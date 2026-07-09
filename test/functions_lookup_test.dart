import 'package:cellar/cellar.dart';
import 'package:test/test.dart';

double num(CellValue value) => (value as NumberValue).value;

Sheet lookupSheet() {
  final sheet = Sheet();
  final rows = [
    ['apple', '1', 'red'],
    ['banana', '2', 'yellow'],
    ['cherry', '3', 'red'],
  ];
  for (var r = 0; r < rows.length; r++) {
    sheet.setValue('A${r + 1}', rows[r][0]);
    sheet.setValue('B${r + 1}', rows[r][1]);
    sheet.setValue('C${r + 1}', rows[r][2]);
  }
  return sheet;
}

void main() {
  group('lookup functions', () {
    test('VLOOKUP exact match returns another column', () {
      final sheet = lookupSheet();
      sheet.setValue('E1', '=VLOOKUP("banana", A1:C3, 3, FALSE)');
      expect(sheet.valueOf('E1'), const TextValue('yellow'));
    });

    test('VLOOKUP approximate on sorted numbers', () {
      final sheet = Sheet();
      sheet.setValue('A1', '0');
      sheet.setValue('B1', 'low');
      sheet.setValue('A2', '10');
      sheet.setValue('B2', 'mid');
      sheet.setValue('A3', '20');
      sheet.setValue('B3', 'high');
      sheet.setValue('D1', '=VLOOKUP(15, A1:B3, 2)');
      expect(sheet.valueOf('D1'), const TextValue('mid'));
    });

    test('VLOOKUP missing exact key is #N/A', () {
      final sheet = lookupSheet();
      sheet.setValue('E1', '=VLOOKUP("mango", A1:C3, 2, FALSE)');
      expect(sheet.valueOf('E1'), const ErrorValue(ErrorKind.na));
    });

    test('HLOOKUP across a row', () {
      final sheet = Sheet();
      sheet.setValue('A1', 'Q1');
      sheet.setValue('B1', 'Q2');
      sheet.setValue('C1', 'Q3');
      sheet.setValue('A2', '10');
      sheet.setValue('B2', '20');
      sheet.setValue('C2', '30');
      sheet.setValue('E1', '=HLOOKUP("Q2", A1:C2, 2, FALSE)');
      expect(num(sheet.valueOf('E1')), 20);
    });

    test('MATCH exact and approximate', () {
      final sheet = lookupSheet();
      sheet.setValue('E1', '=MATCH("cherry", A1:A3, 0)');
      expect(num(sheet.valueOf('E1')), 3);
      final numbers = Sheet();
      numbers.setValue('A1', '10');
      numbers.setValue('A2', '20');
      numbers.setValue('A3', '30');
      numbers.setValue('B1', '=MATCH(25, A1:A3, 1)');
      expect(num(numbers.valueOf('B1')), 2);
    });

    test('INDEX and INDEX/MATCH', () {
      final sheet = lookupSheet();
      sheet.setValue('E1', '=INDEX(A1:C3, 2, 3)');
      sheet.setValue('E2', '=INDEX(B1:B3, MATCH("cherry", A1:A3, 0))');
      expect(sheet.valueOf('E1'), const TextValue('yellow'));
      expect(num(sheet.valueOf('E2')), 3);
    });

    test('CHOOSE ROWS COLUMNS ROW COLUMN', () {
      final sheet = lookupSheet();
      sheet.setValue('E1', '=CHOOSE(2, "a", "b", "c")');
      sheet.setValue('E2', '=ROWS(A1:C3)');
      sheet.setValue('E3', '=COLUMNS(A1:C3)');
      sheet.setValue('E4', '=ROW(B5)');
      sheet.setValue('E5', '=COLUMN(D2)');
      expect(sheet.valueOf('E1'), const TextValue('b'));
      expect(num(sheet.valueOf('E2')), 3);
      expect(num(sheet.valueOf('E3')), 3);
      expect(num(sheet.valueOf('E4')), 5);
      expect(num(sheet.valueOf('E5')), 4);
    });
  });
}
