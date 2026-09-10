import 'dart:io';

import 'package:flutter/material.dart';

import '../core/history.dart';
import 'before_after.dart';
import 'result_screen.dart';

/// §31 screen 07. A grid of results and nothing else — no filters, no select
/// mode, no rename. Tapping one reopens the comparison it came from.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Ảnh đã làm'),
      ),
      body: FutureBuilder<List<HistoryEntry>>(
        future: History.all(),
        builder: (context, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(
              child: Text('Chưa có ảnh nào', style: TextStyle(color: Colors.white38)),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final e = items[i];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ResultScreen(before: File(e.before), after: e.after),
                  ),
                ),
                child: Image(
                  image: imageFor(e.after),
                  fit: BoxFit.cover,
                  // The file may be gone (user cleared storage) or the URL
                  // expired (D9, 30 days). Show the gap, don't crash the grid.
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF161616),
                    child: const Icon(Icons.image_not_supported_outlined,
                        color: Colors.white12, size: 20),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
