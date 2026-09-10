import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../core/identity.dart';
import 'provider.dart';

/// THE ONE FILE TO FILL IN when the company API arrives.
///
/// The shape below follows §17/§17.1 of the build plan. If the real API differs,
/// change it here only — nothing outside this file knows how enhancement works.
///
/// Needed from the API:
///   1. Base URL and how a device authenticates (§17 POST /auth, D15 device token)
///   2. Upload: direct-to-storage signed URL (§18) or multipart to the API?
///   3. Create-job request/response field names
///   4. Poll response: status values, stage string, output URL field
///   5. Error code strings, so ErrorCode.parse matches (§53)
class CompanyApiProvider implements AiProvider {
  CompanyApiProvider({required this.baseUrl, Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 15)));

  final String baseUrl;
  final Dio _dio;

  Future<Options> _auth() async => Options(headers: {
        'Authorization': 'Bearer ${await Identity.token()}',
      });

  @override
  Stream<JobUpdate> enhance(File image, {required String idempotencyKey}) async* {
    try {
      yield const JobUpdate(JobStatus.created);

      // --- 1. Upload -------------------------------------------------------
      // §18: prefer a signed URL so a multi-MB file never routes through the
      // API server. Swap for multipart if the company API expects that.
      final up = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/uploads',
        data: {'content_type': 'image/jpeg'},
        options: await _auth(),
      );
      final uploadUrl = up.data!['upload_url'] as String;
      final objectKey = up.data!['object_key'] as String;

      await Dio().put<void>(
        uploadUrl,
        data: image.openRead(),
        options: Options(headers: {
          'Content-Type': 'image/jpeg',
          'Content-Length': await image.length(),
        }),
      );

      // --- 2. Create job ---------------------------------------------------
      final created = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/jobs',
        data: {'object_key': objectKey},
        options: (await _auth())..headers?['Idempotency-Key'] = idempotencyKey,
      );
      final jobId = created.data!['job_id'] as String;
      yield JobUpdate(JobStatus.queued, jobId: jobId);

      // --- 3. Poll (D6) ----------------------------------------------------
      final deadline = DateTime.now().add(kPollTimeout);
      var attempt = 0;
      var last = JobStatus.queued;

      while (DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(pollDelay(attempt++));

        final r = await _dio.get<Map<String, dynamic>>(
          '$baseUrl/jobs/$jobId',
          options: await _auth(),
        );
        final body = r.data!;
        final status = JobStatus.values.byName(body['status'] as String);

        if (status != last && !canTransition(last, status)) {
          // The server contradicted §52. Surface it instead of rendering nonsense.
          yield JobUpdate(JobStatus.failed, jobId: jobId, error: ErrorCode.unknown);
          return;
        }
        last = status;

        yield JobUpdate(
          status,
          jobId: jobId,
          stage: body['progress_stage'] as String?,
          outputUrl: body['output_url'] as String?,
          error: body['error_code'] == null ? null : ErrorCode.parse(body['error_code'] as String),
        );
        if (isTerminal(status)) return;
      }

      yield JobUpdate(JobStatus.failed, jobId: jobId, error: ErrorCode.queueTimeout);
    } on DioException catch (e) {
      final code = e.response?.data is Map ? (e.response!.data as Map)['error_code'] as String? : null;
      yield JobUpdate(JobStatus.failed, error: code != null ? ErrorCode.parse(code) : ErrorCode.network);
    }
  }
}
