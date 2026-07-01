import 'money.dart';

class VatRate {
  final String label;
  final double rate;
  const VatRate(this.label, this.rate);

  static const standard = VatRate('23%', 0.23);
  static const reduced8 = VatRate('8%', 0.08);
  static const reduced5 = VatRate('5%', 0.05);
  static const zero = VatRate('0%', 0.0);
  static const exempt = VatRate('zw', 0.0);

  static VatRate fromPercent(num percent) => VatRate('$percent%', percent / 100);

  @override
  bool operator ==(Object other) => other is VatRate && other.label == label && other.rate == rate;

  @override
  int get hashCode => Object.hash(label, rate);
}

class Party {
  final String name;
  final String? address;
  final String? taxId;
  final String? email;

  const Party({required this.name, this.address, this.taxId, this.email});
}

class InvoiceLine {
  final String description;
  final num quantity;
  final Money unitPrice;
  final double discountRate;
  final VatRate vat;
  final String unit;

  const InvoiceLine({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.vat,
    this.discountRate = 0.0,
    this.unit = 'pcs',
  });

  Money get grossBeforeDiscount => unitPrice.scaled(quantity);

  Money get discountAmount => grossBeforeDiscount.scaled(discountRate);

  Money get net => grossBeforeDiscount - discountAmount;

  Money get vatAmount => net.scaled(vat.rate);

  Money get total => net + vatAmount;
}

class VatSummaryRow {
  final VatRate rate;
  final Money net;
  final Money vat;

  const VatSummaryRow(this.rate, this.net, this.vat);

  Money get gross => net + vat;
}

class Invoice {
  final String number;
  final DateTime issueDate;
  final DateTime? dueDate;
  final Party seller;
  final Party buyer;
  final Currency currency;
  final List<InvoiceLine> lines;
  final String? notes;
  final String? paymentTerms;
  final Currency? reportingCurrency;
  final double? reportingRate;

  const Invoice({
    required this.number,
    required this.issueDate,
    required this.seller,
    required this.buyer,
    required this.currency,
    required this.lines,
    this.dueDate,
    this.notes,
    this.paymentTerms,
    this.reportingCurrency,
    this.reportingRate,
  });

  List<VatSummaryRow> vatSummary() {
    final order = <String>[];
    final rates = <String, VatRate>{};
    final nets = <String, Money>{};
    for (final line in lines) {
      final key = line.vat.label;
      if (!nets.containsKey(key)) {
        order.add(key);
        rates[key] = line.vat;
        nets[key] = Money.zero(currency);
      }
      nets[key] = nets[key]! + line.net;
    }
    return [
      for (final key in order)
        VatSummaryRow(rates[key]!, nets[key]!, nets[key]!.scaled(rates[key]!.rate)),
    ];
  }

  Money get totalNet {
    var sum = Money.zero(currency);
    for (final row in vatSummary()) {
      sum += row.net;
    }
    return sum;
  }

  Money get totalVat {
    var sum = Money.zero(currency);
    for (final row in vatSummary()) {
      sum += row.vat;
    }
    return sum;
  }

  Money get totalGross => totalNet + totalVat;

  Money? get reportingTotalGross {
    final target = reportingCurrency;
    final rate = reportingRate;
    if (target == null || rate == null) return null;
    return totalGross.convertedTo(target, rate);
  }

  Money? get reportingTotalVat {
    final target = reportingCurrency;
    final rate = reportingRate;
    if (target == null || rate == null) return null;
    return totalVat.convertedTo(target, rate);
  }
}

class InvoiceSequence {
  final String pattern;
  int counter;

  InvoiceSequence(this.pattern, {this.counter = 1});

  String format(DateTime date, int seq) {
    return pattern.replaceAllMapped(RegExp(r'\{(\w+)(?::(\d+))?\}'), (match) {
      final field = match.group(1)!;
      final width = match.group(2) == null ? 0 : int.parse(match.group(2)!);
      final value = switch (field) {
        'seq' => seq,
        'year' => date.year,
        'month' => date.month,
        'day' => date.day,
        _ => throw ArgumentError('Unknown numbering field: $field'),
      };
      return value.toString().padLeft(width, '0');
    });
  }

  String next(DateTime date) {
    final formatted = format(date, counter);
    counter++;
    return formatted;
  }
}
