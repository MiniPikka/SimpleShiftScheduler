/// FFI bindings to the Rust shift-core library.
///
/// Every function returns a decoded JSON map, or null if FFI is unavailable.
/// Callers must fall back to pure Dart when null is returned.
library;

import 'dart:ffi';
import 'dart:convert';
import 'package:ffi/ffi.dart';

// ── Native types ──

typedef _CFunc0 = Pointer<Utf8> Function();
typedef _DFunc0 = Pointer<Utf8> Function();

typedef _CFunc1 = Pointer<Utf8> Function(Pointer<Utf8>, Uint32, Uint32, Pointer<Utf8>);
typedef _DFunc1 = Pointer<Utf8> Function(Pointer<Utf8>, int, int, Pointer<Utf8>);

typedef _CFunc2 = Pointer<Utf8> Function(Int32, Uint32, Uint32, Uint32, Pointer<Utf8>);
typedef _DFunc2 = Pointer<Utf8> Function(int, int, int, int, Pointer<Utf8>);

typedef _CFunc3 = Pointer<Utf8> Function(Uint32, Uint32, Pointer<Utf8>, Uint32, Uint32, Pointer<Utf8>);
typedef _DFunc3 = Pointer<Utf8> Function(int, int, Pointer<Utf8>, int, int, Pointer<Utf8>);

typedef _CFunc4 = Pointer<Utf8> Function(Pointer<Utf8>, Uint32, Uint32, Uint32, Uint32, Pointer<Utf8>);
typedef _DFunc4 = Pointer<Utf8> Function(Pointer<Utf8>, int, int, int, int, Pointer<Utf8>);

typedef _CFuncRange = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Uint32, Uint32, Pointer<Utf8>);
typedef _DFuncRange = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, int, int, Pointer<Utf8>);

typedef _CFuncIcs = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Uint32, Uint32, Pointer<Utf8>, Pointer<Utf8>);
typedef _DFuncIcs = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, int, int, Pointer<Utf8>, Pointer<Utf8>);

typedef _CFree = Void Function(Pointer<Utf8>);
typedef _DFree = void Function(Pointer<Utf8>);

// ── Library loading ──

DynamicLibrary? _lib;
bool _tried = false;

DynamicLibrary? _loadLib() {
  if (_tried) return _lib;
  _tried = true;

  // Order: Android (no path prefix), then Linux test, then Linux release
  final candidates = [
    'libshift_flutter_bridge.so',                     // Android / installed system-wide
    'rust/target/debug/libshift_flutter_bridge.so',   // Linux flutter test
    'rust/target/release/libshift_flutter_bridge.so', // Linux release
  ];

  for (final name in candidates) {
    try {
      _lib = DynamicLibrary.open(name);
      return _lib;
    } catch (_) {}
  }
  return null;
}

String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

dynamic _call(String name, List<Object?> args, dynamic Function(DynamicLibrary lib) callFn) {
  final lib = _loadLib();
  if (lib == null) return null;
  try {
    return callFn(lib);
  } catch (_) {
    return null;
  }
}

// ── Public FFI API ──

Map<String, dynamic>? ffiGetShiftTypeForDate({
  required DateTime date,
  required int teamId,
  int cycleLength = 0,
  DateTime? referenceDate,
}) {
  return _call('shift_get_shift_type_for_date', [], (lib) {
    final fn = lib.lookupFunction<_CFunc1, _DFunc1>('shift_get_shift_type_for_date');
    final free = lib.lookupFunction<_CFree, _DFree>('shift_free_string');
    final dp = _fmt(date).toNativeUtf8();
    final rp = _fmt(referenceDate ?? DateTime(2025, 12, 15)).toNativeUtf8();
    final ptr = fn(dp, teamId, cycleLength, rp);
    final json = ptr.toDartString();
    free(ptr);
    calloc.free(dp); calloc.free(rp);
    return jsonDecode(json);
  });
}

// ──

List<Map<String, dynamic>>? ffiGetShiftInfoRange({
  required DateTime startDate,
  required DateTime endDate,
  required int teamId,
  int cycleLength = 0,
  DateTime? referenceDate,
}) {
  final result = _call('shift_get_shift_info_range', [], (lib) {
    final fn = lib.lookupFunction<_CFuncRange, _DFuncRange>('shift_get_shift_info_range');
    final free = lib.lookupFunction<_CFree, _DFree>('shift_free_string');
    final sp = _fmt(startDate).toNativeUtf8();
    final ep = _fmt(endDate).toNativeUtf8();
    final rp = _fmt(referenceDate ?? DateTime(2025, 12, 15)).toNativeUtf8();
    final ptr = fn(sp, ep, teamId, cycleLength, rp);
    final json = ptr.toDartString();
    free(ptr);
    calloc.free(sp); calloc.free(ep); calloc.free(rp);
    return jsonDecode(json);
  });
  if (result == null || result['days'] == null) return null;
  return (result['days'] as List).cast<Map<String, dynamic>>();
}

Map<String, dynamic>? ffiGetShiftInfo({
  required DateTime date,
  required int teamId,
  int cycleLength = 0,
  DateTime? referenceDate,
}) {
  return _call('shift_get_shift_info', [], (lib) {
    final fn = lib.lookupFunction<_CFunc1, _DFunc1>('shift_get_shift_info');
    final free = lib.lookupFunction<_CFree, _DFree>('shift_free_string');
    final dp = _fmt(date).toNativeUtf8();
    final rp = _fmt(referenceDate ?? DateTime(2025, 12, 15)).toNativeUtf8();
    final ptr = fn(dp, teamId, cycleLength, rp);
    final json = ptr.toDartString();
    free(ptr);
    calloc.free(dp); calloc.free(rp);
    return jsonDecode(json);
  });
}

