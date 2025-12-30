import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'src/ffi_jpeg_encode_bindings_generated.dart';

/// JPEG chroma subsampling modes.
enum JpegSubsampling {
  /// Auto mode: uses 4:2:0 if quality <= 90, else 4:4:4
  auto_,

  /// 4:4:4 - No chroma subsampling (higher quality, larger files)
  yuv444,

  /// 4:2:0 - Chroma subsampling (smaller files)
  yuv420,
}

/// Encodes raw pixel data to JPEG format and returns the bytes.
///
/// This function runs synchronously on the calling thread.
///
/// [pixels] Raw pixel data (RGBA, RGB, or grayscale)
/// [width] Image width in pixels
/// [height] Image height in pixels
/// [comp] Number of channels (1=grayscale, 3=RGB, 4=RGBA)
/// [quality] JPEG quality (1-100, default 95)
/// [subsampling] Chroma subsampling mode
///
/// Returns `Uint8List` containing the JPEG-encoded image data.
///
/// Throws [JpegEncodingException] if encoding fails.
Uint8List encodeJpegToBytes(
  Uint8List pixels,
  int width,
  int height,
  int comp, {
  int quality = 95,
  JpegSubsampling subsampling = JpegSubsampling.auto_,
}) {
  assert(pixels.isNotEmpty, 'pixels is empty');
  assert(width > 0 && height > 0, 'invalid width or height');
  assert(comp == 1 || comp == 3 || comp == 4, 'component must be 1, 3, or 4');

  // Convert enum to int for FFI
  final subsampleMode = switch (subsampling) {
    JpegSubsampling.auto_ => -1,
    JpegSubsampling.yuv444 => 0,
    JpegSubsampling.yuv420 => 1,
  };

  // Allocate native memory for input pixels
  final pixelsPtr = malloc<ffi.Uint8>(pixels.length);
  ffi.Pointer<ffi.UnsignedChar>? nativeBuffer;

  try {
    // Copy pixels to native memory
    pixelsPtr.asTypedList(pixels.length).setAll(0, pixels);

    // Call native encoding
    final result = _bindings.jo_encode_jpg_to_mem(
      pixelsPtr.cast(),
      width,
      height,
      comp,
      quality,
      subsampleMode,
    );

    if (result.data == ffi.nullptr || result.size == 0) {
      throw const JpegEncodingException('Native JPEG encoding failed');
    }

    nativeBuffer = result.data;

    final bytes = Uint8List.fromList(
      result.data.cast<ffi.Uint8>().asTypedList(result.size),
    );

    return bytes;
  } finally {
    malloc.free(pixelsPtr);
    if (nativeBuffer != null) {
      _bindings.jo_free_buffer(nativeBuffer);
    }
  }
}

const String _libName = 'ffi_jpeg_encode';

/// The dynamic library in which the symbols for [FfiJpegEncodeBindings] can be found.
final ffi.DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return ffi.DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return ffi.DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return ffi.DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final _bindings = FfiJpegEncodeBindings(_dylib);

class JpegEncodingException implements Exception {
  const JpegEncodingException(this.message);

  final String message;

  @override
  String toString() => 'JpegEncodingException: $message';
}
