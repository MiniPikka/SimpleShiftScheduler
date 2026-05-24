import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/bridge/ffi_bridge.dart';

/// Linux desktop calendar sync via ICS file export.
///
/// Generates an ICS file from the Rust shift engine and writes it
/// to XDG_DATA_HOME/banban/shifts.ics. The user can import this into
/// any calendar app (GNOME Calendar, KDE Kalendar, Thunderbird, etc.).
class LinuxCalendarSync {
  static String get _dataHome =>
      Platform.environment['XDG_DATA_HOME'] ??
      '${Platform.environment['HOME']}/.local/share';

  static String get icsPath => '$_dataHome/banban/shifts.ics';

  /// Generate ICS for the rest of the year and write to disk.
  /// Returns the number of events written, or 0 on failure.
  static Future<int> sync({
    required int teamId,
    required int cycleLength,
    required DateTime referenceDate,
    String timezone = 'Asia/Shanghai',
  }) async {
    final today = DateTime.now();
    final endOfYear = DateTime(today.year, 12, 31);

    debugPrint('ICS sync: generating from $today to $endOfYear, team=$teamId, cycleLen=$cycleLength');
    final result = ffiGenerateIcs(
      startDate: today,
      endDate: endOfYear,
      teamId: teamId,
      cycleLength: cycleLength,
      referenceDate: referenceDate,
      timezone: timezone,
    );

    if (result == null) {
      debugPrint('ICS sync: FFI returned null — bridge may not be loaded');
      return 0;
    }
    if (result['ics'] == null) {
      debugPrint('ICS sync: FFI result missing "ics" key: $result');
      return 0;
    }

    final ics = result['ics'] as String;
    // Count VEVENTs in the ICS output (Rust doesn't include a count field)
    final count = 'BEGIN:VEVENT\r\n'.allMatches(ics).length;
    debugPrint('ICS sync: got ${ics.length} chars, $count events');
    if (ics.isEmpty || count == 0) return 0;

    final file = File(icsPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(ics);
    debugPrint('ICS sync: written to $icsPath');

    return count;
  }

  /// Open the ICS file with the system's default calendar application.
  static Future<bool> openWithDefaultApp() async {
    if (!await File(icsPath).exists()) return false;
    try {
      final r = await Process.run('xdg-open', [icsPath]);
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Check if the banban systemd timer is active.
  static Future<bool> isSystemdTimerActive() async {
    try {
      final result = await Process.run(
        'systemctl', ['--user', 'is-active', 'banban-ics.timer'],
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
