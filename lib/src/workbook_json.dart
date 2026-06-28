import 'dart:convert';

import 'address.dart';
import 'format.dart';
import 'names.dart';
import 'workbook.dart';

const int workbookJsonVersion = 1;

String encodeWorkbookJson(Workbook workbook) {
  final sheets = <Map<String, dynamic>>[];
  for (final sheet in workbook.sheets) {
    final cells = <String, String>{};
    final formats = <String, String>{};
    for (final entry in sheet.cells.entries) {
      final cell = entry.value;
      if (cell.isOccupied) cells[entry.key.label] = cell.raw;
      final format = cell.format;
      if (format != null) formats[entry.key.label] = format.toCode();
    }
    sheets.add({
      'name': sheet.name,
      'cells': cells,
      if (formats.isNotEmpty) 'formats': formats,
    });
  }

  final names = <String, String>{};
  for (final entry in workbook.definedNames) {
    names[entry.key] = _referenceText(entry.value);
  }

  final document = <String, dynamic>{
    'version': workbookJsonVersion,
    'sheets': sheets,
    if (names.isNotEmpty) 'names': names,
  };
  return const JsonEncoder.withIndent('  ').convert(document);
}

Workbook decodeWorkbookJson(String source) {
  final document = jsonDecode(source) as Map<String, dynamic>;
  final workbook = Workbook();
  final sheetsJson = (document['sheets'] as List).cast<Map<String, dynamic>>();
  for (final sheetJson in sheetsJson) {
    final sheet = workbook.addSheet(sheetJson['name'] as String);
    final cells = (sheetJson['cells'] as Map).cast<String, dynamic>();
    for (final entry in cells.entries) {
      sheet.setCell(CellAddress.parse(entry.key), entry.value as String, recalculate: false);
    }
    final formats = sheetJson['formats'] as Map?;
    if (formats != null) {
      for (final entry in formats.cast<String, dynamic>().entries) {
        sheet.setFormatAt(CellAddress.parse(entry.key), NumberFormat.fromCode(entry.value as String));
      }
    }
  }

  final names = document['names'] as Map?;
  if (names != null) {
    for (final entry in names.cast<String, dynamic>().entries) {
      workbook.defineName(entry.key, entry.value as String);
    }
  }

  workbook.recalculate();
  return workbook;
}

String _referenceText(NameTarget target) {
  switch (target) {
    case CellName(:final sheet, :final address):
      return "'${sheet.name}'!${address.label}";
    case RangeName(:final sheet, :final start, :final end):
      return "'${sheet.name}'!${start.label}:${end.label}";
  }
}
