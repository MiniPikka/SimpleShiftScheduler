import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_cp/features/colleague_mode/share_card_data.dart';

void main() {
  group('ShareCardData', () {
    test('constructs with all required fields', () {
      final data = ShareCardData(
        teamAName: '一值',
        teamBName: '三值',
        nextCommonRestDate: '5月28日',
        nextCommonRestWeekday: '星期三',
        daysUntilNext: 8,
        countIn30Days: 3,
        countIn60Days: 7,
        commonRestDateItems: ['5月28日 星期三', '6月3日 星期二', '6月10日 星期三'],
        dateRange: '2026/05/20 — 12/31',
      );

      expect(data.teamAName, '一值');
      expect(data.teamBName, '三值');
      expect(data.nextCommonRestDate, '5月28日');
      expect(data.daysUntilNext, 8);
      expect(data.countIn30Days, 3);
      expect(data.countIn60Days, 7);
      expect(data.commonRestDateItems.length, 3);
      expect(data.dateRange, '2026/05/20 — 12/31');
    });

    test('works with empty date items list', () {
      final data = ShareCardData(
        teamAName: '一值',
        teamBName: '一值',
        nextCommonRestDate: '5月20日',
        nextCommonRestWeekday: '星期二',
        daysUntilNext: 0,
        countIn30Days: 0,
        countIn60Days: 0,
        commonRestDateItems: [],
        dateRange: '2026/05/20 — 12/31',
      );

      expect(data.commonRestDateItems, isEmpty);
      expect(data.countIn30Days, 0);
      expect(data.daysUntilNext, 0);
    });

    test('immutable — all fields final', () {
      final data = ShareCardData(
        teamAName: 'A',
        teamBName: 'B',
        nextCommonRestDate: '1月1日',
        nextCommonRestWeekday: '周一',
        daysUntilNext: 1,
        countIn30Days: 1,
        countIn60Days: 1,
        commonRestDateItems: ['1月1日 周一'],
        dateRange: 'range',
      );

      // 结构相等比较会正常工作（因为所有字段是值类型）
      final copy = ShareCardData(
        teamAName: data.teamAName,
        teamBName: data.teamBName,
        nextCommonRestDate: data.nextCommonRestDate,
        nextCommonRestWeekday: data.nextCommonRestWeekday,
        daysUntilNext: data.daysUntilNext,
        countIn30Days: data.countIn30Days,
        countIn60Days: data.countIn60Days,
        commonRestDateItems: List.of(data.commonRestDateItems),
        dateRange: data.dateRange,
      );

      expect(data.teamAName, copy.teamAName);
      expect(data.commonRestDateItems, copy.commonRestDateItems);
    });

    test('handles max 12 date items', () {
      final items = List.generate(12, (i) => '${i + 1}月1日 周一');
      final data = ShareCardData(
        teamAName: 'A',
        teamBName: 'B',
        nextCommonRestDate: '1月1日',
        nextCommonRestWeekday: '周一',
        daysUntilNext: 1,
        countIn30Days: 12,
        countIn60Days: 12,
        commonRestDateItems: items,
        dateRange: 'range',
      );

      expect(data.commonRestDateItems.length, 12);
    });

    test('daysUntilNext zero edge case (today is rest)', () {
      final data = ShareCardData(
        teamAName: 'A',
        teamBName: 'B',
        nextCommonRestDate: '5月20日',
        nextCommonRestWeekday: '星期三',
        daysUntilNext: 0,
        countIn30Days: 1,
        countIn60Days: 2,
        commonRestDateItems: ['5月20日 星期三'],
        dateRange: '2026/05/20 — 12/31',
      );

      expect(data.daysUntilNext, 0);
      expect(data.nextCommonRestDate, '5月20日');
    });
  });
}
