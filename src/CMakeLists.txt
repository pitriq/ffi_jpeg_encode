# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(ffi_jpeg_encode_library VERSION 0.0.1 LANGUAGES C)

add_library(ffi_jpeg_encode SHARED
  "ffi_jpeg_encode.c"
)

set_target_properties(ffi_jpeg_encode PROPERTIES
  PUBLIC_HEADER ffi_jpeg_encode.h
  OUTPUT_NAME "ffi_jpeg_encode"
)

target_compile_definitions(ffi_jpeg_encode PUBLIC DART_SHARED_LIB)

# ============================================================================
# Platform-specific optimizations
# ============================================================================

# Optimization strategy:
# - Use -O3 for non-Debug builds (let Debug builds remain unoptimized for debugging)
# - Always enable -ffast-math for faster floating-point (safe for JPEG encoding)
# - Enable SIMD instruction sets based on target architecture

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(ffi_jpeg_encode PRIVATE "-Wl,-z,max-page-size=16384")

  # Android Flutter builds are typically release; apply optimizations
  # Enable SIMD based on Android ABI
  if (CMAKE_ANDROID_ARCH_ABI STREQUAL "arm64-v8a")
    # ARM64: NEON is mandatory, always available
    target_compile_options(ffi_jpeg_encode PRIVATE -O3 -ffast-math)
    message(STATUS "FFI JPEG Encode: ARM64 with NEON")

  elseif (CMAKE_ANDROID_ARCH_ABI STREQUAL "armeabi-v7a")
    # ARMv7: Enable NEON (supported by 99%+ of devices since ~2012)
    target_compile_options(ffi_jpeg_encode PRIVATE -O3 -ffast-math -mfpu=neon -mfloat-abi=softfp)
    message(STATUS "FFI JPEG Encode: ARMv7 with NEON")

  elseif (CMAKE_ANDROID_ARCH_ABI STREQUAL "x86_64")
    # x86_64 emulator: SSE2 is baseline
    target_compile_options(ffi_jpeg_encode PRIVATE -O3 -ffast-math -msse2)
    message(STATUS "FFI JPEG Encode: x86_64 with SSE2")

  elseif (CMAKE_ANDROID_ARCH_ABI STREQUAL "x86")
    # x86 emulator
    target_compile_options(ffi_jpeg_encode PRIVATE -O3 -ffast-math -msse2)
    message(STATUS "FFI JPEG Encode: x86 with SSE2")

  else()
    target_compile_options(ffi_jpeg_encode PRIVATE -O3 -ffast-math)
    message(STATUS "FFI JPEG Encode: ${CMAKE_ANDROID_ARCH_ABI} (scalar)")
  endif()

else()
  # Desktop platforms: respect CMAKE_BUILD_TYPE
  # Use generator expressions to only optimize in non-Debug builds

  if (MSVC)
    # MSVC: /O2 in Release, /fp:fast always
    target_compile_options(ffi_jpeg_encode PRIVATE
      $<$<NOT:$<CONFIG:Debug>>:/O2>
      /fp:fast
    )
    message(STATUS "FFI JPEG Encode: MSVC with SSE2")

  else()
    # GCC/Clang: -O3 in non-Debug, -ffast-math always
    target_compile_options(ffi_jpeg_encode PRIVATE
      $<$<NOT:$<CONFIG:Debug>>:-O3>
      -ffast-math
    )

    # Add SIMD flags based on architecture
    if (APPLE)
      if (CMAKE_SYSTEM_PROCESSOR MATCHES "arm64")
        message(STATUS "FFI JPEG Encode: Apple Silicon with NEON")
      else()
        message(STATUS "FFI JPEG Encode: Intel Mac with SSE")
      endif()

    elseif (CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
      message(STATUS "FFI JPEG Encode: Linux ARM64 with NEON")

    elseif (CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
      target_compile_options(ffi_jpeg_encode PRIVATE -mfpu=neon)
      message(STATUS "FFI JPEG Encode: Linux ARM with NEON")

    elseif (CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
      target_compile_options(ffi_jpeg_encode PRIVATE -msse2)
      message(STATUS "FFI JPEG Encode: x86_64 with SSE2")

    elseif (CMAKE_SYSTEM_PROCESSOR MATCHES "i[3-6]86")
      target_compile_options(ffi_jpeg_encode PRIVATE -msse2)
      message(STATUS "FFI JPEG Encode: x86 with SSE2")

    else()
      message(STATUS "FFI JPEG Encode: ${CMAKE_SYSTEM_PROCESSOR} (scalar)")
    endif()
  endif()
endif()
