import 'package:cellar/cellar.dart';
import 'package:test/test.dart';

double numberOf(CellValue value) => (value as NumberValue).value;

void main() {
  group('multi-sheet workbook', () {
    test('a workbook holds several named sheets', () {
      final workbook = Workbook();
      workbook.addSheet('Sheet1');
      workbook.addSheet('Data');
      expect(workbook.sheetCount, 2);
      expect(workbook.sheetNames, ['Sheet1', 'Data']);
    });

    test('cross sheet reference resolves the other sheet', () {
      final workbook = Workbook();
      final first = workbook.addSheet('Sheet1');
      final data = workbook.addSheet('Data');
      first.setValue('A1', '10');
      first.setValue('A2', '20');
      data.setValue('B1', '=Sheet1!A1 + Sheet1!A2');
      expect(numberOf(data.valueOf('B1')), 30);
    });

    test('cross sheet range aggregation', () {
      final workbook = Workbook();
      final first = workbook.addSheet('Sheet1');
      final data = workbook.addSheet('Data');
      first.setValue('A1', '1');
      first.setValue('A2', '2');
      first.setValue('A3', '3');
      data.setValue('B1', '=SUM(Sheet1!A1:A3) * 2');
      expect(numberOf(data.valueOf('B1')), 12);
    });

    test('editing a precedent recomputes a dependent on another sheet', () {
      final workbook = Workbook();
      final first = workbook.addSheet('Sheet1');
      final data = workbook.addSheet('Data');
      first.setValue('A1', '5');
      data.setValue('B1', '=Sheet1!A1 * 3');
      expect(numberOf(data.valueOf('B1')), 15);
      first.setValue('A1', '9');
      expect(numberOf(data.valueOf('B1')), 27);
    });

    test('quoted sheet names with spaces', () {
      final workbook = Workbook();
      final first = workbook.addSheet('My Sheet');
      final data = workbook.addSheet('Data');
      first.setValue('A1', '42');
      data.setValue('B1', "='My Sheet'!A1 + 1");
      expect(numberOf(data.valueOf('B1')), 43);
    });

    test('reference to an unknown sheet is #REF!', () {
      final workbook = Workbook();
      final data = workbook.addSheet('Data');
      data.setValue('A1', '=Missing!A1');
      expect(data.valueOf('A1'), const ErrorValue(ErrorKind.ref));
    });

    test('a cycle spanning two sheets is detected', () {
      final workbook = Workbook();
      final first = workbook.addSheet('Sheet1');
      final data = workbook.addSheet('Data');
      first.setValue('A1', '=Data!A1');
      data.setValue('A1', '=Sheet1!A1');
      expect(first.valueOf('A1'), const ErrorValue(ErrorKind.cycle));
      expect(data.valueOf('A1'), const ErrorValue(ErrorKind.cycle));
    });
  });

  group('named ranges', () {
    test('a named cell resolves to its value', () {
      final workbook = Workbook();
      final sheet = workbook.addSheet('Sheet1');
      sheet.setValue('B2', '99');
      workbook.defineName('Answer', 'Sheet1!B2');
      sheet.setValue('C1', '=Answer + 1');
      expect(numberOf(sheet.valueOf('C1')), 100);
    });

    test('a named range works inside an aggregate', () {
      final workbook = Workbook();
      final sheet = workbook.addSheet('Sheet1');
      sheet.setValue('A1', '10');
      sheet.setValue('A2', '20');
      sheet.setValue('A3', '30');
      workbook.defineName('Inputs', 'Sheet1!A1:A3');
      sheet.setValue('B1', '=SUM(Inputs)');
      expect(numberOf(sheet.valueOf('B1')), 60);
    });

    test('a named range defined after the formula still propagates', () {
      final workbook = Workbook();
      final sheet = workbook.addSheet('Sheet1');
      sheet.setValue('A1', '5');
      sheet.setValue('A2', '7');
      sheet.setValue('B1', '=SUM(Prices)');
      expect(sheet.valueOf('B1'), const ErrorValue(ErrorKind.name));
      workbook.defineName('Prices', 'Sheet1!A1:A2');
      expect(numberOf(sheet.valueOf('B1')), 12);
      sheet.setValue('A1', '50');
      expect(numberOf(sheet.valueOf('B1')), 57);
    });

    test('an unknown bare name is #NAME?', () {
      final workbook = Workbook();
      final sheet = workbook.addSheet('Sheet1');
      sheet.setValue('A1', '=Nope + 1');
      expect(sheet.valueOf('A1'), const ErrorValue(ErrorKind.name));
    });
  });
}
