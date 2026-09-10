import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../ai/provider.dart';

/// §19 — validation and normalisation happen on-device, before upload.
///
/// HEIC is converted here rather than on the server: it removes libheif from the
/// request path and from the attack surface, and cuts upload size. The backend
/// then only ever sees JPEG.
class PreparedPhoto {
  const PreparedPhoto.ok(this.file) : error = null;
  const PreparedPhoto.failed(this.error) : file = null;

  final File? file;
  final ErrorCode? error;

  bool get isOk => file != null;
}

const _maxEdge = 2048;
const _maxBytes = 25 * 1024 * 1024;

Future<PreparedPhoto> preparePhoto(File input) async {
  if (!await input.exists()) return const PreparedPhoto.failed(ErrorCode.invalidImage);
  if (await input.length() > _maxBytes) return const PreparedPhoto.failed(ErrorCode.imageTooLarge);

  final dir = await getTemporaryDirectory();
  final out = '${dir.path}/up_${DateTime.now().microsecondsSinceEpoch}.jpg';

  // Also normalises EXIF orientation (§6.1) — autoCorrectionAngle is on by default.
  final result = await FlutterImageCompress.compressAndGetFile(
    input.path,
    out,
    format: CompressFormat.jpeg,
    quality: 92,
    minWidth: _maxEdge,
    minHeight: _maxEdge,
    keepExif: false, // strip location before it ever leaves the device (§42)
  );

  if (result == null) return const PreparedPhoto.failed(ErrorCode.unsupportedFormat);
  return PreparedPhoto.ok(File(result.path));
}
