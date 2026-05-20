import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/shapes.dart';
import '../../core/utils/l10n.dart';
import '../../core/services/share_service.dart';
import '../../domain/algorithms/colleague_mode.dart';
import '../home/home_state.dart';
import 'share_card_data.dart';
import 'share_card_layout.dart';

class ColleagueModeScreen extends ConsumerStatefulWidget {
  const ColleagueModeScreen({super.key});
  @override
  ConsumerState<ColleagueModeScreen> createState() =>
      _ColleagueModeScreenState();
}

class _ColleagueModeScreenState extends ConsumerState<ColleagueModeScreen> {
  late int _teamAId, _teamBId;

  // 分享状态
  bool _isSharing = false;
  String? _shareError;
  ShareCardData? _shareData;
  final _shareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _teamAId = ref.read(selectedTeamProvider);
    _teamBId = _teamAId < 6 ? _teamAId + 1 : 1;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = DateTime.now();

    final cycle = settings.isValid ? settings.shiftCycle : null;
    final refDate = settings.isValid ? settings.referenceDate : null;
    final result = findCommonRestDays(
      teamAId: _teamAId,
      teamBId: _teamBId,
      today: now,
      customCycle: cycle,
      referenceDate: refDate,
      teamNameResolver: (id) => localizedTeamName(id, l10n),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.colleagueModeTitle),
        actions: [
          if (_teamAId != _teamBId && result.nextCommonRestDate != null)
            _isSharing
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.share_outlined),
                    tooltip: 'Share',
                    onPressed: () => _shareImage(result, l10n, now),
                  ),
        ],
      ),
      body: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // 离屏渲染：分享长图置于底层，被 ListView 遮盖但正常绘制
          if (_isSharing && _shareData != null)
            Positioned(
              left: 0,
              top: 0,
              child: RepaintBoundary(
                key: _shareKey,
                child: ShareCardLayout(data: _shareData!),
              ),
            ),
          // 正常内容（上层，遮住分享长图）
          ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              Expanded(
                child: _TeamPicker(
                  label: l10n.iam,
                  value: _teamAId,
                  onChanged: (id) => setState(() => _teamAId = id),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: () => setState(() {
                  final t = _teamAId;
                  _teamAId = _teamBId;
                  _teamBId = t;
                }),
              ),
              Expanded(
                child: _TeamPicker(
                  label: l10n.heis,
                  value: _teamBId,
                  onChanged: (id) => setState(() => _teamBId = id),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            if (_teamAId == _teamBId)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.sameTeam, style: theme.textTheme.bodyLarge),
                ),
              )
            else ...[
              Card(
                shape: RoundedRectangleBorder(borderRadius: CpShapes.mainCard),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: CpShapes.mainCard,
                    gradient: LinearGradient(
                      colors: [
                        shiftNight.withValues(alpha: 0.08),
                        shiftStudy.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                  child: Column(children: [
                    Text(l10n.nextCommonRest, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      result.nextCommonRestDate != null
                          ? '${result.nextCommonRestDate!.month}月${result.nextCommonRestDate!.day}日'
                          : l10n.noCommonRest,
                      style: theme.textTheme.displayLarge,
                    ),
                    if (result.daysUntilNext != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.daysUntil(result.daysUntilNext!),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _StatCard(
                    l10n.next30days,
                    l10n.dayCount(result.countIn30Days),
                    shiftRest,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    l10n.next60days,
                    l10n.dayCount(result.countIn60Days),
                    shiftAfternoon,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Text(
                l10n.commonRestDaysList(result.totalCount),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              if (result.commonRestDates.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.noCommonRestFound),
                  ),
                )
              else
                ...result.commonRestDates.take(20).map((date) {
                  final diffDays = date.difference(now).inDays;
                  return ListTile(
                    dense: true,
                    title: Text(
                      '${date.month}月${date.day}日 ${localizedWeekday(date.weekday, l10n)}',
                    ),
                    trailing: Text(
                      diffDays == 0 ? l10n.statusToday : l10n.dayCount(diffDays),
                      style: TextStyle(color: diffDays == 0 ? shiftRest : null),
                    ),
                  );
                }),
            ],
          ]),
          // 分享错误 SnackBar 提示
          if (_shareError != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Material(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Expanded(child: Text(_shareError!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer))),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _shareError = null),
                    ),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _shareImage(result, l10n, DateTime today) async {
    if (_isSharing) return;

    final nextDate = result.nextCommonRestDate;
    if (nextDate == null) return;

    setState(() {
      _isSharing = true;
      _shareError = null;
    });

    try {
      // 1. 构建 ShareCardData（可在任意线程）
      final data = ShareCardData(
        teamAName: result.teamAName,
        teamBName: result.teamBName,
        nextCommonRestDate: '${nextDate.month}月${nextDate.day}日',
        nextCommonRestWeekday: localizedWeekday(nextDate.weekday, l10n),
        daysUntilNext: result.daysUntilNext ?? 0,
        countIn30Days: result.countIn30Days,
        countIn60Days: result.countIn60Days,
        commonRestDateItems: result.commonRestDates.take(12).map<String>((d) => '${d.month}月${d.day}日 ${localizedWeekday(d.weekday, l10n)}').toList(),
        dateRange: '${today.year}/${today.month.toString().padLeft(2, '0')}/${today.day.toString().padLeft(2, '0')} — 12/31',
      );

      setState(() => _shareData = data);

      // 2. 等待下一帧渲染完成（RepaintBoundary 必须已经绘制才能 toImage）
      final frameCompleter = Completer<void>();
      WidgetsBinding.instance.addPostFrameCallback((_) => frameCompleter.complete());
      await frameCompleter.future;

      // 3. 离屏渲染
      ui.Image image;
      try {
        image = await renderToImage(_shareKey, pixelRatio: 1.0);
      } catch (e) {
        throw Exception('渲染失败: $e');
      }

      // 4. 转为 PNG bytes
      final pngBytes = await imageToPngBytes(image);
      image.dispose();

      // 5. 保存到缓存
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = await saveToCache(pngBytes, 'colleague_$timestamp');

      // 6. 调起系统分享
      await shareImageFile(
        filePath,
        subject: '${result.teamAName} & ${result.teamBName} 共同休息',
      );
    } catch (e) {
      setState(() {
        _shareError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isSharing = false;
        _shareData = null;
      });
    }
  }
}

class _TeamPicker extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _TeamPicker({required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          DropdownButton<int>(
            value: value,
            underline: const SizedBox.shrink(),
            items: List.generate(6, (i) => i + 1)
                .map((id) => DropdownMenuItem(value: id, child: Text(localizedTeamName(id, l10n))))
                .toList(),
            onChanged: (id) => id != null ? onChanged(id) : null,
          ),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}
