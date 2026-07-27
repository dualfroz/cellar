import 'package:cellar/cellar.dart';
import 'package:test/test.dart';

void main() {
  group('number format', () {
    test('grouped decimals', () {
      const format = NumberFormat.decimal(decimals: 2, thousands: true);
      expect(format.apply(const NumberValue(1234567.891)), '1,234,567.89');
      expect(format.apply(const NumberValue(-5.5)), '-5.50');
    });

    test('percent scales by a hundred', () {
      const format = NumberFormat.percent(decimals: 1);
      expect(format.apply(const NumberValue(0.1234)), '12.3%');
    });

    test('currency before and after', () {
      const before = NumberFormat.currency(r'$', decimals: 2);
      const after = NumberFormat.currency('zl', decimals: 2, before: false, thousands: false);
      expect(before.apply(const NumberValue(1234.5)), r'$1,234.50');
      expect(after.apply(const NumberValue(30)), '30.00zl');
    });

    test('integer with thousands', () {
      const format = NumberFormat.integer(thousands: true);
      expect(format.apply(const NumberValue(1234567)), '1,234,567');
    });

    test('non-number values fall through to display', () {
      const format = NumberFormat.decimal(decimals: 2);
      expect(format.apply(const TextValue('hello')), 'hello');
      expect(format.apply(const ErrorValue(ErrorKind.divZero)), '#DIV/0!');
    });

    test('fromCode parses common patterns', () {
      expect(NumberFormat.fromCode('#,##0.00').apply(const NumberValue(1234.5)), '1,234.50');
      expect(NumberFormat.fromCode('0.0%').apply(const NumberValue(0.25)), '25.0%');
      expect(NumberFormat.fromCode(r'$#,##0.00').apply(const NumberValue(1234.5)), r'$1,234.50');
    });

    test('toCode round trips', () {
      expect(const NumberFormat.decimal(decimals: 2, thousands: true).toCode(), '#,##0.00');
      expect(const NumberFormat.percent(decimals: 1).toCode(), '0.0%');
      expect(const NumberFormat.integer(thousands: true).toCode(), '#,##0');
    });
  });
}
