import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'history.dart';

/// D15 — a device token is a sufficient identity to hang entitlement on.
/// No login screen at MVP. Swap for a real token from POST /auth when the API
/// lands; nothing else in the app reads this.
class Identity {
  static const _k = 'device_token';
  static String? _cached;

  static Future<String> token() async {
    if (_cached != null) return _cached!;
    final p = await SharedPreferences.getInstance();
    var t = p.getString(_k);
    if (t == null) {
      t = const Uuid().v4();
      await p.setString(_k, t);
    }
    return _cached = t;
  }

  /// §43 — the on-device half of "delete my data": token, quota counter, and
  /// the prepared JPEGs left in the temp dir by [preparePhoto].
  ///
  /// The next call to [token] mints a new identity, so the device is a stranger
  /// to the backend afterwards.
  ///
  /// ponytail: local only. §43 also requires the server to delete jobs, objects
  /// and analytics rows — call DELETE /me here once the API exists. Apple
  /// requires the server half before the app can ship.
  static Future<void> wipe() async {
    await History.clear();
    await (await SharedPreferences.getInstance()).clear();
    _cached = null;

    final dir = await getTemporaryDirectory();
    if (!dir.existsSync()) return;
    for (final f in dir.listSync()) {
      if (f is File && f.uri.pathSegments.last.startsWith('up_')) f.deleteSync();
    }
  }
}
