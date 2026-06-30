import 'dart:math' as math;

import '../evaluator.dart';
import '../format.dart';
import '../values.dart';
import 'helpers.dart';

void registerText(Map<String, CellFunction> registry) {
  registry['CONCAT'] = (args, ctx) {
    final buffer = StringBuffer();
    for (final value in ctx.flatten(args)) {
      buffer.write(ctx.asText(value));
    }
    return TextValue(buffer.toString());
  };
  registry['CONCATENATE'] = registry['CONCAT']!;

  registry['TEXTJOIN'] = (args, ctx) {
    arity(args, 3);
    final delimiter = textArg(args[0], ctx);
    final ignoreEmpty = boolArg(args[1], ctx);
    final parts = <String>[];
    for (final value in ctx.flatten(args.sublist(2))) {
      final text = ctx.asText(value);
      if (ignoreEmpty && text.isEmpty) continue;
      parts.add(text);
    }
    return TextValue(parts.join(delimiter));
  };

  registry['LEN'] = (args, ctx) {
    arity(args, 1, 1);
    return NumberValue(textArg(args[0], ctx).length.toDouble());
  };

  registry['LEFT'] = (args, ctx) {
    arity(args, 1, 2);
    final text = textArg(args[0], ctx);
    final count = args.length > 1 ? intArg(args[1], ctx) : 1;
    if (count < 0) throw const EvalException(ErrorValue(ErrorKind.value));
    return TextValue(text.substring(0, math.min(count, text.length)));
  };

  registry['RIGHT'] = (args, ctx) {
    arity(args, 1, 2);
    final text = textArg(args[0], ctx);
    final count = args.length > 1 ? intArg(args[1], ctx) : 1;
    if (count < 0) throw const EvalException(ErrorValue(ErrorKind.value));
    final take = math.min(count, text.length);
    return TextValue(text.substring(text.length - take));
  };

  registry['MID'] = (args, ctx) {
    arity(args, 3, 3);
    final text = textArg(args[0], ctx);
    final start = intArg(args[1], ctx);
    final length = intArg(args[2], ctx);
    if (start < 1 || length < 0) throw const EvalException(ErrorValue(ErrorKind.value));
    if (start > text.length) return const TextValue('');
    final begin = start - 1;
    final end = math.min(begin + length, text.length);
    return TextValue(text.substring(begin, end));
  };

  registry['UPPER'] = (args, ctx) {
    arity(args, 1, 1);
    return TextValue(textArg(args[0], ctx).toUpperCase());
  };

  registry['LOWER'] = (args, ctx) {
    arity(args, 1, 1);
    return TextValue(textArg(args[0], ctx).toLowerCase());
  };

  registry['PROPER'] = (args, ctx) {
    arity(args, 1, 1);
    final text = textArg(args[0], ctx);
    final buffer = StringBuffer();
    var atWordStart = true;
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      final isLetter = RegExp(r'[A-Za-z]').hasMatch(ch);
      if (isLetter) {
        buffer.write(atWordStart ? ch.toUpperCase() : ch.toLowerCase());
        atWordStart = false;
      } else {
        buffer.write(ch);
        atWordStart = true;
      }
    }
    return TextValue(buffer.toString());
  };

  registry['TRIM'] = (args, ctx) {
    arity(args, 1, 1);
    return TextValue(textArg(args[0], ctx).trim().replaceAll(RegExp(r'\s+'), ' '));
  };

  registry['REPT'] = (args, ctx) {
    arity(args, 2, 2);
    final count = intArg(args[1], ctx);
    if (count < 0) throw const EvalException(ErrorValue(ErrorKind.value));
    return TextValue(textArg(args[0], ctx) * count);
  };

  registry['EXACT'] = (args, ctx) {
    arity(args, 2, 2);
    return BooleanValue(textArg(args[0], ctx) == textArg(args[1], ctx));
  };

  registry['SUBSTITUTE'] = (args, ctx) {
    arity(args, 3, 4);
    final text = textArg(args[0], ctx);
    final oldText = textArg(args[1], ctx);
    final newText = textArg(args[2], ctx);
    if (oldText.isEmpty) return TextValue(text);
    if (args.length == 3) return TextValue(text.replaceAll(oldText, newText));
    final instance = intArg(args[3], ctx);
    if (instance < 1) throw const EvalException(ErrorValue(ErrorKind.value));
    return TextValue(_replaceNth(text, oldText, newText, instance));
  };

  registry['REPLACE'] = (args, ctx) {
    arity(args, 4, 4);
    final text = textArg(args[0], ctx);
    final start = intArg(args[1], ctx);
    final length = intArg(args[2], ctx);
    final replacement = textArg(args[3], ctx);
    if (start < 1 || length < 0) throw const EvalException(ErrorValue(ErrorKind.value));
    final begin = math.min(start - 1, text.length);
    final end = math.min(begin + length, text.length);
    return TextValue(text.substring(0, begin) + replacement + text.substring(end));
  };

  registry['FIND'] = (args, ctx) {
    arity(args, 2, 3);
    final needle = textArg(args[0], ctx);
    final haystack = textArg(args[1], ctx);
    final start = args.length > 2 ? intArg(args[2], ctx) : 1;
    if (start < 1) throw const EvalException(ErrorValue(ErrorKind.value));
    final index = haystack.indexOf(needle, start - 1);
    if (index < 0) throw const EvalException(ErrorValue(ErrorKind.value));
    return NumberValue((index + 1).toDouble());
  };

  registry['SEARCH'] = (args, ctx) {
    arity(args, 2, 3);
    final needle = textArg(args[0], ctx).toLowerCase();
    final haystack = textArg(args[1], ctx).toLowerCase();
    final start = args.length > 2 ? intArg(args[2], ctx) : 1;
    if (start < 1) throw const EvalException(ErrorValue(ErrorKind.value));
    final index = haystack.indexOf(needle, start - 1);
    if (index < 0) throw const EvalException(ErrorValue(ErrorKind.value));
    return NumberValue((index + 1).toDouble());
  };

  registry['CHAR'] = (args, ctx) {
    arity(args, 1, 1);
    final code = intArg(args[0], ctx);
    if (code < 1 || code > 0x10FFFF) throw const EvalException(ErrorValue(ErrorKind.value));
    return TextValue(String.fromCharCode(code));
  };

  registry['CODE'] = (args, ctx) {
    arity(args, 1, 1);
    final text = textArg(args[0], ctx);
    if (text.isEmpty) throw const EvalException(ErrorValue(ErrorKind.value));
    return NumberValue(text.runes.first.toDouble());
  };

  registry['VALUE'] = (args, ctx) {
    arity(args, 1, 1);
    final parsed = double.tryParse(textArg(args[0], ctx).trim());
    if (parsed == null) throw const EvalException(ErrorValue(ErrorKind.value));
    return NumberValue(parsed);
  };

  registry['NUMBERVALUE'] = (args, ctx) {
    arity(args, 1, 3);
    var text = textArg(args[0], ctx).trim();
    final decimalSep = args.length > 1 ? textArg(args[1], ctx) : '.';
    final groupSep = args.length > 2 ? textArg(args[2], ctx) : ',';
    text = text.replaceAll(groupSep, '');
    if (decimalSep != '.') text = text.replaceAll(decimalSep, '.');
    final parsed = double.tryParse(text);
    if (parsed == null) throw const EvalException(ErrorValue(ErrorKind.value));
    return NumberValue(parsed);
  };

  registry['TEXT'] = (args, ctx) {
    arity(args, 2, 2);
    final value = ctx.eval(args[0]);
    final code = textArg(args[1], ctx);
    return TextValue(NumberFormat.fromCode(code).apply(value));
  };

  registry['REGEXMATCH'] = (args, ctx) {
    arity(args, 2, 2);
    final pattern = RegExp(textArg(args[1], ctx));
    return BooleanValue(pattern.hasMatch(textArg(args[0], ctx)));
  };

  registry['REGEXEXTRACT'] = (args, ctx) {
    arity(args, 2, 2);
    final pattern = RegExp(textArg(args[1], ctx));
    final match = pattern.firstMatch(textArg(args[0], ctx));
    if (match == null) throw const EvalException(ErrorValue(ErrorKind.na));
    return TextValue(match.groupCount >= 1 ? (match.group(1) ?? '') : match.group(0)!);
  };

  registry['REGEXREPLACE'] = (args, ctx) {
    arity(args, 3, 3);
    final pattern = RegExp(textArg(args[1], ctx));
    return TextValue(textArg(args[0], ctx).replaceAll(pattern, textArg(args[2], ctx)));
  };
}

String _replaceNth(String text, String oldText, String newText, int instance) {
  var searchFrom = 0;
  var seen = 0;
  while (true) {
    final index = text.indexOf(oldText, searchFrom);
    if (index < 0) return text;
    seen++;
    if (seen == instance) {
      return text.substring(0, index) + newText + text.substring(index + oldText.length);
    }
    searchFrom = index + oldText.length;
  }
}
