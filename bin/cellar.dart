import 'dart:io';

import 'package:cellar/cellar.dart';

const _usage = '''
cellar - a spreadsheet engine, workbook store and invoice toolkit in pure Dart

Usage:
  dart run cellar <command> [args]
  dart run cellar <file.csv> [options]        (shorthand for the sheet command)

Commands:
  sheet <file.csv>       Load a CSV sheet, optionally edit and print it
  workbook <file.json>   Load a JSON workbook and print a sheet
  invoice <file.json>    Compute and render an invoice
  functions              List every supported formula function
  help                   Show this message

Sheet options:
  --set REF=CONTENT   Set a cell before printing (keep leading '=' for a formula)
  --show REF          Print value and raw content of a single cell
  --formulas          Print the raw formulas grid instead of computed values
  --csv-values        Emit the computed sheet as CSV
  --csv-formulas      Emit the formulas sheet as CSV

Workbook options:
  --sheet NAME        Which sheet to print (default: first)
  --set NAME!REF=VAL  Set a cell on a sheet before printing
  --show NAME!REF     Print a single cell value
  --formulas          Print raw formulas instead of values

Invoice options:
  --html              Emit an HTML invoice instead of the text render
  --out FILE          Write the render to FILE instead of stdout
''';

void main(List<String> args) {
  if (args.isEmpty || args.first == 'help' || args.first == '--help') {
    stdout.write(_usage);
    return;
  }

  final command = args.first;
  final rest = args.sublist(1);
  switch (command) {
    case 'sheet':
      _runSheet(rest);
    case 'workbook':
      _runWorkbook(rest);
    case 'invoice':
      _runInvoice(rest);
    case 'functions':
      stdout.writeln(functionNames().join('\n'));
    default:
      if (command.startsWith('--')) {
        stderr.writeln('Unknown option: $command');
        exit(2);
      }
      _runSheet(args);
  }
}

void _runSheet(List<String> args) {
  String? path;
  final assignments = <String>[];
  final shows = <String>[];
  var showFormulas = false;
  var emitCsvValues = false;
  var emitCsvFormulas = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    switch (arg) {
      case '--set':
        assignments.add(_requireValue(args, ++i, '--set'));
      case '--show':
        shows.add(_requireValue(args, ++i, '--show'));
      case '--formulas':
        showFormulas = true;
      case '--csv-values':
        emitCsvValues = true;
      case '--csv-formulas':
        emitCsvFormulas = true;
      default:
        if (arg.startsWith('--')) {
          stderr.writeln('Unknown option: $arg');
          exit(2);
        }
        path = arg;
    }
  }

  if (path == null) {
    stderr.writeln('No input file given.');
    exit(2);
  }

  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('File not found: $path');
    exit(2);
  }

  final sheet = Sheet();
  importCsv(sheet, file.readAsStringSync());

  for (final assignment in assignments) {
    final separator = assignment.indexOf('=');
    if (separator < 1) {
      stderr.writeln('Invalid --set argument: $assignment');
      exit(2);
    }
    sheet.setValue(assignment.substring(0, separator), assignment.substring(separator + 1));
  }

  if (emitCsvValues) {
    stdout.writeln(exportValues(sheet));
    return;
  }
  if (emitCsvFormulas) {
    stdout.writeln(exportFormulas(sheet));
    return;
  }
  if (shows.isNotEmpty) {
    for (final reference in shows) {
      _printCell(sheet, reference);
    }
    return;
  }

  stdout.write(renderGrid(sheet, formulas: showFormulas));
}

void _runWorkbook(List<String> args) {
  String? path;
  String? sheetName;
  final assignments = <String>[];
  final shows = <String>[];
  var showFormulas = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    switch (arg) {
      case '--sheet':
        sheetName = _requireValue(args, ++i, '--sheet');
      case '--set':
        assignments.add(_requireValue(args, ++i, '--set'));
      case '--show':
        shows.add(_requireValue(args, ++i, '--show'));
      case '--formulas':
        showFormulas = true;
      default:
        if (arg.startsWith('--')) {
          stderr.writeln('Unknown option: $arg');
          exit(2);
        }
        path = arg;
    }
  }

  if (path == null) {
    stderr.writeln('No workbook file given.');
    exit(2);
  }
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('File not found: $path');
    exit(2);
  }

  final workbook = decodeWorkbookJson(file.readAsStringSync());

  for (final assignment in assignments) {
    final separator = assignment.indexOf('=');
    if (separator < 1) {
      stderr.writeln('Invalid --set argument: $assignment');
      exit(2);
    }
    final target = assignment.substring(0, separator);
    final content = assignment.substring(separator + 1);
    final (sheet, reference) = _splitQualified(workbook, target, sheetName);
    sheet.setValue(reference, content);
  }

  if (shows.isNotEmpty) {
    for (final show in shows) {
      final (sheet, reference) = _splitQualified(workbook, show, sheetName);
      _printCell(sheet, reference);
    }
    return;
  }

  final sheet = sheetName == null ? workbook.firstSheet! : workbook.sheet(sheetName);
  stdout.writeln('# ${sheet.name}');
  stdout.write(renderGrid(sheet, formulas: showFormulas));
}

void _runInvoice(List<String> args) {
  String? path;
  String? outPath;
  var html = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    switch (arg) {
      case '--html':
        html = true;
      case '--out':
        outPath = _requireValue(args, ++i, '--out');
      default:
        if (arg.startsWith('--')) {
          stderr.writeln('Unknown option: $arg');
          exit(2);
        }
        path = arg;
    }
  }

  if (path == null) {
    stderr.writeln('No invoice file given.');
    exit(2);
  }
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('File not found: $path');
    exit(2);
  }

  final invoice = invoiceFromJsonString(file.readAsStringSync());
  final rendered = html ? renderInvoiceHtml(invoice) : renderInvoiceText(invoice);
  if (outPath != null) {
    File(outPath).writeAsStringSync(rendered);
    stdout.writeln('Wrote ${html ? 'HTML' : 'text'} invoice to $outPath');
  } else {
    stdout.write(rendered);
  }
}

(Sheet, String) _splitQualified(Workbook workbook, String reference, String? fallback) {
  final bang = reference.indexOf('!');
  if (bang < 0) {
    final sheet = fallback == null ? workbook.firstSheet! : workbook.sheet(fallback);
    return (sheet, reference);
  }
  return (workbook.sheet(reference.substring(0, bang)), reference.substring(bang + 1));
}

void _printCell(Sheet sheet, String reference) {
  final address = CellAddress.parse(reference);
  final raw = sheet.rawAt(address);
  final value = sheet.displayAt(address);
  stdout.writeln('${address.label}: value=$value  content=${raw.isEmpty ? '(empty)' : raw}');
}

String _requireValue(List<String> args, int index, String option) {
  if (index >= args.length) {
    stderr.writeln('Missing value for $option');
    exit(2);
  }
  return args[index];
}
