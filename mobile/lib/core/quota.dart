import 'package:shared_preferences/shared_preferences.dart';

/// D4 — one free result before the paywall.
///
/// ponytail: client-side counter. §22 is explicit that the backend must be the
/// source of truth for entitlement; this exists only so the paywall can be built
/// and tested before the API exists. Replace with GET /entitlements — do NOT
/// ship this to users, it is a counter anyone can reset by reinstalling.
class Quota {
  static const _k = 'free_used';
  static const freeAllowance = 1;

  static Future<int> used() async =>
      (await SharedPreferences.getInstance()).getInt(_k) ?? 0;

  static Future<bool> hasFree() async => await used() < freeAllowance;

  /// §51 — consume only after a successful job. Never on failure.
  static Future<void> consume() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_k, (p.getInt(_k) ?? 0) + 1);
  }
}
