import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// §3.2 P1 / §31 screen 07 — the list of results the user already produced.
///
/// Entirely on-device: a job the backend has already forgotten (D9 — results
/// expire after 30 days) is still worth showing until its file goes.
class HistoryEntry {
  const HistoryEntry({required this.id, required this.before, required this.after, required this.at});

  final String id;

  /// Local path. Copied out of the temp dir, which the OS purges without asking.
  final String before;

  /// Local path (mock, or a downloaded result) or an https URL from the API.
  final String after;

  final DateTime at;

  Map<String, dynamic> toJson() =>
      {'id': id, 'b': before, 'a': after, 't': at.millisecondsSinceEpoch};

  static HistoryEntry fromJson(Map<String, dynamic> j) => HistoryEntry(
        id: j['id'] as String,
        before: j['b'] as String,
        after: j['a'] as String,
        at: DateTime.fromMillisecondsSinceEpoch(j['t'] as int),
      );
}

class History {
  static const _k = 'history';

  /// ponytail: a flat cap, not a size budget. Two full-res JPEGs per entry is a
  /// few hundred MB at worst. Measure before replacing this with anything
  /// cleverer.
  static const max = 30;

  static Future<Directory> _dir() async =>
      Directory('${(await getApplicationDocumentsDirectory()).path}/history');

  static Future<List<HistoryEntry>> all() async {
    final raw = (await SharedPreferences.getInstance()).getString(_k);
    if (raw == null) return const [];
    return (jsonDecode(raw) as List)
        .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Copies the images somewhere durable, then records the entry. Newest first.
  static Future<void> add({required File before, required String after}) async {
    final dir = await (await _dir()).create(recursive: true);
    final id = DateTime.now().microsecondsSinceEpoch.toString();

    await before.copy('${dir.path}/${id}_b.jpg');
    // An https result stays a URL: downloading it here would duplicate what
    // "Lưu ảnh" already does, on every job, whether the user wants it or not.
    if (!after.startsWith('http')) await File(after).copy('${dir.path}/${id}_a.jpg');

    final entry = HistoryEntry(
      id: id,
      before: '${dir.path}/${id}_b.jpg',
      after: after.startsWith('http') ? after : '${dir.path}/${id}_a.jpg',
      at: DateTime.now(),
    );

    final kept = [entry, ...await all()];
    for (final gone in kept.skip(max)) {
      for (final p in [gone.before, gone.after]) {
        final f = File(p);
        if (!p.startsWith('http') && f.existsSync()) f.deleteSync();
      }
    }
    await _save(kept.take(max).toList());
  }

  static Future<void> _save(List<HistoryEntry> l) async =>
      (await SharedPreferences.getInstance())
          .setString(_k, jsonEncode(l.map((e) => e.toJson()).toList()));

  /// §43 — part of "delete my data".
  static Future<void> clear() async {
    final dir = await _dir();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    await (await SharedPreferences.getInstance()).remove(_k);
  }
}
