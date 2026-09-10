import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import 'before_after.dart';

/// §32 — the most important screen in the application. The user must answer
/// "what did the AI actually improve?" without being told.
class ResultScreen extends StatelessWidget {
  /// Takes the two images, not a JobRunner: History replays an old result
  /// through this same screen, and an old result has no running job.
  const ResultScreen({super.key, required this.before, required this.after});

  final File before;
  final String after;

  Future<void> _save(BuildContext context) async {
    final url = after;
    try {
      if (url.startsWith('http')) {
        final r = await Dio().get<List<int>>(url,
            options: Options(responseType: ResponseType.bytes));
        await Gal.putImageBytes(Uint8List.fromList(r.data!));
      } else {
        await Gal.putImage(url);
      }
      if (context.mounted) _toast(context, 'Đã lưu vào thư viện');
    } on GalException catch (e) {
      if (context.mounted) _toast(context, 'Không lưu được: ${e.type.message}');
    }
  }

  Future<void> _share() async {
    final url = after;
    if (url.startsWith('http')) {
      await SharePlus.instance.share(ShareParams(uri: Uri.parse(url)));
    } else {
      await SharePlus.instance.share(ShareParams(files: [XFile(url)]));
    }
  }

  static void _toast(BuildContext c, String m) =>
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Kết quả'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: BeforeAfter(
                before: FileImage(before),
                after: imageFor(after),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('Kéo để so sánh',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Chia sẻ'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => _save(context),
                    icon: const Icon(Icons.download),
                    label: const Text('Lưu ảnh'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
