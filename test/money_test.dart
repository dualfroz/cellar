import 'package:cellar/cellar.dart';
import 'package:test/test.dart';

void main() {
  group('money', () {
    test('constructs minor units with rounding', () {
      expect(Money.of(19.99, Currency.pln).minor, 1999);
      expect(Money.of(19.999, Currency.pln).minor, 2000);
      expect(Money.parse('19.99', Currency.pln).minor, 1999);
    });

    test('scaling multiplies exactly with rounding', () {
      expect(Money.of(10, Currency.pln).scaled(3), Money.of(30, Currency.pln));
      expect(Money.of(0.10, Currency.pln).scaled(0.23), Money.of(0.02, Currency.pln));
    });

    test('addition and subtraction', () {
      final sum = Money.of(19.99, Currency.pln) + Money.of(0.01, Currency.pln);
      expect(sum, Money.of(20.00, Currency.pln));
      final diff = Money.of(20.00, Currency.pln) - Money.of(5.50, Currency.pln);
      expect(diff, Money.of(14.50, Currency.pln));
    });

    test('formatting groups and places the symbol', () {
      expect(Money.of(1234.5, Currency.pln).format(), '1 234.50 zl');
      expect(Money.of(5, Currency.usd).format(), r'$5.00');
    });

    test('currency mismatch is rejected', () {
      expect(
        () => Money.of(1, Currency.pln) + Money.of(1, Currency.eur),
        throwsArgumentError,
      );
    });

    test('conversion applies an exchange rate', () {
      final converted = Money.of(100, Currency.pln).convertedTo(Currency.eur, 0.25);
      expect(converted, Money.of(25, Currency.eur));
    });

    test('known currencies resolve by code', () {
      expect(Currency.byCode('usd').symbolBefore, isTrue);
      expect(Currency.byCode('EUR').code, 'EUR');
    });
  });
}
