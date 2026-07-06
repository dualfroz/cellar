import 'package:cellar/cellar.dart';
import 'package:test/test.dart';

double num(CellValue value) => (value as NumberValue).value;

void main() {
  group('workbook JSON store', () {
    test('round trips values, formulas, formats and names', () {
      final workbook = Workbook();
      final sheet1 = workbook.addSheet('Sheet1');
      final data = workbook.addSheet('Data');
      sheet1.setValue('A1', '10');
      sheet1.setValue('A2', '20');
      sheet1.setValue('A3', '=SUM(A1:A2)');
      sheet1.setFormat('A3', const NumberFormat.currency('zl', before: false, thousands: false));
      data.setValue('B1', '=Sheet1!A3 * 2');
      workbook.defineName('Total', 'Sheet1!A3');

      final encoded = encodeWorkbookJson(workbook);
      final reloaded = decodeWorkbookJson(encoded);

      expect(reloaded.sheetNames, ['Sheet1', 'Data']);
      expect(num(reloaded.sheet('Sheet1').valueOf('A3')), 30);
      expect(reloaded.sheet('Sheet1').displayAt(CellAddress.parse('A3')), '30.00zl');
      expect(num(reloaded.sheet('Data').valueOf('B1')), 60);
      expect(reloaded.resolveName('Total'), isNotNull);
    });

    test('reloaded workbook recomputes after an edit', () {
      final workbook = Workbook();
      final sheet1 = workbook.addSheet('Sheet1');
      final data = workbook.addSheet('Data');
      sheet1.setValue('A1', '5');
      data.setValue('B1', '=Sheet1!A1 + 100');

      final reloaded = decodeWorkbookJson(encodeWorkbookJson(workbook));
      expect(num(reloaded.sheet('Data').valueOf('B1')), 105);
      reloaded.sheet('Sheet1').setValue('A1', '7');
      expect(num(reloaded.sheet('Data').valueOf('B1')), 107);
    });
  });
}
