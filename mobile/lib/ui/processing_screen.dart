import 'package:flutter/material.dart';

import '../ai/provider.dart';
import '../jobs/job_runner.dart';
import 'result_screen.dart';

/// §28 — never a bare spinner for a long AI job. The stage text comes from the
/// backend where it exists; the fallback copy below is product-level and does
/// not claim any specific model operation.
class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key, required this.runner});

  final JobRunner runner;

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  @override
  void initState() {
    super.initState();
    widget.runner.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.runner.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    if (widget.runner.succeeded) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            before: widget.runner.input!,
            after: widget.runner.outputUrl!,
          ),
        ),
      );
    } else {
      setState(() {});
    }
  }

  String get _label => switch (widget.runner.status) {
        JobStatus.created => 'Đang chuẩn bị ảnh',
        JobStatus.queued => 'Đang xếp hàng',
        JobStatus.processing => widget.runner.stage ?? 'Đang xử lý',
        _ => 'Đang hoàn tất',
      };

  @override
  Widget build(BuildContext context) {
    final r = widget.runner;
    final failed = r.status == JobStatus.failed;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: failed ? _failure(context, r) : _progress(context, r),
        ),
      ),
    );
  }

  Widget _progress(BuildContext context, JobRunner r) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Opacity(opacity: 0.4, child: Image.file(r.input!, fit: BoxFit.cover)),
            ),
          ),
          const SizedBox(height: 40),
          const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(height: 24),
          Text(_label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Giữ ứng dụng mở',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 28),
          TextButton(
            onPressed: () async {
              await r.cancel();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Huỷ'),
          ),
        ],
      );

  /// §29 — say plainly that nothing was charged, then offer the retry.
  Widget _failure(BuildContext context, JobRunner r) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.white54, size: 48),
          const SizedBox(height: 20),
          Text((r.error ?? ErrorCode.unknown).message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => r.start(r.input!),
            child: const Text('Thử lại'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chọn ảnh khác'),
          ),
        ],
      );
}
