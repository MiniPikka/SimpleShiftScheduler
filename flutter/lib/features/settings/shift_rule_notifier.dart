import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/shift_type.dart';
import '../../domain/models/runtime_shift_settings.dart';
import '../../domain/models/team.dart';
import '../../domain/models/shift_cycle_config.dart';
import '../../data/providers.dart';
import '../home/home_state.dart';

class ShiftRuleUiState {
  final int cycleLength;
  final List<ShiftType> sequence;
  final int defaultTeamId;
  final DateTime startDate;
  final bool isDirty;
  final bool isSaved;
  final bool isLoading;

  ShiftRuleUiState({
    this.cycleLength = ShiftCycleConfig.cycleLength,
    this.sequence = ShiftCycleConfig.shiftCycle,
    this.defaultTeamId = 1,
    DateTime? startDate,
    this.isDirty = false,
    this.isSaved = false,
    this.isLoading = true,
  }) : startDate = startDate ?? ShiftCycleConfig.referenceDate;

  ShiftRuleUiState copyWith({
    int? cycleLength,
    List<ShiftType>? sequence,
    int? defaultTeamId,
    DateTime? startDate,
    bool? isDirty,
    bool? isSaved,
    bool? isLoading,
  }) {
    return ShiftRuleUiState(
      cycleLength: cycleLength ?? this.cycleLength,
      sequence: sequence ?? this.sequence,
      defaultTeamId: defaultTeamId ?? this.defaultTeamId,
      startDate: startDate ?? this.startDate,
      isDirty: isDirty ?? this.isDirty,
      isSaved: isSaved ?? this.isSaved,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final shiftRuleProvider =
    NotifierProvider<ShiftRuleNotifier, ShiftRuleUiState>(
  ShiftRuleNotifier.new,
);

class ShiftRuleNotifier extends Notifier<ShiftRuleUiState> {
  @override
  ShiftRuleUiState build() {
    // Listen for repo availability, then load saved settings
    ref.listen(hiveRepoProvider, (prev, next) {
      next.whenData((repo) async {
        final settings = await repo.loadSettings();
        state = ShiftRuleUiState(
          cycleLength: settings.cycleLength,
          sequence: List.from(settings.shiftCycle),
          defaultTeamId: settings.defaultTeamId,
          startDate: settings.referenceDate,
          isLoading: false,
        );
      });
    });
    return ShiftRuleUiState();
  }

  void setCycleLength(int n) {
    if (n < 1 || n > 100) return;
    var seq = List<ShiftType>.from(state.sequence);
    if (n > seq.length) {
      // Fill with REST
      seq.addAll(List.filled(n - seq.length, ShiftType.REST));
    } else if (n < seq.length) {
      // Truncate
      seq = seq.sublist(0, n);
    }
    state = state.copyWith(cycleLength: n, sequence: seq, isDirty: true, isSaved: false);
  }

  void addShift(ShiftType type) {
    final seq = List<ShiftType>.from(state.sequence)..add(type);
    final newLen = seq.length > state.cycleLength ? seq.length : state.cycleLength;
    state = state.copyWith(cycleLength: newLen, sequence: seq, isDirty: true, isSaved: false);
  }

  void removeShift(int index) {
    if (index < 0 || index >= state.sequence.length) return;
    if (state.sequence.length <= 1) return; // Keep at least 1
    final seq = List<ShiftType>.from(state.sequence)..removeAt(index);
    final newLen = seq.length < state.cycleLength ? state.cycleLength : seq.length;
    state = state.copyWith(cycleLength: newLen, sequence: seq, isDirty: true, isSaved: false);
  }

  void setStartDate(DateTime date) {
    state = state.copyWith(startDate: date, isDirty: true, isSaved: false);
  }

  void setDefaultTeam(int teamId) {
    if (teamId < 1 || teamId > Team.totalTeams) return;
    state = state.copyWith(defaultTeamId: teamId, isDirty: true, isSaved: false);
  }

  /// Apply a preset cycle
  void applyPreset(List<ShiftType> preset) {
    if (preset.isEmpty) return;
    state = state.copyWith(
      cycleLength: preset.length,
      sequence: List.from(preset),
      isDirty: true,
      isSaved: false,
    );
  }

  /// Clear all shifts
  void clearAll() {
    state = state.copyWith(cycleLength: 1, sequence: [ShiftType.REST], isDirty: true, isSaved: false);
  }

  Future<void> save() async {
    final s = state;
    final settings = RuntimeShiftSettings(
      cycleLength: s.cycleLength,
      shiftCycle: s.sequence,
      defaultTeamId: s.defaultTeamId,
      referenceDate: s.startDate,
    );
    // Update the global settingsProvider → triggers home/calendar refresh + calendar resync
    ref.read(settingsProvider.notifier).update(settings);
    state = state.copyWith(isDirty: false, isSaved: true);
    // Reset saved indicator after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      state = state.copyWith(isSaved: false);
    });
  }
}
