import 'package:flutter/material.dart';

/// D5 — one product: weekly with a 3-day trial. Not monthly, not credits,
/// not tiers.
///
/// ponytail: presentation only. Wire to RevenueCat (purchases_flutter) in
/// Phase 4; the purchase call and entitlement refresh belong behind this sheet,
/// and the backend stays the source of truth for entitlement (§22).
Future<void> showPaywall(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF141414),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Dùng không giới hạn',
                style: TextStyle(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            ...const [
              'Xử lý không giới hạn ảnh',
              'Hàng đợi ưu tiên',
              'Lưu bản đầy đủ độ phân giải',
            ].map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    const Icon(Icons.check, color: Colors.white70, size: 18),
                    const SizedBox(width: 10),
                    Text(t, style: const TextStyle(color: Colors.white70, fontSize: 15)),
                  ]),
                )),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Dùng thử 3 ngày miễn phí'),
            ),
            const SizedBox(height: 8),
            const Text('Sau đó tính phí theo tuần. Huỷ bất kỳ lúc nào.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