Map<String, dynamic>? ffiGetDaysUntilRest({
  required DateTime date,
  required int teamId,
  int cycleLength = 0,
  DateTime? referenceDate,
}) {
  return _call('shift_get_days_until_rest', [], (lib) {
    final fn = lib.lookupFunction<_CFunc1, _DFunc1>('shift_get_days_until_rest');
    final free = lib.lookupFunction<_CFree, _DFree>('shift_free_string');
    final dp = _fmt(date).toNativeUtf8();
    final rp = _fmt(referenceDate ?? DateTime(2025, 12, 15)).toNativeUtf8();
    final ptr = fn(dp, teamId, cycleLength, rp);
    final json = ptr.toDartString();
    free(ptr);
    calloc.free(dp); calloc.free(rp);
    return jsonDecode(json);
  });
}

Map<String, dynamic>? ffiGetConsecutiveWorkDays({
  required DateTime date,
  required int teamId,
  int cycleLength = 0,
  DateTime? referenceDate,
}) {
  return _call('shift_get_consecutive_work_days', [], (lib) {
    final fn = lib.lookupFunction<_CFunc1, _DFunc1>('shift_get_consecutive_work_days');
    final free = lib.lookupFunction<_CFree, _DFree>('shift_free_string');
    final dp = _fmt(date).toNativeUtf8();
    final rp = _fmt(referenceDate ?? DateTime(2025, 12, 15)).toNativeUtf8();
    final ptr = fn(dp, teamId, cycleLength, rp);
    final json = ptr.toDartString();
    free(ptr);
    calloc.free(dp); calloc.free(rp);
    return jsonDecode(json);
  });
}

Map<String, dynamic>? ffiGetMonthlyStats({
  required int year,
  required int month,
  required int teamId,
  int cycleLength = 0,
  DateTime? referenceDate,
}) {
  return _call('shift_get_monthly_stats', [], (lib) {
    final fn = lib.lookupFunction<_CFunc2, _DFunc2>('shift_get_monthly_stats');
    final free = lib.lookupFunction<_CFree, _DFree>('shift_free_string');
    final rp = _fmt(referenceDate ?? DateTime(2025, 12, 15)).toNativeUtf8();
    final ptr = fn(year, month, teamId, cycleLength, rp);
    final json = ptr.toDartString();
    free(ptr);
    calloc.free(rp);
    return jsonDecode(json);
  });
}

Map<String, dynamic>? ffiGetCommonRestDays({
  required int teamA,
  required int teamB,
  required DateTime today,
  required int daysToAnalyze,
  int cycleLength = 0,
  DateTime? referenceDate,
}) {
  return _call('shift_get_common_rest_days', [], (lib) {
    final fn = lib.lookupFunction<_CFunc3, _DFunc3>('shift_get_common_rest_days');
    final free = lib.lookupFunction<_CFree, _DFree>('shift_free_string');
    final dp = _fmt(today).toNativeUtf8();
    final rp = _fmt(referenceDate ?? DateTime(2025, 12, 15)).toNativeUtf8();
    final ptr = fn(teamA, teamB, dp, daysToAnalyze, cycleLength, rp);
    final json = ptr.toDartString();
    free(ptr);
    calloc.free(dp); calloc.free(rp);
    return jsonDecode(json);
  });
}

Map<String, dynamic>? ffiGetHolidays() {
  return _call('shift_get_holidays', [], (lib) {
    final fn = lib.lookupFunction<_CFunc0, _DFunc0>('shift_get_holidays');
    final free = lib.lookupFunction<_CFree, _DFree>('shift_free_string');
    final ptr = fn();
    final json = ptr.toDartString();
    free(ptr);
    return jsonDecode(json);
  });
}

Map<String, dynamic>? ffiGenerateIcs({
  required DateTime startDate,
  required DateTime endDate,
  required int teamId,
  int cycleLength = 0,
  DateTime? referenceDate,
  String timezone = 'Asia/Shanghai',
}) {
  return _call('shift_generate_ics', [], (lib) {
    final fn = lib.lookupFunction<_CFuncIcs, _DFuncIcs>('shift_generate_ics');
    final free = lib.lookupFunction<_CFree, _DFree>('shift_free_string');
    final sp = _fmt(startDate).toNativeUtf8();
    final ep = _fmt(endDate).toNativeUtf8();
    final rp = _fmt(referenceDate ?? DateTime(2025, 12, 15)).toNativeUtf8();
    final tp = timezone.toNativeUtf8();
    final ptr = fn(sp, ep, teamId, cycleLength, rp, tp);
    final json = ptr.toDartString();
    free(ptr);
    calloc.free(sp); calloc.free(ep); calloc.free(rp); calloc.free(tp);
    return jsonDecode(json);
  });
}

Map<String, dynamic>? ffiGetBestLeavePlans({
  required DateTime today,
  required int daysToAnalyze,
  required int teamId,
  required int maxLeaveDays,
  int cycleLength = 0,
  DateTime? referenceDate,
}) {
  return _call('shift_get_best_leave_plans', [], (lib) {
    final fn = lib.lookupFunction<_CFunc4, _DFunc4>('shift_get_best_leave_plans');
    final free = lib.lookupFunction<_CFree, _DFree>('shift_free_string');
    final dp = _fmt(today).toNativeUtf8();
    final rp = _fmt(referenceDate ?? DateTime(2025, 12, 15)).toNativeUtf8();
    final ptr = fn(dp, daysToAnalyze, teamId, maxLeaveDays, cycleLength, rp);
    final json = ptr.toDartString();
    free(ptr);
    calloc.free(dp); calloc.free(rp);
    return jsonDecode(json);
  });
}
