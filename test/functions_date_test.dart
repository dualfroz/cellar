import 'package:cellar/cellar.dart';
import 'package:test/test.dart';

CellValue ev(String formula) {
  final sheet = Sheet();
  sheet.setValue('Z1', formula);
  return sheet.valueOf('Z1');
}

double num(CellValue value) => (value as NumberValue).value;

void main() {
  group('date functions', () {
    test('DATE produces the Excel serial number', () {
      expect(num(ev('=DATE(2024, 1, 1)')), 45292);
      expect(num(ev('=DATE(1899, 12, 31)')), 1);
    });

    test('YEAR MONTH DAY decompose a serial', () {
      expect(num(ev('=YEAR(DATE(2024, 3, 15))')), 2024);
      expect(num(ev('=MONTH(DATE(2024, 3, 15))')), 3);
      expect(num(ev('=DAY(DATE(2024, 3, 15))')), 15);
    });

    test('DATEDIF across units', () {
      expect(num(ev('=DATEDIF(DATE(2020,1,1), DATE(2024,3,15), "Y")')), 4);
      expect(num(ev('=DATEDIF(DATE(2020,1,1), DATE(2024,3,15), "M")')), 50);
      expect(num(ev('=DATEDIF(DATE(2020,1,1), DATE(2024,3,15), "YM")')), 2);
      expect(num(ev('=DATEDIF(DATE(2024,1,1), DATE(2024,1,11), "D")')), 10);
    });

    test('EDATE and EOMONTH honour month lengths', () {
      expect(num(ev('=DAY(EDATE(DATE(2024,1,31), 1))')), 29);
      expect(num(ev('=DAY(EOMONTH(DATE(2024,2,10), 0))')), 29);
      expect(num(ev('=MONTH(EOMONTH(DATE(2024,1,15), 2))')), 3);
    });

    test('WEEKDAY and DAYS', () {
      expect(num(ev('=WEEKDAY(DATE(2024,1,7))')), 1);
      expect(num(ev('=WEEKDAY(DATE(2024,1,8), 2)')), 1);
      expect(num(ev('=DAYS(DATE(2024,1,10), DATE(2024,1,1))')), 9);
    });

    test('TODAY agrees with the system year', () {
      final year = DateTime.now().year;
      expect(num(ev('=YEAR(TODAY())')), year.toDouble());
    });
  });
}
