import 'package:cellar/cellar.dart';

void main() {
  final sheet = Sheet();
  sheet.setValue('A1', '10');
  sheet.setValue('A2', '20');
  sheet.setValue('B1', '=SUM(A1:A2)');
  print(sheet.valueOf('B1').display());

  sheet.setValue('A2', '32');
  print(sheet.valueOf('B1').display());

  sheet.setValue('C1', '=C2+1');
  sheet.setValue('C2', '=C1+1');
  print(sheet.valueOf('C1').display());

  final workbook = Workbook();
  final prices = workbook.addSheet('Prices');
  final orders = workbook.addSheet('Orders');
  prices.setValue('A1', 'apple');
  prices.setValue('B1', '1.20');
  prices.setValue('A2', 'pear');
  prices.setValue('B2', '1.75');
  workbook.defineName('PriceList', 'Prices!A1:B2');
  orders.setValue('A1', 'pear');
  orders.setValue('B1', '4');
  orders.setValue('C1', '=VLOOKUP(A1,PriceList,2,FALSE)*B1');
  orders.setFormat('C1', const NumberFormat.currency(r'$'));
  print(orders.displayAt(CellAddress.parse('C1')));

  final sales = Sheet('Sales');
  importCsv(sales, 'Region,Product,Units\nNorth,Tea,5\nSouth,Tea,3\nNorth,Coffee,7\n');
  final pivot = DataTable.fromSheet(sales).pivot(
    rowKey: 'Region',
    columnKey: 'Product',
    valueColumn: 'Units',
  );
  print(renderTextRows(pivot.toRows()));

  final invoice = Invoice(
    number: InvoiceSequence('INV/{year}/{seq:4}').next(DateTime(2026, 3, 1)),
    issueDate: DateTime(2026, 3, 1),
    seller: const Party(name: 'Example Seller'),
    buyer: const Party(name: 'Example Buyer'),
    currency: Currency.eur,
    lines: [
      InvoiceLine(
        description: 'Support plan',
        quantity: 3,
        unitPrice: Money.of(99.90, Currency.eur),
        vat: VatRate.standard,
      ),
    ],
  );
  print('${invoice.number}: ${invoice.totalGross.format()}');
}
