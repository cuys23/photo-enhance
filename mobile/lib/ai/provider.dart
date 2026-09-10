import 'dart:io';

/// §52 — job state machine. Transitions are checked, not assumed.
enum JobStatus { created, queued, processing, completed, failed, cancelled, expired }

const _allowed = <JobStatus, Set<JobStatus>>{
  JobStatus.created: {JobStatus.queued, JobStatus.cancelled, JobStatus.failed},
  JobStatus.queued: {JobStatus.processing, JobStatus.cancelled, JobStatus.expired, JobStatus.failed},
  JobStatus.processing: {JobStatus.completed, JobStatus.failed},
  JobStatus.completed: {},
  JobStatus.failed: {},
  JobStatus.cancelled: {},
  JobStatus.expired: {},
};

bool canTransition(JobStatus from, JobStatus to) => _allowed[from]!.contains(to);

bool isTerminal(JobStatus s) =>
    s == JobStatus.completed || s == JobStatus.failed || s == JobStatus.cancelled || s == JobStatus.expired;

/// §53 — stable error codes. The wire sends the string, the app owns the copy.
enum ErrorCode {
  invalidImage('INVALID_IMAGE'),
  unsupportedFormat('UNSUPPORTED_FORMAT'),
  imageTooLarge('IMAGE_TOO_LARGE'),
  quotaExceeded('QUOTA_EXCEEDED'),
  queueTimeout('QUEUE_TIMEOUT'),
  modelError('MODEL_ERROR'),
  gpuError('GPU_ERROR'),
  storageError('STORAGE_ERROR'),
  network('NETWORK_ERROR'),
  unknown('UNKNOWN_ERROR');

  const ErrorCode(this.wire);
  final String wire;

  static ErrorCode parse(String? s) =>
      ErrorCode.values.firstWhere((e) => e.wire == s, orElse: () => ErrorCode.unknown);

  /// §53 — map to something a person can act on. No apologies, no vagueness.
  String get message => switch (this) {
        ErrorCode.invalidImage => 'Ảnh này không đọc được. Thử chọn ảnh khác.',
        ErrorCode.unsupportedFormat => 'Định dạng chưa hỗ trợ. Dùng JPEG, PNG hoặc HEIC.',
        ErrorCode.imageTooLarge => 'Ảnh quá lớn. Thử ảnh dưới 25 MB.',
        ErrorCode.quotaExceeded => 'Bạn đã dùng hết lượt miễn phí.',
        ErrorCode.queueTimeout => 'Xử lý lâu hơn bình thường. Thử lại sau ít phút.',
        ErrorCode.modelError || ErrorCode.gpuError => 'Xử lý ảnh thất bại. Lượt của bạn chưa bị trừ.',
        ErrorCode.storageError => 'Không lưu được kết quả. Thử lại.',
        ErrorCode.network => 'Mất kết nối. Kiểm tra mạng rồi thử lại.',
        ErrorCode.unknown => 'Có lỗi xảy ra. Lượt của bạn chưa bị trừ.',
      };
}

/// D6 — poll fast while the user is watching, then back off. Kept here with the
/// other contracts (and free of Flutter imports) so it stays directly testable.
Duration pollDelay(int attempt) =>
    attempt < 10 ? const Duration(seconds: 1) : const Duration(seconds: 3);

const kPollTimeout = Duration(seconds: 90);

/// One update in a job's life. `stage` is whatever the backend reported —
/// §28: never invent a stage the model did not actually report.
class JobUpdate {
  const JobUpdate(this.status, {this.jobId, this.stage, this.outputUrl, this.error});

  final JobStatus status;
  final String? jobId;
  final String? stage;
  final String? outputUrl;
  final ErrorCode? error;
}

/// §66 — the seam. One method. The app must never know which model is behind it.
///
/// Everything that differs between providers (REST vs polling vs webhook,
/// upload strategy, auth) lives inside the implementation.
abstract class AiProvider {
  /// [idempotencyKey] — §12. Replaying the same key must not create a second
  /// job or consume a second credit.
  Stream<JobUpdate> enhance(File image, {required String idempotencyKey});
}
