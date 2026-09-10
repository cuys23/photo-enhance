import 'package:flutter/material.dart';

import '../core/identity.dart';
import '../core/quota.dart';

/// §31 screen 08 + §43. Carries the one P0 obligation that needs no backend:
/// the user can delete what the app holds about them.
///
/// Privacy and Terms belong here too (§3.2 P0) — one row each, added the day
/// legal supplies the URLs. Nothing is placeholdered in the meantime.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: const Text('Xoá dữ liệu của bạn?'),
        content: const Text(
            'Xoá mã thiết bị, số lượt đã dùng và ảnh tạm trên máy này. '
            'Ảnh bạn đã lưu vào thư viện không bị ảnh hưởng. Không hoàn tác được.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE5484D)),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await Identity.wipe();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã xoá dữ liệu trên máy này')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        children: [
          FutureBuilder<int>(
            future: Quota.used(),
            builder: (_, s) => ListTile(
              title: const Text('Lượt miễn phí', style: TextStyle(color: Colors.white)),
              subtitle: Text('Đã dùng ${s.data ?? 0}/${Quota.freeAllowance}',
                  style: const TextStyle(color: Colors.white38)),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          ListTile(
            onTap: _delete,
            title: const Text('Xoá dữ liệu của tôi',
                style: TextStyle(color: Color(0xFFE5484D))),
            subtitle: const Text('Mã thiết bị, số lượt đã dùng, ảnh tạm',
                style: TextStyle(color: Colors.white38)),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Support needs to be able to find this device's rows in the backend.
          FutureBuilder<String>(
            future: Identity.token(),
            builder: (_, s) => ListTile(
              title: const Text('Mã thiết bị', style: TextStyle(color: Colors.white54)),
              subtitle: Text(s.data ?? '…',
                  style: const TextStyle(color: Colors.white24, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
