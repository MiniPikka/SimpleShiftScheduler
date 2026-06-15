import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/services/share_service.dart';
import '../../core/utils/l10n.dart';
import 'share_card_data.dart';

/// 同事模式分享长图布局
///
/// 深色主题，大字体，高对比度，适合社交传播。
/// 内容区用 SingleChildScrollView 包裹，RepaintBoundary 自动撑高。
class ShareCardLayout extends StatelessWidget {
  final ShareCardData data;
  const ShareCardLayout({super.key, required this.data});

  // 设计常量
  static const double _cardWidth = 1080;
  static const double _padding = 48;
  static const Color _bg = Color(0xFF0B0D10);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFFD1D5DB);
  static const Color _textMuted = Color(0xFF9CA3AF);
  static const Color _accentGold = Color(0xFFFACC15);
  static const Color _statCardBg = Color(0xFF1B1F26);
  static const Color _dateItemColor = Color(0xFFE5E7EB);
  static const Color _footerColor = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      width: _cardWidth,
      child: Container(
        color: _bg,
        padding: const EdgeInsets.all(_padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 品牌标题
            Text(
              l10n.appTitle,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: _textSecondary),
            ),
            const SizedBox(height: 48),

            // 主结果卡片
            _MainResultCard(data: data),
            const SizedBox(height: 40),

            // 统计行
            _StatsRow(data: data),
            const SizedBox(height: 40),

            // 日期列表
            _DateList(data: data),
            const SizedBox(height: 48),

            // QR 码
            _QrSection(),
            const SizedBox(height: 40),

            // 底部信息
            Text(
              l10n.slogan,
              style: const TextStyle(fontSize: 22, color: _footerColor),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.analysisRange(data.dateRange),
              style: const TextStyle(fontSize: 18, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// 主结果卡片：渐变背景 + 班组名 + 大字体日期 + 倒计时
class _MainResultCard extends StatelessWidget {
  final ShareCardData data;
  const _MainResultCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0x667C5CFF), Color(0x404DA3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // 班组名
          Text(
            '${data.teamAName} × ${data.teamBName}',
            style: const TextStyle(fontSize: 26, color: ShareCardLayout._textSecondary),
          ),
          const SizedBox(height: 24),
          // 大日期
          Text(
            data.nextCommonRestDate,
            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: ShareCardLayout._textPrimary),
          ),
          const SizedBox(height: 12),
          // 星期
          Text(
            data.nextCommonRestWeekday,
            style: const TextStyle(fontSize: 30, color: ShareCardLayout._textSecondary),
          ),
          const SizedBox(height: 20),
          // 倒计时
          Text(
            context.l10n.daysUntil(data.daysUntilNext),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: ShareCardLayout._accentGold),
          ),
        ],
      ),
    );
  }
}

/// 统计卡片行：30 天 / 60 天
class _StatsRow extends StatelessWidget {
  final ShareCardData data;
  const _StatsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(child: _StatCard(title: l10n.next30days, count: data.countIn30Days)),
        const SizedBox(width: 20),
        Expanded(child: _StatCard(title: l10n.next60days, count: data.countIn60Days)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  const _StatCard({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: ShareCardLayout._statCardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            context.l10n.countTimes(count),
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: ShareCardLayout._textPrimary),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 22, color: ShareCardLayout._textSecondary)),
        ],
      ),
    );
  }
}

/// 共同休息日列表（2 列，最多 12 项）
class _DateList extends StatelessWidget {
  final ShareCardData data;
  const _DateList({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = data.commonRestDateItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(
          context.l10n.commonRestDaysList(items.length),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: ShareCardLayout._textSecondary),
        ),
        const SizedBox(height: 20),
        // 2 列布局
        ...List.generate((items.length + 1) ~/ 2, (row) {
          final left = items[row * 2];
          final right = row * 2 + 1 < items.length ? items[row * 2 + 1] : null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(child: _DateItem(text: left)),
                const SizedBox(width: 24),
                Expanded(child: right != null ? _DateItem(text: right) : const SizedBox()),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _DateItem extends StatelessWidget {
  final String text;
  const _DateItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '•',
          style: TextStyle(fontSize: 24, color: ShareCardLayout._accentGold, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 24, color: ShareCardLayout._dateItemColor),
          ),
        ),
      ],
    );
  }
}

/// QR 码区
class _QrSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          child: QrImageView(
            data: shareQrUrl,
            version: QrVersions.auto,
            size: 240,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.scanToDownload,
          style: const TextStyle(fontSize: 20, color: ShareCardLayout._textMuted),
        ),
      ],
    );
  }
}
