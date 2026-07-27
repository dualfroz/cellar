import 'package:cellar/cellar.dart';
import 'package:test/test.dart';

CellValue ev(String formula) {
  final sheet = Sheet();
  sheet.setValue('Z1', formula);
  return sheet.valueOf('Z1');
}

double num(CellValue value) => (value as NumberValue).value;

void main() {
  group('financial functions', () {
    test('PMT for a mortgage', () {
      expect(num(ev('=PMT(0.05/12, 360, 200000)')), closeTo(-1073.64, 0.01));
    });

    test('PMT with a zero rate', () {
      expect(num(ev('=PMT(0, 10, 1000)')), -100);
    });

    test('FV of a savings plan', () {
      expect(num(ev('=FV(0.06/12, 120, -100)')), closeTo(16387.93, 0.01));
      expect(num(ev('=FV(0, 10, -100)')), 1000);
    });

    test('PV of an annuity', () {
      expect(num(ev('=PV(0.05, 10, -1000)')), closeTo(7721.73, 0.01));
      expect(num(ev('=PV(0, 10, -100)')), 1000);
    });

    test('NPV discounts future flows', () {
      expect(num(ev('=NPV(0.1, 100, 200, 300)')), closeTo(481.59, 0.01));
    });

    test('IRR of a project', () {
      final sheet = Sheet();
      sheet.setValue('A1', '-1000');
      sheet.setValue('A2', '400');
      sheet.setValue('A3', '400');
      sheet.setValue('A4', '400');
      sheet.setValue('B1', '=IRR(A1:A4)');
      expect(num(sheet.valueOf('B1')), closeTo(0.0971, 0.001));
    });

    test('NPER inverts PMT', () {
      final sheet = Sheet();
      sheet.setValue('A1', '=PMT(0.01, 24, 1000)');
      sheet.setValue('A2', '=NPER(0.01, A1, 1000)');
      expect(num(sheet.valueOf('A2')), closeTo(24, 0.01));
    });

    test('RATE inverts PMT', () {
      final sheet = Sheet();
      sheet.setValue('A1', '=PMT(0.02, 36, 5000)');
      sheet.setValue('A2', '=RATE(36, A1, 5000)');
      expect(num(sheet.valueOf('A2')), closeTo(0.02, 1e-4));
    });
  });
}
