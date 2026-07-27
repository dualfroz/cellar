import 'package:cellar/cellar.dart';
import 'package:test/test.dart';

Invoice sampleInvoice() => Invoice(
      number: 'FV/2026/001',
      issueDate: DateTime(2026, 8, 28),
      dueDate: DateTime(2026, 9, 11),
      seller: const Party(name: 'Vulp Sp. z o.o.', taxId: 'PL1234567890'),
      buyer: const Party(name: 'Acme Corp', taxId: 'PL9876543210'),
      currency: Currency.pln,
      lines: [
        InvoiceLine(
          description: 'Consulting',
          quantity: 10,
          unitPrice: Money.of(100, Currency.pln),
          vat: VatRate.standard,
        ),
        InvoiceLine(
          description: 'License',
          quantity: 2,
          unitPrice: Money.of(500, Currency.pln),
          vat: VatRate.standard,
          discountRate: 0.1,
        ),
        InvoiceLine(
          description: 'Books',
          quantity: 4,
          unitPrice: Money.of(25, Currency.pln),
          vat: VatRate.reduced5,
        ),
      ],
    );

void main() {
  group('invoice line computations', () {
    test('discount reduces the net amount', () {
      final line = InvoiceLine(
        description: 'License',
        quantity: 2,
        unitPrice: Money.of(500, Currency.pln),
        vat: VatRate.standard,
        discountRate: 0.1,
      );
      expect(line.grossBeforeDiscount, Money.of(1000, Currency.pln));
      expect(line.discountAmount, Money.of(100, Currency.pln));
      expect(line.net, Money.of(900, Currency.pln));
      expect(line.vatAmount, Money.of(207, Currency.pln));
    });
  });

  group('invoice totals', () {
    test('VAT summary groups by rate', () {
      final summary = sampleInvoice().vatSummary();
      expect(summary.length, 2);
      expect(summary[0].rate, VatRate.standard);
      expect(summary[0].net, Money.of(1900, Currency.pln));
      expect(summary[0].vat, Money.of(437, Currency.pln));
      expect(summary[1].rate, VatRate.reduced5);
      expect(summary[1].net, Money.of(100, Currency.pln));
      expect(summary[1].vat, Money.of(5, Currency.pln));
    });

    test('totals sum the summary', () {
      final invoice = sampleInvoice();
      expect(invoice.totalNet, Money.of(2000, Currency.pln));
      expect(invoice.totalVat, Money.of(442, Currency.pln));
      expect(invoice.totalGross, Money.of(2442, Currency.pln));
    });
  });

  group('invoice numbering', () {
    test('sequence pads and advances', () {
      final sequence = InvoiceSequence('FV/{seq:04}/{year}');
      expect(sequence.next(DateTime(2026, 3, 1)), 'FV/0001/2026');
      expect(sequence.next(DateTime(2026, 3, 1)), 'FV/0002/2026');
    });

    test('month and day placeholders', () {
      final sequence = InvoiceSequence('{year}/{month:02}/{seq:03}');
      expect(sequence.format(DateTime(2026, 3, 5), 7), '2026/03/007');
    });
  });

  group('invoice JSON', () {
    test('round trips through JSON', () {
      final original = sampleInvoice();
      final decoded = invoiceFromJsonString(encodeInvoiceJson(original));
      expect(decoded.totalNet, original.totalNet);
      expect(decoded.totalVat, original.totalVat);
      expect(decoded.totalGross, original.totalGross);
      expect(decoded.lines.length, 3);
      expect(decoded.number, original.number);
    });

    test('multicurrency reporting equivalent', () {
      final invoice = Invoice(
        number: 'FV/EU/1',
        issueDate: DateTime(2026, 8, 28),
        seller: const Party(name: 'Seller'),
        buyer: const Party(name: 'Buyer'),
        currency: Currency.eur,
        reportingCurrency: Currency.pln,
        reportingRate: 4.32,
        lines: [
          InvoiceLine(
            description: 'Service',
            quantity: 1,
            unitPrice: Money.of(1000, Currency.eur),
            vat: VatRate.standard,
          ),
        ],
      );
      expect(invoice.totalGross, Money.of(1230, Currency.eur));
      expect(invoice.reportingTotalGross, Money.of(5313.6, Currency.pln));
    });
  });
}
