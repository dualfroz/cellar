import 'package:cellar/cellar.dart';
import 'package:test/test.dart';

double num(CellValue value) => (value as NumberValue).value;

Sheet withGrid() {
  final sheet = Sheet();
  final rows = [
    ['North', 'A', '100'],
    ['South', 'A', '150'],
    ['North', 'B', '200'],
    ['South', 'B', '50'],
    ['North', 'A', '75'],
  ];
  for (var r = 0; r < rows.length; r++) {
    sheet.setValue('A${r + 1}', rows[r][0]);
    sheet.setValue('B${r + 1}', rows[r][1]);
    sheet.setValue('C${r + 1}', rows[r][2]);
  }
  return sheet;
}

void main() {
  group('aggregate functions', () {
    test('SUM SUMSQ PRODUCT MIN MAX', () {
      final sheet = Sheet();
      sheet.setValue('A1', '2');
      sheet.setValue('A2', '3');
      sheet.setValue('A3', '4');
      sheet.setValue('B1', '=SUM(A1:A3)');
      sheet.setValue('B2', '=SUMSQ(A1:A3)');
      sheet.setValue('B3', '=PRODUCT(A1:A3)');
      sheet.setValue('B4', '=MIN(A1:A3)');
      sheet.setValue('B5', '=MAX(A1:A3)');
      expect(num(sheet.valueOf('B1')), 9);
      expect(num(sheet.valueOf('B2')), 29);
      expect(num(sheet.valueOf('B3')), 24);
      expect(num(sheet.valueOf('B4')), 2);
      expect(num(sheet.valueOf('B5')), 4);
    });

    test('SUMPRODUCT multiplies element wise', () {
      final sheet = Sheet();
      sheet.setValue('A1', '1');
      sheet.setValue('A2', '2');
      sheet.setValue('A3', '3');
      sheet.setValue('B1', '4');
      sheet.setValue('B2', '5');
      sheet.setValue('B3', '6');
      sheet.setValue('C1', '=SUMPRODUCT(A1:A3, B1:B3)');
      expect(num(sheet.valueOf('C1')), 32);
    });

    test('SUMIF with a comparison criterion and a separate sum range', () {
      final sheet = withGrid();
      sheet.setValue('E1', '=SUMIF(C1:C5, ">100")');
      sheet.setValue('E2', '=SUMIF(A1:A5, "North", C1:C5)');
      expect(num(sheet.valueOf('E1')), 350);
      expect(num(sheet.valueOf('E2')), 375);
    });

    test('COUNTIF and AVERAGEIF', () {
      final sheet = withGrid();
      sheet.setValue('E1', '=COUNTIF(A1:A5, "North")');
      sheet.setValue('E2', '=AVERAGEIF(A1:A5, "South", C1:C5)');
      expect(num(sheet.valueOf('E1')), 3);
      expect(num(sheet.valueOf('E2')), 100);
    });

    test('COUNTIF with a wildcard', () {
      final sheet = Sheet();
      sheet.setValue('A1', 'apple');
      sheet.setValue('A2', 'apricot');
      sheet.setValue('A3', 'banana');
      sheet.setValue('B1', '=COUNTIF(A1:A3, "ap*")');
      expect(num(sheet.valueOf('B1')), 2);
    });

    test('SUMIFS AVERAGEIFS COUNTIFS with two conditions', () {
      final sheet = withGrid();
      sheet.setValue('E1', '=SUMIFS(C1:C5, A1:A5, "North", B1:B5, "A")');
      sheet.setValue('E2', '=COUNTIFS(A1:A5, "North", B1:B5, "A")');
      sheet.setValue('E3', '=AVERAGEIFS(C1:C5, A1:A5, "North", B1:B5, "A")');
      expect(num(sheet.valueOf('E1')), 175);
      expect(num(sheet.valueOf('E2')), 2);
      expect(num(sheet.valueOf('E3')), 87.5);
    });

    test('MAXIFS and MINIFS', () {
      final sheet = withGrid();
      sheet.setValue('E1', '=MAXIFS(C1:C5, A1:A5, "North")');
      sheet.setValue('E2', '=MINIFS(C1:C5, A1:A5, "North")');
      expect(num(sheet.valueOf('E1')), 200);
      expect(num(sheet.valueOf('E2')), 75);
    });
  });
}
