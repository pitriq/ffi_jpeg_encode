import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (BuildInput input, BuildOutputBuilder output) async {
    final codeConfig = input.config.code;
    final targetOS = codeConfig.targetOS;
    final targetArch = codeConfig.targetArchitecture;

    final flags = <String>[];

    // Compiler-specific optimization flags
    if (targetOS == OS.windows) {
      // MSVC flags
      flags.addAll(['/O2', '/fp:fast']);
    } else {
      // GCC/Clang flags (macOS, Linux, iOS, Android)
      flags.addAll(['-O3', '-ffast-math']);

      // Architecture-specific SIMD flags
      if (targetArch == Architecture.arm) {
        flags.addAll(['-mfpu=neon', '-mfloat-abi=softfp']);
      } else if (targetArch == Architecture.x64 ||
          targetArch == Architecture.ia32) {
        flags.add('-msse2');
      }
      // arm64 has NEON by default
    }

    // Android 15 linker flag for 16KB page size compatibility
    if (targetOS == OS.android) {
      flags.add('-Wl,-z,max-page-size=16384');
    }

    // Link against math library for ceilf/floorf on Android
    final libraries = <String>[];
    if (targetOS == OS.android || targetOS == OS.linux) {
      libraries.add('m');
    }

    await CBuilder.library(
      name: 'ffi_jpeg_encode',
      assetName: 'ffi_jpeg_encode.dart',
      sources: ['src/ffi_jpeg_encode.c'],
      includes: ['src'],
      flags: flags,
      libraries: libraries,
      defines: {'DART_SHARED_LIB': null},
      language: Language.c,
    ).run(input: input, output: output);
  });
}
