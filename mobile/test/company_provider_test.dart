import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_enhance/ai/company_provider.dart';
import 'package:photo_enhance/ai/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// R3 — `company_provider.dart` is written against an API contract nobody has
/// confirmed. These tests pin the parts that survive a schema change: the poll
/// loop, the §52 transition guard, §12 idempotency, and §53 error mapping.
///
/// The fake server is `dart:io` HttpServer — no mock package, and when the real
/// contract arrives this file is where it gets encoded.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // flutter_test installs a mock HttpClient that answers 400 to everything.
  HttpOverrides.global = null;
  SharedPreferences.setMockInitialValues({});

  late HttpServer server;
  late String baseUrl;
  late File image;

  /// Responses `GET /jobs/{id}` hands back, one per poll.
  late List<Map<String, dynamic>> pollScript;
  Map<String, dynamic>? jobsError; // non-null => POST /jobs answers 400 with this
  String? seenIdempotencyKey;
  var uploadedBytes = 0;

  setUp(() async {
    pollScript = [];
    jobsError = null;
    seenIdempotencyKey = null;
    uploadedBytes = 0;

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://127.0.0.1:${server.port}';

    image = File('${Directory.systemTemp.path}/t_${server.port}.jpg')
      ..writeAsBytesSync(List.filled(64, 7));

    server.listen((req) async {
      Future<void> reply(int code, Object body) async {
        req.response
          ..statusCode = code
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(body));
        await req.response.close();
      }

      final path = req.uri.path;
      if (path == '/uploads') {
        await reply(200, {'upload_url': '$baseUrl/put', 'object_key': 'k1'});
      } else if (path == '/put') {
        uploadedBytes = (await req.fold<List<int>>([], (a, b) => a..addAll(b))).length;
        await req.response.close();
      } else if (path == '/jobs') {
        seenIdempotencyKey = req.headers.value('Idempotency-Key');
        await (jobsError == null ? reply(200, {'job_id': 'j1'}) : reply(400, jobsError!));
      } else if (path == '/jobs/j1') {
        // The last entry repeats, so a script never runs dry mid-poll.
        await reply(200,
            pollScript.length > 1 ? pollScript.removeAt(0) : pollScript.first);
      } else {
        await reply(404, {});
      }
    });
  });

  tearDown(() async {
    await server.close(force: true);
    if (image.existsSync()) image.deleteSync();
  });

  Future<List<JobUpdate>> run() => CompanyApiProvider(baseUrl: baseUrl)
      .enhance(image, idempotencyKey: 'key-abc')
      .toList();

  test('happy path uploads, creates, polls to completed', () async {
    pollScript = [
      {'status': 'processing', 'progress_stage': 'Đang tăng cường chi tiết'},
      {'status': 'completed', 'output_url': 'https://cdn/out.jpg'},
    ];

    final updates = await run();

    expect(updates.map((u) => u.status).toList(),
        [JobStatus.created, JobStatus.queued, JobStatus.processing, JobStatus.completed]);
    expect(uploadedBytes, 64, reason: 'the whole file must reach storage');
    expect(seenIdempotencyKey, 'key-abc', reason: '§12');
    expect(updates.last.outputUrl, 'https://cdn/out.jpg');
    expect(updates[2].stage, 'Đang tăng cường chi tiết', reason: '§28 stage is the server’s');
    // Terminal means terminal: the completed entry was the last one consumed.
    expect(pollScript.length, 1);
  });

  test('refuses a server response that breaks the state machine (§52)', () async {
    // queued -> completed is not a legal transition; the server contradicted itself.
    pollScript = [
      {'status': 'completed', 'output_url': 'https://cdn/out.jpg'},
    ];

    final updates = await run();

    expect(updates.last.status, JobStatus.failed);
    expect(updates.last.error, ErrorCode.unknown);
    expect(updates.any((u) => u.outputUrl != null), isFalse,
        reason: 'never render a result arrived at illegally');
  });

  test('maps a server error code to the taxonomy (§53)', () async {
    jobsError = {'error_code': 'QUOTA_EXCEEDED'};

    final updates = await run();

    expect(updates.last.status, JobStatus.failed);
    expect(updates.last.error, ErrorCode.quotaExceeded);
  });

  test('an unreachable API is a network error, not a crash', () async {
    await server.close(force: true);

    final updates = await CompanyApiProvider(baseUrl: baseUrl)
        .enhance(image, idempotencyKey: 'k')
        .toList();

    expect(updates.last.status, JobStatus.failed);
    expect(updates.last.error, ErrorCode.network);
  });

  test('a failed job reports an error the user can act on (§29)', () async {
    pollScript = [
      {'status': 'processing'},
      {'status': 'failed', 'error_code': 'MODEL_ERROR'},
    ];

    final updates = await run();

    expect(updates.last.status, JobStatus.failed);
    expect(updates.last.error, ErrorCode.modelError);
    expect(updates.last.error!.message, contains('chưa bị trừ'));
  });
}
