# ffi_jpeg_encode

Fast JPEG encoding via FFI with SIMD optimizations for Android and iOS.

## Usage

```dart
import 'package:ffi_jpeg_encode/ffi_jpeg_encode.dart';

final jpegBytes = encodeJpegToBytes(
  pixels,       // Uint8List of raw pixel data
  width,        // Image width
  height,       // Image height
  4,            // Components (1=grayscale, 3=RGB, 4=RGBA)
  quality: 95,
  subsampling: JpegSubsampling.auto_,
);
```

## Subsampling Options

- `JpegSubsampling.auto_` - 4:2:0 if quality <= 90, else 4:4:4
- `JpegSubsampling.yuv444` - No subsampling (higher quality)
- `JpegSubsampling.yuv420` - Subsampling (smaller files)

## Credits

Adapted from [flutter_jpeg_encode_ffi](https://github.com/fingerart/flutter_jpeg_encode_ffi).

Based on [jo_jpeg](http://jonolick.com) - Public Domain JPEG writer.
