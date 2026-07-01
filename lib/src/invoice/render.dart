import 'invoice.dart';

String _date(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _quantity(num value) {
  if (value is int || value == value.roundToDouble()) return value.toInt().toString();
  return value.toString();
}

String renderInvoiceText(Invoice invoice) {
  final buffer = StringBuffer();
  buffer.writeln('INVOICE ${invoice.number}');
  buffer.writeln('Issued: ${_date(invoice.issueDate)}'
      '${invoice.dueDate == null ? '' : '   Due: ${_date(invoice.dueDate!)}'}');
  buffer.writeln();

  buffer.writeln('Seller: ${invoice.seller.name}');
  if (invoice.seller.address != null) buffer.writeln('        ${invoice.seller.address}');
  if (invoice.seller.taxId != null) buffer.writeln('        Tax ID: ${invoice.seller.taxId}');
  buffer.writeln('Buyer:  ${invoice.buyer.name}');
  if (invoice.buyer.address != null) buffer.writeln('        ${invoice.buyer.address}');
  if (invoice.buyer.taxId != null) buffer.writeln('        Tax ID: ${invoice.buyer.taxId}');
  buffer.writeln();

  final rows = <List<String>>[
    ['#', 'Description', 'Qty', 'Unit', 'Unit net', 'Disc', 'Net', 'VAT'],
  ];
  for (var i = 0; i < invoice.lines.length; i++) {
    final line = invoice.lines[i];
    rows.add([
      '${i + 1}',
      line.description,
      _quantity(line.quantity),
      line.unit,
      line.unitPrice.formatPlain(),
      line.discountRate == 0 ? '-' : '${(line.discountRate * 100).round()}%',
      line.net.formatPlain(),
      line.vat.label,
    ]);
  }
  buffer.write(_renderTable(rows, const {2, 4, 5, 6}));
  buffer.writeln();

  buffer.writeln('VAT summary (${invoice.currency.code}):');
  final summaryRows = <List<String>>[
    ['Rate', 'Net', 'VAT', 'Gross'],
  ];
  for (final row in invoice.vatSummary()) {
    summaryRows.add([
      row.rate.label,
      row.net.formatPlain(),
      row.vat.formatPlain(),
      row.gross.formatPlain(),
    ]);
  }
  buffer.write(_renderTable(summaryRows, const {1, 2, 3}));
  buffer.writeln();

  buffer.writeln('Subtotal (net): ${invoice.totalNet.format()}');
  buffer.writeln('VAT total:      ${invoice.totalVat.format()}');
  buffer.writeln('TOTAL:          ${invoice.totalGross.format()}');
  final reportingGross = invoice.reportingTotalGross;
  if (reportingGross != null) {
    buffer.writeln('Reporting total: ${reportingGross.format()} '
        '(rate ${invoice.reportingRate})');
  }
  if (invoice.paymentTerms != null) {
    buffer.writeln();
    buffer.writeln('Payment terms: ${invoice.paymentTerms}');
  }
  if (invoice.notes != null) {
    buffer.writeln();
    buffer.writeln('Notes: ${invoice.notes}');
  }
  return buffer.toString();
}

String _renderTable(List<List<String>> rows, Set<int> rightAligned) {
  final columns = rows.first.length;
  final widths = List<int>.filled(columns, 0);
  for (final row in rows) {
    for (var c = 0; c < columns; c++) {
      if (row[c].length > widths[c]) widths[c] = row[c].length;
    }
  }
  final buffer = StringBuffer();
  void writeRow(List<String> row) {
    final cells = <String>[];
    for (var c = 0; c < columns; c++) {
      final cell = rightAligned.contains(c)
          ? row[c].padLeft(widths[c])
          : row[c].padRight(widths[c]);
      cells.add(cell);
    }
    buffer.writeln(cells.join('  '));
  }

  writeRow(rows.first);
  buffer.writeln('-' * (widths.reduce((a, b) => a + b) + (columns - 1) * 2));
  for (final row in rows.skip(1)) {
    writeRow(row);
  }
  return buffer.toString();
}

String renderInvoiceHtml(Invoice invoice) {
  final buffer = StringBuffer();
  buffer.writeln('<!DOCTYPE html>');
  buffer.writeln('<html lang="en">');
  buffer.writeln('<head>');
  buffer.writeln('<meta charset="utf-8">');
  buffer.writeln('<title>Invoice ${_escape(invoice.number)}</title>');
  buffer.writeln('<style>');
  buffer.writeln(_css);
  buffer.writeln('</style>');
  buffer.writeln('</head>');
  buffer.writeln('<body>');
  buffer.writeln('<div class="invoice">');
  buffer.writeln('<header>');
  buffer.writeln('<h1>Invoice</h1>');
  buffer.writeln('<div class="meta">');
  buffer.writeln('<div><span>Number</span><strong>${_escape(invoice.number)}</strong></div>');
  buffer.writeln('<div><span>Issued</span><strong>${_date(invoice.issueDate)}</strong></div>');
  if (invoice.dueDate != null) {
    buffer.writeln('<div><span>Due</span><strong>${_date(invoice.dueDate!)}</strong></div>');
  }
  buffer.writeln('</div>');
  buffer.writeln('</header>');

  buffer.writeln('<section class="parties">');
  buffer.write(_partyHtml('Seller', invoice.seller));
  buffer.write(_partyHtml('Buyer', invoice.buyer));
  buffer.writeln('</section>');

  buffer.writeln('<table class="lines">');
  buffer.writeln('<thead><tr>'
      '<th>#</th><th>Description</th><th class="num">Qty</th><th>Unit</th>'
      '<th class="num">Unit net</th><th class="num">Disc</th>'
      '<th class="num">Net</th><th class="num">VAT</th></tr></thead>');
  buffer.writeln('<tbody>');
  for (var i = 0; i < invoice.lines.length; i++) {
    final line = invoice.lines[i];
    buffer.writeln('<tr>'
        '<td>${i + 1}</td>'
        '<td>${_escape(line.description)}</td>'
        '<td class="num">${_quantity(line.quantity)}</td>'
        '<td>${_escape(line.unit)}</td>'
        '<td class="num">${line.unitPrice.formatPlain()}</td>'
        '<td class="num">${line.discountRate == 0 ? '-' : '${(line.discountRate * 100).round()}%'}</td>'
        '<td class="num">${line.net.formatPlain()}</td>'
        '<td class="num">${_escape(line.vat.label)}</td>'
        '</tr>');
  }
  buffer.writeln('</tbody>');
  buffer.writeln('</table>');

  buffer.writeln('<table class="summary">');
  buffer.writeln('<thead><tr><th>VAT rate</th><th class="num">Net</th>'
      '<th class="num">VAT</th><th class="num">Gross</th></tr></thead>');
  buffer.writeln('<tbody>');
  for (final row in invoice.vatSummary()) {
    buffer.writeln('<tr>'
        '<td>${_escape(row.rate.label)}</td>'
        '<td class="num">${row.net.formatPlain()}</td>'
        '<td class="num">${row.vat.formatPlain()}</td>'
        '<td class="num">${row.gross.formatPlain()}</td>'
        '</tr>');
  }
  buffer.writeln('</tbody>');
  buffer.writeln('</table>');

  buffer.writeln('<div class="totals">');
  buffer.writeln('<div><span>Subtotal (net)</span><strong>${invoice.totalNet.format()}</strong></div>');
  buffer.writeln('<div><span>VAT total</span><strong>${invoice.totalVat.format()}</strong></div>');
  buffer.writeln('<div class="grand"><span>Total</span><strong>${invoice.totalGross.format()}</strong></div>');
  final reportingGross = invoice.reportingTotalGross;
  if (reportingGross != null) {
    buffer.writeln('<div><span>Reporting total</span><strong>${reportingGross.format()}</strong></div>');
  }
  buffer.writeln('</div>');

  if (invoice.paymentTerms != null) {
    buffer.writeln('<p class="terms">Payment terms: ${_escape(invoice.paymentTerms!)}</p>');
  }
  if (invoice.notes != null) {
    buffer.writeln('<p class="notes">${_escape(invoice.notes!)}</p>');
  }
  buffer.writeln('</div>');
  buffer.writeln('</body>');
  buffer.writeln('</html>');
  return buffer.toString();
}

String _partyHtml(String role, Party party) {
  final buffer = StringBuffer();
  buffer.writeln('<div class="party">');
  buffer.writeln('<h2>$role</h2>');
  buffer.writeln('<p class="name">${_escape(party.name)}</p>');
  if (party.address != null) buffer.writeln('<p>${_escape(party.address!)}</p>');
  if (party.taxId != null) buffer.writeln('<p>Tax ID: ${_escape(party.taxId!)}</p>');
  if (party.email != null) buffer.writeln('<p>${_escape(party.email!)}</p>');
  buffer.writeln('</div>');
  return buffer.toString();
}

String _escape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

const _css = '''
body { font-family: Arial, Helvetica, sans-serif; color: #1c2530; background: #eef1f5; margin: 0; padding: 32px; }
.invoice { max-width: 820px; margin: 0 auto; background: #ffffff; padding: 40px; border-radius: 12px; box-shadow: 0 12px 40px rgba(20,30,50,0.12); }
header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #2f5bd0; padding-bottom: 20px; }
header h1 { margin: 0; font-size: 34px; letter-spacing: 2px; color: #2f5bd0; }
.meta { text-align: right; font-size: 13px; }
.meta div { margin-bottom: 4px; }
.meta span { display: inline-block; width: 70px; color: #6b7684; }
.parties { display: flex; gap: 40px; margin: 28px 0; }
.party { flex: 1; }
.party h2 { font-size: 12px; text-transform: uppercase; letter-spacing: 1px; color: #6b7684; margin: 0 0 8px; }
.party .name { font-weight: bold; margin: 0 0 4px; }
.party p { margin: 2px 0; font-size: 13px; }
table { width: 100%; border-collapse: collapse; margin: 18px 0; font-size: 13px; }
th { text-align: left; background: #f3f6fb; color: #48566a; padding: 10px; border-bottom: 2px solid #d6ddea; }
td { padding: 10px; border-bottom: 1px solid #eef1f5; }
.num { text-align: right; }
.totals { margin-top: 24px; margin-left: auto; width: 300px; }
.totals div { display: flex; justify-content: space-between; padding: 6px 0; font-size: 14px; }
.totals .grand { border-top: 2px solid #2f5bd0; margin-top: 6px; padding-top: 12px; font-size: 18px; color: #2f5bd0; }
.terms, .notes { font-size: 12px; color: #6b7684; margin-top: 20px; }
''';
