import 'package:cellar/cellar.dart';
import 'package:test/test.dart';

double numberOf(CellValue value) => (value as NumberValue).value;

CellValue evalFormula(String formula) {
  final sheet = Sheet();
  sheet.setValue('Z100', formula);
  return sheet.valueOf('Z100');
}

void main() {
  group('arithmetic and precedence', () {
    test('multiplication binds tighter than addition', () {
      expect(numberOf(evalFormula('=1+2*3')), 7);
    });

    test('parentheses override precedence', () {
      expect(numberOf(evalFormula('=(1+2)*3')), 9);
    });

    test('exponent is right associative', () {
      expect(numberOf(evalFormula('=2^3^2')), 512);
    });

    test('unary minus binds looser than exponent', () {
      expect(numberOf(evalFormula('=-2^2')), -4);
    });

    test('division yields a fraction', () {
      expect(numberOf(evalFormula('=10/4')), 2.5);
    });

    test('percent operator is modulo', () {
      expect(numberOf(evalFormula('=10%3')), 1);
    });

    test('comparison has the lowest precedence', () {
      expect(evalFormula('=1+1=2'), const BooleanValue(true));
    });

    test('inequality returns a boolean', () {
      expect(evalFormula('=5>=5'), const BooleanValue(true));
      expect(evalFormula('=2<>2'), const BooleanValue(false));
    });

    test('string concatenation with ampersand', () {
      expect(evalFormula('="a"&"b"&"c"'), const TextValue('abc'));
    });
  });

  group('built-in functions', () {
    late Sheet sheet;

    setUp(() {
      sheet = Sheet();
      sheet.setValue('A1', '1');
      sheet.setValue('A2', '2');
      sheet.setValue('A3', '3');
    });

    test('SUM over a range', () {
      sheet.setValue('B1', '=SUM(A1:A3)');
      expect(numberOf(sheet.valueOf('B1')), 6);
    });

    test('SUM mixes range and scalar arguments', () {
      sheet.setValue('B1', '=SUM(A1:A3, 10, 4)');
      expect(numberOf(sheet.valueOf('B1')), 20);
    });

    test('AVERAGE and AVG alias', () {
      sheet.setValue('B1', '=AVERAGE(A1:A3)');
      sheet.setValue('B2', '=AVG(A1:A3)');
      expect(numberOf(sheet.valueOf('B1')), 2);
      expect(numberOf(sheet.valueOf('B2')), 2);
    });

    test('MIN and MAX', () {
      sheet.setValue('B1', '=MIN(A1:A3)');
      sheet.setValue('B2', '=MAX(A1:A3)');
      expect(numberOf(sheet.valueOf('B1')), 1);
      expect(numberOf(sheet.valueOf('B2')), 3);
    });

    test('COUNT counts only numbers while COUNTA counts non-blank', () {
      sheet.setValue('C1', '10');
      sheet.setValue('C2', 'hello');
      sheet.setValue('C4', 'TRUE');
      sheet.setValue('D1', '=COUNT(C1:C4)');
      sheet.setValue('D2', '=COUNTA(C1:C4)');
      expect(numberOf(sheet.valueOf('D1')), 1);
      expect(numberOf(sheet.valueOf('D2')), 3);
    });

    test('IF chooses a branch', () {
      sheet.setValue('B1', '=IF(A3>A1,"big","small")');
      expect(sheet.valueOf('B1'), const TextValue('big'));
    });

    test('nested functions', () {
      sheet.setValue('B1', '=IF(SUM(A1:A3)=6, MAX(A1:A3)*2, 0)');
      expect(numberOf(sheet.valueOf('B1')), 6);
    });

    test('math helpers', () {
      expect(numberOf(evalFormula('=ABS(-4.5)')), 4.5);
      expect(numberOf(evalFormula('=ROUND(3.14159, 2)')), 3.14);
      expect(numberOf(evalFormula('=FLOOR(7.8)')), 7);
      expect(numberOf(evalFormula('=CEIL(7.2)')), 8);
      expect(numberOf(evalFormula('=MOD(10, 3)')), 1);
      expect(numberOf(evalFormula('=POWER(2, 10)')), 1024);
      expect(numberOf(evalFormula('=SQRT(144)')), 12);
      expect(numberOf(evalFormula('=INT(9.99)')), 9);
    });

    test('text helpers', () {
      expect(evalFormula('=CONCAT("foo","bar")'), const TextValue('foobar'));
      expect(numberOf(evalFormula('=LEN("hello")')), 5);
      expect(evalFormula('=LEFT("spreadsheet", 6)'), const TextValue('spread'));
      expect(evalFormula('=RIGHT("spreadsheet", 5)'), const TextValue('sheet'));
      expect(evalFormula('=MID("spreadsheet", 7, 5)'), const TextValue('sheet'));
      expect(evalFormula('=UPPER("cellar")'), const TextValue('CELLAR'));
      expect(evalFormula('=LOWER("CELLAR")'), const TextValue('cellar'));
      expect(evalFormula('=TRIM("  a   b  ")'), const TextValue('a b'));
    });

    test('logical helpers', () {
      expect(evalFormula('=AND(TRUE, 1=1, 2>1)'), const BooleanValue(true));
      expect(evalFormula('=OR(FALSE, 1=2, 3>1)'), const BooleanValue(true));
      expect(evalFormula('=NOT(1=1)'), const BooleanValue(false));
    });

    test('INDEX into a range', () {
      sheet.setValue('B1', '=INDEX(A1:A3, 2)');
      expect(numberOf(sheet.valueOf('B1')), 2);
    });

    test('INDEX out of range returns #REF!', () {
      sheet.setValue('B1', '=INDEX(A1:A3, 9)');
      expect(sheet.valueOf('B1'), const ErrorValue(ErrorKind.ref));
    });

    test('IFERROR replaces an error', () {
      expect(numberOf(evalFormula('=IFERROR(1/0, 42)')), 42);
      expect(numberOf(evalFormula('=IFERROR(5, 42)')), 5);
    });

    test('ISERROR detects errors', () {
      expect(evalFormula('=ISERROR(1/0)'), const BooleanValue(true));
      expect(evalFormula('=ISERROR(1+1)'), const BooleanValue(false));
    });
  });

  group('errors', () {
    test('division by zero', () {
      expect(evalFormula('=1/0'), const ErrorValue(ErrorKind.divZero));
    });

    test('reference error literal propagates through arithmetic', () {
      expect(evalFormula('=#REF!'), const ErrorValue(ErrorKind.ref));
      expect(evalFormula('=#REF!+1'), const ErrorValue(ErrorKind.ref));
    });

    test('unknown function name', () {
      expect(evalFormula('=NOPE(1)'), const ErrorValue(ErrorKind.name));
    });

    test('bare unknown name', () {
      expect(evalFormula('=SOMENAME'), const ErrorValue(ErrorKind.name));
    });

    test('square root of a negative is #NUM!', () {
      expect(evalFormula('=SQRT(-1)'), const ErrorValue(ErrorKind.numError));
    });

    test('error propagates from a referenced cell', () {
      final sheet = Sheet();
      sheet.setValue('A1', '=1/0');
      sheet.setValue('B1', '=A1+5');
      expect(sheet.valueOf('B1'), const ErrorValue(ErrorKind.divZero));
    });
  });

  group('address helpers', () {
    test('column label round trips', () {
      expect(columnLabel(0), 'A');
      expect(columnLabel(25), 'Z');
      expect(columnLabel(26), 'AA');
      expect(columnLabel(27), 'AB');
      expect(columnLabel(701), 'ZZ');
      expect(columnLabel(702), 'AAA');
    });

    test('parse A1 style references', () {
      expect(CellAddress.parse('A1'), const CellAddress(0, 0));
      expect(CellAddress.parse('B2'), const CellAddress(1, 1));
      expect(CellAddress.parse('AA10').col, 26);
      expect(CellAddress.parse('AA10').row, 9);
    });
  });
}
