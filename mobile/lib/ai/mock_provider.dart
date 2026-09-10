import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'provider.dart';

/// Runs the whole app with no backend. Delete when the real API lands —
/// keep it until then so the UI can be built and demoed offline.
class MockProvider implements AiProvider {
  MockProvider({this.failureRate = 0.0, this.duration = const Duration(seconds: 6)});

  final double failureRate;
  final Duration duration;
  final _rng = Random();

  @override
  Stream<JobUpdate> enhance(File image, {required String idempotencyKey}) async* {
    final step = duration ~/ 4;
    yield const JobUpdate(JobStatus.created, jobId: 'mock');
    await Future<void>.delayed(step);
    yield const JobUpdate(JobStatus.queued, jobId: 'mock', stage: 'Đang xếp hàng');
    await Future<void>.delayed(step);
    yield const JobUpdate(JobStatus.processing, jobId: 'mock', stage: 'Đang phân tích ảnh');
    await Future<void>.delayed(step);
    yield const JobUpdate(JobStatus.processing, jobId: 'mock', stage: 'Đang tăng cường chi tiết');
    await Future<void>.delayed(step);

    if (_rng.nextDouble() < failureRate) {
      yield const JobUpdate(JobStatus.failed, jobId: 'mock', error: ErrorCode.modelError);
      return;
    }
    // No model here: hand back the input so the before/after screen is real UI
    // over honest data rather than a fake "improved" image.
    yield JobUpdate(JobStatus.completed, jobId: 'mock', outputUrl: image.path);
  }
}
