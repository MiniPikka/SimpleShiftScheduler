/// FFI bindings to the Rust shift-core library.
///
/// Loads `libshift_flutter_bridge.so` and exposes C-compatible functions
/// via `dart:ffi`. All functions return JSON strings allocated by Rust;
/// callers must free them with [shiftFreeString].
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:ffi/ffi.dart';

// ── Native function signatures ──

typedef ShiftGetShiftInfoNative = Pointer<Utf8> Function(
  Pointer<Utf8> dateIso,
  Uint32 teamId,
  Uint32 cycleLength,
  Pointer<Utf8> referenceDateIso,
);

typedef ShiftGetShiftInfoDart = Pointer<Utf8> Function(
  Pointer<Utf8> dateIso,
  int teamId,
  int cycleLength,
  Pointer<Utf8> referenceDateIso,
);

typedef ShiftFreeStringNative = Void Function(Pointer<Utf8> ptr);
typedef ShiftFreeStringDart = void Function(Pointer<Utf8> ptr);

// ── Library loading ──

DynamicLibrary? _lib;

DynamicLibrary _loadLib() {
  if (_lib != null) return _lib!;

  // Try multiple paths for the shared library
  final candidates = [
    // Flutter test on Linux: relative to project root
    'rust/target/debug/libshift_flutter_bridge.so',
    // Installed system-wide
    'libshift_flutter_bridge.so',
    // Flutter Android/iOS: handled by platform-specific loading
  ];

  for (final path in candidates) {
    try {
      final lib = DynamicLibrary.open(path);
      _lib = lib;
      return lib;
    } catch (_) {}
  }

  throw UnsupportedError(
    'Cannot load libshift_flutter_bridge.so. '
    'Build it first: cd flutter/rust && cargo build'
  );
}

// ── Public API ──

/// Get shift info for a given date.
///
/// Returns a decoded JSON map, or null on error.
Map<String, dynamic>? ffiGetShiftInfo({
  required String dateIso,
  required int teamId,
  int cycleLength = 0,
  String referenceDateIso = '',
}) {
  try {
    final lib = _loadLib();
    final getShiftInfo = lib.lookupFunction<
      ShiftGetShiftInfoNative,
      ShiftGetShiftInfoDart
    >('shift_get_shift_info');
    final freeString = lib.lookupFunction<
      ShiftFreeStringNative,
      ShiftFreeStringDart
    >('shift_free_string');

    final datePtr = dateIso.toNativeUtf8();
    final refPtr = referenceDateIso.toNativeUtf8();

    final resultPtr = getShiftInfo(datePtr, teamId, cycleLength, refPtr);

    calloc.free(datePtr);
    calloc.free(refPtr);

    if (resultPtr == nullptr) return null;

    final jsonStr = resultPtr.toDartString();
    freeString(resultPtr);

    return jsonDecode(jsonStr) as Map<String, dynamic>;
  } catch (e) {
    // FFI not available (e.g. web platform) — caller should fall back to Dart impl
    return null;
  }
}
