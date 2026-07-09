import 'package:cellar/cellar.dart';
import 'package:test/test.dart';

CellValue ev(String formula) {
  final sheet = Sheet();
  sheet.setValue('Z1', formula);
  return sheet.valueOf('Z1');
}

double num(CellValue value) => (value as NumberValue).value;

void main() {
  group('logical functions', () {
    test('IF chooses a branch', () {
      expect(ev('=IF(2>1, "yes", "no")'), const TextValue('yes'));
      expect(ev('=IF(2<1, "yes", "no")'), const TextValue('no'));
    });

    test('IFS picks the first true condition', () {
      expect(ev('=IFS(FALSE, 1, TRUE, 2, TRUE, 3)'), const NumberValue(2));
      expect(ev('=IFS(FALSE, 1, FALSE, 2)'), const ErrorValue(ErrorKind.na));
    });

    test('SWITCH matches a value with a default', () {
      expect(ev('=SWITCH(2, 1, "a", 2, "b", "z")'), const TextValue('b'));
      expect(ev('=SWITCH(9, 1, "a", 2, "b", "z")'), const TextValue('z'));
      expect(ev('=SWITCH(9, 1, "a")'), const ErrorValue(ErrorKind.na));
    });

    test('AND OR NOT XOR', () {
      expect(ev('=AND(TRUE, 1=1, 2>1)'), const BooleanValue(true));
      expect(ev('=OR(FALSE, 1=2, 3>1)'), const BooleanValue(true));
      expect(ev('=NOT(1=1)'), const BooleanValue(false));
      expect(ev('=XOR(TRUE, TRUE, TRUE)'), const BooleanValue(true));
      expect(ev('=XOR(TRUE, TRUE)'), const BooleanValue(false));
    });

    test('IFERROR and IFNA', () {
      expect(num(ev('=IFERROR(1/0, 42)')), 42);
      expect(num(ev('=IFERROR(5, 42)')), 5);
      expect(num(ev('=IFNA(NA(), 7)')), 7);
      expect(ev('=IFNA(1/0, 7)'), const ErrorValue(ErrorKind.divZero));
    });
  });

  group('info functions', () {
    test('type predicates', () {
      expect(ev('=ISNUMBER(5)'), const BooleanValue(true));
      expect(ev('=ISTEXT("x")'), const BooleanValue(true));
      expect(ev('=ISLOGICAL(TRUE)'), const BooleanValue(true));
      expect(ev('=ISNUMBER("x")'), const BooleanValue(false));
    });

    test('error predicates', () {
      expect(ev('=ISERROR(1/0)'), const BooleanValue(true));
      expect(ev('=ISERR(1/0)'), const BooleanValue(true));
      expect(ev('=ISERR(NA())'), const BooleanValue(false));
      expect(ev('=ISNA(NA())'), const BooleanValue(true));
      expect(ev('=ISNA(1/0)'), const BooleanValue(false));
    });

    test('ISBLANK reflects an empty cell', () {
      final sheet = Sheet();
      sheet.setValue('B1', '=ISBLANK(A1)');
      sheet.setValue('B2', '=ISBLANK(A2)');
      sheet.setValue('A2', 'x');
      expect(sheet.valueOf('B1'), const BooleanValue(true));
      expect(sheet.valueOf('B2'), const BooleanValue(false));
    });

    test('N and TYPE', () {
      expect(num(ev('=N(TRUE)')), 1);
      expect(num(ev('=N("text")')), 0);
      expect(num(ev('=TYPE(5)')), 1);
      expect(num(ev('=TYPE("x")')), 2);
      expect(num(ev('=TYPE(1/0)')), 16);
    });
  });
}
