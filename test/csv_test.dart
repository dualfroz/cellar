import 'package:cellar/cellar.dart';
import 'package:test/test.dart';

double numberOf(CellValue value) => (value as NumberValue).value;

void main() {
  group('csv parsing', () {
    test('parses quoted fields with embedded commas and quotes', () {
      final rows = parseCsv('a,"b,c","he said ""hi"""\n1,2,3');
      expect(rows, [
        ['a', 'b,c', 'he said "hi"'],
        ['1', '2', '3'],
      ]);
    });

    test('a trailing newline does not create an empty record', () {
      final rows = parseCsv('a,b\nc,d\n');
      expect(rows.length, 2);
    });
  });

  group('csv import and compute', () {
    test('imports literals and formulas then computes', () {
      final sheet = Sheet();
      importCsv(sheet, 'Name,Qty,Price,Total\nApple,3,2,=B2*C2\nPear,4,5,=B3*C3\n,,,=SUM(D2:D3)');
      expect(numberOf(sheet.valueOf('D2')), 6);
      expect(numberOf(sheet.valueOf('D3')), 20);
      expect(numberOf(sheet.valueOf('D4')), 26);
    });
  });

  group('csv round trip', () {
    test('formulas survive export and re-import with equal results', () {
      final original = Sheet();
      original.setValue('A1', '10');
      original.setValue('A2', '20');
      original.setValue('A3', '30');
      original.setValue('B1', '=SUM(A1:A3)');
      original.setValue('B2', '=AVERAGE(A1:A3)');
      original.setValue('B3', '=IF(B1>50, "high", "low")');

      final formulaCsv = exportFormulas(original);
      final reloaded = Sheet();
      importCsv(reloaded, formulaCsv);

      expect(exportFormulas(reloaded), formulaCsv);
      expect(numberOf(reloaded.valueOf('B1')), 60);
      expect(numberOf(reloaded.valueOf('B2')), 20);
      expect(reloaded.valueOf('B3'), const TextValue('high'));
    });

    test('value export renders computed numbers', () {
      final sheet = Sheet();
      sheet.setValue('A1', '4');
      sheet.setValue('B1', '=A1*A1');
      final valueCsv = exportValues(sheet);
      expect(valueCsv, '4,16');
    });
  });
}
