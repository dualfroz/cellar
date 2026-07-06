import 'package:cellar/cellar.dart';
import 'package:test/test.dart';

double numberOf(CellValue value) => (value as NumberValue).value;

void main() {
  group('dependency graph recalculation', () {
    test('changing a precedent recomputes a dependent', () {
      final sheet = Sheet();
      sheet.setValue('A1', '5');
      sheet.setValue('B1', '=A1+1');
      expect(numberOf(sheet.valueOf('B1')), 6);

      sheet.setValue('A1', '10');
      expect(numberOf(sheet.valueOf('B1')), 11);
    });

    test('a chain propagates through several levels', () {
      final sheet = Sheet();
      sheet.setValue('A1', '2');
      sheet.setValue('B1', '=A1*2');
      sheet.setValue('C1', '=B1*2');
      sheet.setValue('D1', '=C1+1');
      expect(numberOf(sheet.valueOf('D1')), 9);

      sheet.setValue('A1', '5');
      expect(numberOf(sheet.valueOf('B1')), 10);
      expect(numberOf(sheet.valueOf('C1')), 20);
      expect(numberOf(sheet.valueOf('D1')), 21);
    });

    test('a single precedent feeds multiple dependents', () {
      final sheet = Sheet();
      sheet.setValue('A1', '3');
      sheet.setValue('B1', '=A1+1');
      sheet.setValue('B2', '=A1*10');
      sheet.setValue('B3', '=A1-1');
      sheet.setValue('A1', '7');
      expect(numberOf(sheet.valueOf('B1')), 8);
      expect(numberOf(sheet.valueOf('B2')), 70);
      expect(numberOf(sheet.valueOf('B3')), 6);
    });

    test('range dependencies recompute when a member changes', () {
      final sheet = Sheet();
      sheet.setValue('A1', '1');
      sheet.setValue('A2', '2');
      sheet.setValue('A3', '3');
      sheet.setValue('B1', '=SUM(A1:A3)');
      expect(numberOf(sheet.valueOf('B1')), 6);

      sheet.setValue('A2', '20');
      expect(numberOf(sheet.valueOf('B1')), 24);
    });
  });

  group('cycle detection', () {
    test('two cells referencing each other become #CYCLE!', () {
      final sheet = Sheet();
      sheet.setValue('A1', '=B1');
      sheet.setValue('B1', '=A1');
      expect(sheet.valueOf('A1'), const ErrorValue(ErrorKind.cycle));
      expect(sheet.valueOf('B1'), const ErrorValue(ErrorKind.cycle));
    });

    test('self reference is a cycle', () {
      final sheet = Sheet();
      sheet.setValue('A1', '=A1+1');
      expect(sheet.valueOf('A1'), const ErrorValue(ErrorKind.cycle));
    });

    test('a three cell cycle is detected', () {
      final sheet = Sheet();
      sheet.setValue('A1', '=B1');
      sheet.setValue('B1', '=C1');
      sheet.setValue('C1', '=A1');
      expect(sheet.valueOf('A1'), const ErrorValue(ErrorKind.cycle));
      expect(sheet.valueOf('B1'), const ErrorValue(ErrorKind.cycle));
      expect(sheet.valueOf('C1'), const ErrorValue(ErrorKind.cycle));
    });

    test('breaking a cycle restores computation', () {
      final sheet = Sheet();
      sheet.setValue('A1', '=B1');
      sheet.setValue('B1', '=A1');
      expect(sheet.valueOf('A1'), const ErrorValue(ErrorKind.cycle));

      sheet.setValue('B1', '5');
      expect(numberOf(sheet.valueOf('B1')), 5);
      expect(numberOf(sheet.valueOf('A1')), 5);
    });
  });
}
