import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../ai/provider.dart';
import '../core/history.dart';
import '../core/quota.dart';

/// Drives one enhancement from picked file to result, and owns the only piece of
/// business logic the app is allowed to have: when a credit is consumed.
class JobRunner extends ChangeNotifier {
  JobRunner(this._provider);

  final AiProvider _provider;
  StreamSubscription<JobUpdate>? _sub;

  JobStatus status = JobStatus.created;
  String? stage;
  String? outputUrl;
  File? input;
  ErrorCode? error;

  bool get isRunning => !isTerminal(status);
  bool get succeeded => status == JobStatus.completed;

  Future<void> start(File prepared) async {
    await _sub?.cancel();
    input = prepared;
    status = JobStatus.created;
    stage = null;
    outputUrl = null;
    error = null;
    notifyListeners();

    // §12 — one key per attempt at this image. A retry of the same tap must not
    // create a second job.
    final key = const Uuid().v4();

    _sub = _provider.enhance(prepared, idempotencyKey: key).listen(
      (u) async {
        status = u.status;
        stage = u.stage ?? stage;
        outputUrl = u.outputUrl ?? outputUrl;
        error = u.error;

        // §29/§51 — the credit is consumed on success only. A failed job never
        // costs the user anything.
        if (u.status == JobStatus.completed) {
          await Quota.consume();
          // History is a P1 convenience. A full disk must not trap the user on
          // the processing screen holding a result they cannot see.
          try {
            await History.add(before: prepared, after: outputUrl!);
          } catch (e) {
            debugPrint('history: $e');
          }
        }

        notifyListeners();
      },
      onError: (Object _) {
        status = JobStatus.failed;
        error = ErrorCode.unknown;
        notifyListeners();
      },
    );
  }

  Future<void> cancel() async {
    await _sub?.cancel();
    if (canTransition(status, JobStatus.cancelled)) {
      status = JobStatus.cancelled;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
