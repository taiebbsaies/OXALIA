import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Client-side preprocessing before upload: normalizes any picked image
/// into a bounded-size JPEG.
///
/// Uses platform-native codecs (Kotlin/Swift) instead of a pure-Dart
/// decoder: dramatically faster on 12MP+ photos, and it transparently
/// converts HEIC — the default iPhone capture format that pure-Dart
/// decoders cannot read.
class ImagePreprocessor {
  ImagePreprocessor._();

  /// Shortest edge of the output, matching the model's input window.
  static const int minDimension = 1024;
  static const int jpegQuality = 85;

  /// Returns normalized JPEG bytes.
  ///
  /// EXIF metadata is stripped: camera photos embed GPS coordinates and
  /// device identifiers that must not leave the device in a medical app.
  static Future<Uint8List> normalize(Uint8List bytes) {
    return FlutterImageCompress.compressWithList(
      bytes,
      minWidth: minDimension,
      minHeight: minDimension,
      quality: jpegQuality,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
  }
}
