import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/services/share_service.dart';
import 'share_card_data.dart';

/// 同事模式分享长图布局 — 对应 Android 版 ShareCardLayout
///
/// 1080×1920px 逻辑尺寸，pixelRatio=1.0 离屏渲染。
/// 深色主题，信息密度高，适合社交传播。

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
    // 使用固定宽度 SizedBox + SingleChildScrollView 来容纳内容
    return SizedBox(
      width: _cardWidth,
      child: Container(
        color: _bg,
        padding: const EdgeInsets.all(_padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App 名称
            Text('倒班助手', style: const TextStyle(fontSize: 20, color: _textSecondary)),
            const SizedBox(height: 36),
            // 区标题
            Text('下次同时休息', style: const TextStyle(fontSize: 24, color: _textSecondary)),
            const SizedBox(height: 24),
            // 主结果卡片
            _MainResultCard(data: data),
            const SizedBox(height: 32),
            // 统计卡片行
            _StatsRow(data: data),
            const SizedBox(height: 32),
            // 共同休息日列表
            _DateList(data: data),
            const SizedBox(height: 36),
            // QR 码区
            _QrSection(),
            const SizedBox(height: 36),
            // 页脚
            Text('倒班助手 · 你的智能排班管家', style: const TextStyle(fontSize: 18, color: _footerColor)),
            const SizedBox(height: 8),
            Text('分析范围：${data.dateRange}', style: const TextStyle(fontSize: 16, color: Color(0xFF4B5563))),
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
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0x667C5CFF), Color(0x404DA3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            '${data.teamAName} × ${data.teamBName}',
            style: const TextStyle(fontSize: 18, color: ShareCardLayout._textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            data.nextCommonRestDate,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: ShareCardLayout._textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            data.nextCommonRestWeekday,
            style: const TextStyle(fontSize: 22, color: ShareCardLayout._textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            '距今 ${data.daysUntilNext} 天',
            style: const TextStyle(fontSize: 20, color: ShareCardLayout._accentGold),
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
    return Row(
      children: [
        Expanded(child: _StatCard(title: '未来30天', count: data.countIn30Days)),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(title: '未来60天', count: data.countIn60Days)),
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
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: ShareCardLayout._statCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '$count 次',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: ShareCardLayout._textPrimary),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 16, color: ShareCardLayout._textSecondary)),
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
        Text(
          '共同休息日（共 ${items.length} 次）',
          style: const TextStyle(fontSize: 20, color: ShareCardLayout._textSecondary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: (ShareCardLayout._cardWidth - ShareCardLayout._padding * 2 - 24) / 2,
              child: Row(
                children: [
                  const Text('•', style: TextStyle(fontSize: 18, color: ShareCardLayout._dateItemColor)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 18, color: ShareCardLayout._dateItemColor))),
                ],
              ),
            );
          }).toList(),
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
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(12),
          child: QrImageView(
            data: shareQrUrl,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '扫码下载倒班助手',
          style: TextStyle(fontSize: 16, color: ShareCardLayout._textMuted),
        ),
      ],
    );
  }
}
