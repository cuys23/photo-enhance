import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/quota.dart';
import '../jobs/job_runner.dart';
import '../photo/prepare.dart';
import 'paywall_sheet.dart';
import 'history_screen.dart';
import 'processing_screen.dart';
import 'settings_screen.dart';

/// §4.1 — the home screen exists to get the user to the upload action. Nothing
/// else belongs here: no dashboard, no mode grid, no navigation system.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.runner});

  final JobRunner runner;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  bool _busy = false;

  /// Both destinations can wipe the quota, so both refresh the free-count line.
  Future<void> _open(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // §24 — the paywall comes after the free allowance is spent, never before
      // the user has seen a result.
      if (!await Quota.hasFree()) {
        if (mounted) await showPaywall(context);
        return;
      }

      final picked = await _picker.pickImage(source: source);
      if (picked == null) return;

      final prepared = await preparePhoto(File(picked.path));
      if (!prepared.isOk) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(prepared.error!.message)));
        }
        return;
      }

      await widget.runner.start(prepared.file!);
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ProcessingScreen(runner: widget.runner)),
        );
        setState(() {}); // refresh the remaining-free line
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => _open(const HistoryScreen()),
                    icon: const Icon(Icons.grid_view_outlined, color: Colors.white38),
                  ),
                  IconButton(
                    onPressed: () => _open(const SettingsScreen()),
                    icon: const Icon(Icons.settings_outlined, color: Colors.white38),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              const Text('Làm ảnh của bạn\nđẹp hơn',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      height: 1.15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              const Text('Chọn một tấm ảnh. Phần còn lại tự động.',
                  style: TextStyle(color: Colors.white54, fontSize: 15)),
              const Spacer(flex: 3),
              FilledButton(
                onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                child: const Text('Chọn ảnh'),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _busy ? null : () => _pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Chụp ảnh mới'),
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
              ),
              const SizedBox(height: 20),
              FutureBuilder<int>(
                future: Quota.used(),
                builder: (_, s) {
                  final left = Quota.freeAllowance - (s.data ?? 0);
                  return Text(
                    left > 0 ? 'Còn $left lượt miễn phí' : 'Đã dùng hết lượt miễn phí',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
