import 'package:cellar/cellar.dart';
import 'package:test/test.dart';

double num(CellValue value) => (value as NumberValue).value;

Sheet withColumn(List<String> values) {
  final sheet = Sheet();
  for (var i = 0; i < values.length; i++) {
    sheet.setValue('A${i + 1}', values[i]);
  }
  return sheet;
}

void main() {
  group('statistics functions', () {
    test('MEDIAN', () {
      final odd = withColumn(['3', '1', '2']);
      odd.setValue('B1', '=MEDIAN(A1:A3)');
      expect(num(odd.valueOf('B1')), 2);
      final even = withColumn(['1', '2', '3', '4']);
      even.setValue('B1', '=MEDIAN(A1:A4)');
      expect(num(even.valueOf('B1')), 2.5);
    });

    test('MODE finds the most frequent value', () {
      final sheet = withColumn(['2', '4', '4', '7', '4', '2']);
      sheet.setValue('B1', '=MODE(A1:A6)');
      expect(num(sheet.valueOf('B1')), 4);
    });

    test('COUNT COUNTA COUNTBLANK', () {
      final sheet = Sheet();
      sheet.setValue('A1', '10');
      sheet.setValue('A2', 'text');
      sheet.setValue('A4', '5');
      sheet.setValue('C1', '=COUNT(A1:A4)');
      sheet.setValue('C2', '=COUNTA(A1:A4)');
      sheet.setValue('C3', '=COUNTBLANK(A1:A4)');
      expect(num(sheet.valueOf('C1')), 2);
      expect(num(sheet.valueOf('C2')), 3);
      expect(num(sheet.valueOf('C3')), 1);
    });

    test('variance and standard deviation', () {
      final sheet = withColumn(['2', '4', '4', '4', '5', '5', '7', '9']);
      sheet.setValue('B1', '=VARP(A1:A8)');
      sheet.setValue('B2', '=STDEVP(A1:A8)');
      sheet.setValue('B3', '=VAR(A1:A8)');
      expect(num(sheet.valueOf('B1')), closeTo(4, 1e-9));
      expect(num(sheet.valueOf('B2')), closeTo(2, 1e-9));
      expect(num(sheet.valueOf('B3')), closeTo(4.5714286, 1e-6));
    });

    test('LARGE SMALL RANK', () {
      final sheet = withColumn(['5', '1', '9', '3']);
      sheet.setValue('B1', '=LARGE(A1:A4, 1)');
      sheet.setValue('B2', '=SMALL(A1:A4, 2)');
      sheet.setValue('B3', '=RANK(9, A1:A4)');
      sheet.setValue('B4', '=RANK(1, A1:A4, 1)');
      expect(num(sheet.valueOf('B1')), 9);
      expect(num(sheet.valueOf('B2')), 3);
      expect(num(sheet.valueOf('B3')), 1);
      expect(num(sheet.valueOf('B4')), 1);
    });

    test('PERCENTILE interpolates', () {
      final sheet = withColumn(['1', '2', '3', '4']);
      sheet.setValue('B1', '=PERCENTILE(A1:A4, 0.5)');
      expect(num(sheet.valueOf('B1')), 2.5);
    });

    test('AVERAGE of an empty selection is #DIV/0!', () {
      final sheet = Sheet();
      sheet.setValue('B1', '=AVERAGE(A1:A3)');
      expect(sheet.valueOf('B1'), const ErrorValue(ErrorKind.divZero));
    });
  });
}
