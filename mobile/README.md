# Photo Enhance — mobile

Khung ứng dụng theo `AI Photo Enhancement App — Master Build Plan.md` (revision R1).
Chạy được ngay, chưa cần backend.

Project pin Flutter 3.38.0 qua `.fvmrc` — dùng `fvm flutter`, không dùng `flutter` trần.

```bash
fvm flutter run                                              # MockProvider, không cần API
fvm flutter run --dart-define=API_BASE_URL=https://api.cty.vn # API thật
fvm dart analyze && fvm flutter test                         # 13 test
fvm flutter build ios --simulator --no-codesign              # kiểm tra biên dịch native
```

## Khi API của công ty sẵn sàng

Sửa **đúng một file**: `lib/ai/company_provider.dart`.

Cần biết 5 thứ:

1. Base URL, và thiết bị xác thực thế nào (D15 device token)
2. Upload — signed URL (§18) hay multipart lên API?
3. Tên trường trong request/response của create-job
4. Response khi poll: giá trị `status`, trường `progress_stage`, trường URL kết quả
5. Chuỗi error code, để `ErrorCode.parse` khớp (§53)

Không file nào khác biết mô hình AI chạy ở đâu — đó là mục đích của §66.

## Cấu trúc

```
lib/
  ai/provider.dart          §52 state machine · §53 error taxonomy · D6 poll · §66 interface
  ai/mock_provider.dart     chạy toàn app không cần backend — xoá khi có API thật
  ai/company_provider.dart  ★ file duy nhất cần điền
  core/identity.dart        D15 device token · §43 xoá dữ liệu trên máy
  core/quota.dart           D4 free tier — tạm ở client, xem cảnh báo trong file
  core/history.dart         §31/07 — chép ảnh ra docs dir, giữ 30 mục gần nhất
  photo/prepare.dart        §19 HEIC→JPEG, resize, strip EXIF, ngay trên máy
  jobs/job_runner.dart      §51 trừ lượt chỉ khi thành công
  ui/home_screen.dart       §4.1
  ui/processing_screen.dart §28 stage text · §29 lỗi không trừ lượt
  ui/result_screen.dart     §32 màn hình quan trọng nhất — dùng chung cho History
  ui/history_screen.dart    §31/07 lưới kết quả
  ui/before_after.dart      §33 tự viết, không dùng package
  ui/paywall_sheet.dart     D5 — giao diện, chưa nối RevenueCat
  ui/settings_screen.dart   §43 xoá dữ liệu — nửa client, nửa server chờ API
```

## Chưa làm, và khi nào nên làm

| Bỏ qua | Thêm khi |
|---|---|
| RevenueCat / mua hàng thật | Phase 4 — `purchases_flutter`, webhook về backend |
| Entitlement từ server | Có `GET /entitlements`; **xoá `core/quota.dart`**, §22 |
| Onboarding, Splash | Sau khi vòng lặp lõi chạy đúng trên máy thật |
| `DELETE /me` — nửa server của §43 | Có API. **Apple bắt buộc trước khi lên store** |
| Privacy, Terms | Legal đưa URL — mỗi cái một dòng trong Settings |
| PostHog, Sentry | Trước closed beta (§25) |
| Consent sinh trắc, quét CSAM | **Trước người dùng ngoài đầu tiên** (§21.5) — P0, không hoãn |
| Push notification | V1.1 (D6) |
| Riverpod | Chưa cần: 4 màn hình, `ChangeNotifier` là đủ |
