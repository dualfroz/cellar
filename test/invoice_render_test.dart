import 'package:cellar/cellar.dart';
import 'package:test/test.dart';

bool isAscii(String text) => text.runes.every((rune) => rune < 128);

Invoice invoice() => Invoice(
      number: 'FV/2026/07/001',
      issueDate: DateTime(2026, 8, 28),
      dueDate: DateTime(2026, 9, 11),
      seller: const Party(name: 'Example Software Sp. z o.o.', address: 'Warszawa', taxId: 'PL1234567890'),
      buyer: const Party(name: 'Acme <Corp>', address: 'Krakow'),
      currency: Currency.pln,
      paymentTerms: '14 days',
      lines: [
        InvoiceLine(
          description: 'Consulting',
          quantity: 12,
          unitPrice: Money.of(150, Currency.pln),
          vat: VatRate.standard,
        ),
        InvoiceLine(
          description: 'Manual',
          quantity: 3,
          unitPrice: Money.of(20, Currency.pln),
          vat: VatRate.reduced5,
        ),
      ],
    );

void main() {
  group('invoice text render', () {
    test('shows the totals and stays ASCII', () {
      final text = renderInvoiceText(invoice());
      expect(text.contains('INVOICE FV/2026/07/001'), isTrue);
      expect(text.contains('Subtotal (net): 1 860.00 zl'), isTrue);
      expect(text.contains('VAT total:      417.00 zl'), isTrue);
      expect(text.contains('TOTAL:          2 277.00 zl'), isTrue);
      expect(isAscii(text), isTrue);
    });
  });

  group('invoice HTML render', () {
    test('is a full ASCII document with the total', () {
      final html = renderInvoiceHtml(invoice());
      expect(html.contains('<!DOCTYPE html>'), isTrue);
      expect(html.contains('</html>'), isTrue);
      expect(html.contains('2 277.00 zl'), isTrue);
      expect(html.contains('Acme &lt;Corp&gt;'), isTrue);
      expect(isAscii(html), isTrue);
    });
  });
}
