import 'package:cellar/cellar.dart';
import 'package:test/test.dart';

CellValue ev(String formula) {
  final sheet = Sheet();
  sheet.setValue('Z1', formula);
  return sheet.valueOf('Z1');
}

double num(CellValue value) => (value as NumberValue).value;

void main() {
  group('text functions', () {
    test('slicing', () {
      expect(ev('=LEFT("spreadsheet", 6)'), const TextValue('spread'));
      expect(ev('=RIGHT("spreadsheet", 5)'), const TextValue('sheet'));
      expect(ev('=MID("spreadsheet", 7, 5)'), const TextValue('sheet'));
      expect(num(ev('=LEN("hello")')), 5);
    });

    test('case and proper', () {
      expect(ev('=UPPER("cellar")'), const TextValue('CELLAR'));
      expect(ev('=LOWER("CELLAR")'), const TextValue('cellar'));
      expect(ev('=PROPER("john the FIRST")'), const TextValue('John The First'));
      expect(ev('=TRIM("  a   b  ")'), const TextValue('a b'));
    });

    test('concat and textjoin', () {
      expect(ev('=CONCAT("foo", "bar")'), const TextValue('foobar'));
      expect(ev('=TEXTJOIN("-", TRUE, "a", "", "b")'), const TextValue('a-b'));
      expect(ev('=TEXTJOIN("-", FALSE, "a", "", "b")'), const TextValue('a--b'));
    });

    test('substitute and replace', () {
      expect(ev('=SUBSTITUTE("a-b-c", "-", "+")'), const TextValue('a+b+c'));
      expect(ev('=SUBSTITUTE("a-b-c", "-", "+", 2)'), const TextValue('a-b+c'));
      expect(ev('=REPLACE("abcdef", 2, 3, "XY")'), const TextValue('aXYef'));
    });

    test('find and search', () {
      expect(num(ev('=FIND("c", "abcabc")')), 3);
      expect(num(ev('=SEARCH("C", "abcabc")')), 3);
      expect(ev('=FIND("z", "abc")'), const ErrorValue(ErrorKind.value));
    });

    test('char and code', () {
      expect(ev('=CHAR(65)'), const TextValue('A'));
      expect(num(ev('=CODE("A")')), 65);
    });

    test('value and numbervalue', () {
      expect(num(ev('=VALUE("42.5")')), 42.5);
      expect(num(ev('=NUMBERVALUE("1.234,50", ",", ".")')), 1234.5);
    });

    test('TEXT formats a number', () {
      expect(ev('=TEXT(1234.5, "#,##0.00")'), const TextValue('1,234.50'));
      expect(ev('=TEXT(0.25, "0.0%")'), const TextValue('25.0%'));
    });

    test('regex helpers', () {
      expect(ev('=REGEXMATCH("abc123", "[0-9]+")'), const BooleanValue(true));
      expect(ev('=REGEXEXTRACT("order 42 done", "([0-9]+)")'), const TextValue('42'));
      expect(ev('=REGEXREPLACE("a1b2c3", "[0-9]", "#")'), const TextValue('a#b#c#'));
    });

    test('REPT and EXACT', () {
      expect(ev('=REPT("ab", 3)'), const TextValue('ababab'));
      expect(ev('=EXACT("Abc", "abc")'), const BooleanValue(false));
    });
  });
}
