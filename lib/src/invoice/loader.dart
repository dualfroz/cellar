import 'dart:convert';

import 'invoice.dart';
import 'money.dart';

Invoice invoiceFromJsonString(String source) =>
    invoiceFromJson(jsonDecode(source) as Map<String, dynamic>);

Invoice invoiceFromJson(Map<String, dynamic> json) {
  final currency = Currency.byCode(json['currency'] as String? ?? 'PLN');
  final linesJson = (json['lines'] as List).cast<Map<String, dynamic>>();
  final lines = [
    for (final line in linesJson)
      InvoiceLine(
        description: line['description'] as String,
        quantity: line['quantity'] as num,
        unitPrice: Money.of((line['unitPrice'] as num).toDouble(), currency),
        vat: _vatFrom(line['vat']),
        discountRate: (line['discount'] as num?)?.toDouble() ?? 0.0,
        unit: line['unit'] as String? ?? 'pcs',
      ),
  ];
  return Invoice(
    number: json['number'] as String,
    issueDate: _parseDate(json['issueDate'] as String),
    dueDate: json['dueDate'] == null ? null : _parseDate(json['dueDate'] as String),
    seller: _partyFrom(json['seller'] as Map<String, dynamic>),
    buyer: _partyFrom(json['buyer'] as Map<String, dynamic>),
    currency: currency,
    lines: lines,
    notes: json['notes'] as String?,
    paymentTerms: json['paymentTerms'] as String?,
    reportingCurrency:
        json['reportingCurrency'] == null ? null : Currency.byCode(json['reportingCurrency'] as String),
    reportingRate: (json['reportingRate'] as num?)?.toDouble(),
  );
}

String encodeInvoiceJson(Invoice invoice) {
  final json = <String, dynamic>{
    'number': invoice.number,
    'issueDate': _formatDate(invoice.issueDate),
    if (invoice.dueDate != null) 'dueDate': _formatDate(invoice.dueDate!),
    'currency': invoice.currency.code,
    'seller': _partyToJson(invoice.seller),
    'buyer': _partyToJson(invoice.buyer),
    if (invoice.paymentTerms != null) 'paymentTerms': invoice.paymentTerms,
    if (invoice.notes != null) 'notes': invoice.notes,
    if (invoice.reportingCurrency != null) 'reportingCurrency': invoice.reportingCurrency!.code,
    if (invoice.reportingRate != null) 'reportingRate': invoice.reportingRate,
    'lines': [
      for (final line in invoice.lines)
        {
          'description': line.description,
          'quantity': line.quantity,
          'unitPrice': line.unitPrice.amount,
          'vat': line.vat.rate == 0 ? line.vat.label : (line.vat.rate * 100),
          if (line.discountRate != 0) 'discount': line.discountRate,
          'unit': line.unit,
        },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(json);
}

Party _partyFrom(Map<String, dynamic> json) => Party(
      name: json['name'] as String,
      address: json['address'] as String?,
      taxId: json['taxId'] as String?,
      email: json['email'] as String?,
    );

Map<String, dynamic> _partyToJson(Party party) => {
      'name': party.name,
      if (party.address != null) 'address': party.address,
      if (party.taxId != null) 'taxId': party.taxId,
      if (party.email != null) 'email': party.email,
    };

VatRate _vatFrom(Object? value) {
  if (value is num) return VatRate.fromPercent(value);
  final label = (value as String).trim().toLowerCase();
  switch (label) {
    case 'zw':
    case 'exempt':
      return VatRate.exempt;
    case '0':
    case '0%':
      return VatRate.zero;
    default:
      final numeric = double.tryParse(label.replaceAll('%', ''));
      if (numeric != null) return VatRate.fromPercent(numeric);
      throw FormatException('Unknown VAT rate: $value');
  }
}

DateTime _parseDate(String text) {
  final parts = text.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
