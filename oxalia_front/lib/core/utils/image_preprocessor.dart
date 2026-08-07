import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Client-side preprocessing before upload: downscales and re-encodes
/// any picked image into a bounded-size JPEG.
///
/// Uses platform-native codecs (Kotlin/Swift) instead of a pure-Dart
/// decoder: dramatically faster on 12MP+ photos, and it transparently
/// converts HEIC — the default iPhone capture format that pure-Dart
/// decoders cannot read.
class ImagePreprocessor {
  ImagePreprocessor._();

  /// Longest edge of the final upload payload.
  /// Despite the compressor API names (`minWidth` / `minHeight`), these
  /// values act as *maximum* dimensions: larger images are scaled down.
  static const int maxDimension = 1024;

  /// Working copy kept for the interactive crop step.
  static const int previewMaxDimension = 1600;

  static const int jpegQuality = 85;

  /// HEIC/PNG → JPEG, EXIF stripped, bounded by [maxEdge].
  static Future<Uint8List> normalize(
    Uint8List bytes, {
    int maxEdge = maxDimension,
  }) {
    return FlutterImageCompress.compressWithList(
      bytes,
      minWidth: maxEdge,
      minHeight: maxEdge,
      quality: jpegQuality,
      format: CompressFormat.jpeg,
      keepExif: false,
      autoCorrectionAngle: true,
    );
  }
}
