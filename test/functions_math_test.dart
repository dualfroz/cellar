import 'package:cellar/cellar.dart';
import 'package:test/test.dart';

CellValue ev(String formula) {
  final sheet = Sheet();
  sheet.setValue('Z1', formula);
  return sheet.valueOf('Z1');
}

double num(CellValue value) => (value as NumberValue).value;

void main() {
  group('math functions', () {
    test('rounding family', () {
      expect(num(ev('=ROUND(3.14159, 2)')), 3.14);
      expect(num(ev('=ROUNDUP(3.141, 2)')), 3.15);
      expect(num(ev('=ROUNDDOWN(3.149, 2)')), 3.14);
      expect(num(ev('=ROUNDUP(-3.141, 2)')), -3.15);
      expect(num(ev('=MROUND(17, 5)')), 15);
      expect(num(ev('=TRUNC(9.99)')), 9);
      expect(num(ev('=INT(-1.1)')), -2);
    });

    test('modulo and quotient', () {
      expect(num(ev('=MOD(10, 3)')), 1);
      expect(num(ev('=MOD(-10, 3)')), 2);
      expect(num(ev('=QUOTIENT(17, 5)')), 3);
      expect(ev('=QUOTIENT(1, 0)'), const ErrorValue(ErrorKind.divZero));
    });

    test('powers, roots and logs', () {
      expect(num(ev('=POWER(2, 10)')), 1024);
      expect(num(ev('=SQRT(144)')), 12);
      expect(num(ev('=EXP(0)')), 1);
      expect(num(ev('=LN(EXP(3))')), closeTo(3, 1e-9));
      expect(num(ev('=LOG10(1000)')), closeTo(3, 1e-9));
      expect(num(ev('=LOG(8, 2)')), closeTo(3, 1e-9));
      expect(ev('=SQRT(-1)'), const ErrorValue(ErrorKind.numError));
      expect(ev('=LN(0)'), const ErrorValue(ErrorKind.numError));
    });

    test('sign, even, odd', () {
      expect(num(ev('=SIGN(-7)')), -1);
      expect(num(ev('=EVEN(3)')), 4);
      expect(num(ev('=EVEN(-1)')), -2);
      expect(num(ev('=ODD(2)')), 3);
      expect(num(ev('=ODD(-4)')), -5);
    });

    test('floor and ceil with significance', () {
      expect(num(ev('=FLOOR(7.8)')), 7);
      expect(num(ev('=FLOOR(23, 5)')), 20);
      expect(num(ev('=CEILING(23, 5)')), 25);
    });

    test('gcd, lcm, factorial, combinations', () {
      expect(num(ev('=GCD(24, 36)')), 12);
      expect(num(ev('=LCM(4, 6)')), 12);
      expect(num(ev('=FACT(5)')), 120);
      expect(num(ev('=COMBIN(5, 2)')), 10);
      expect(ev('=FACT(-1)'), const ErrorValue(ErrorKind.numError));
    });

    test('trigonometry and conversions', () {
      expect(num(ev('=SIN(0)')), 0);
      expect(num(ev('=COS(0)')), 1);
      expect(num(ev('=DEGREES(PI())')), closeTo(180, 1e-9));
      expect(num(ev('=RADIANS(180)')), closeTo(3.14159265, 1e-6));
      expect(num(ev('=ATAN2(1, 1)')), closeTo(0.785398, 1e-5));
    });

    test('RANDBETWEEN stays within bounds', () {
      for (var i = 0; i < 50; i++) {
        final value = num(ev('=RANDBETWEEN(3, 7)'));
        expect(value, inInclusiveRange(3, 7));
        expect(value, value.roundToDouble());
      }
    });
  });
}
