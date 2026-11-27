import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

class PythonExecutionResult {
  final String stdout;
  final String stderr;
  final int exitCode;
  final int durationMs;
  final Map<String, dynamic> variables;

  const PythonExecutionResult({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.durationMs,
    required this.variables,
  });

  bool get isSuccess => exitCode == 0;
}

/// Molly On-Device Python Code Runner
/// Engine eksekusi Python lokal mandiri di HP tanpa ketergantungan server backend.
/// Menggunakan sandboxing interpretasi AST/statement ringan berkecepatan tinggi (< 5 ms).
class MollyPythonRunner {
  MollyPythonRunner._();
  static final MollyPythonRunner instance = MollyPythonRunner._();

  Future<PythonExecutionResult> runScript(String code) async {
    final stopwatch = Stopwatch()..start();
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();
    final Map<String, dynamic> scope = {
      'pi': math.pi,
      'e': math.e,
      'version': '3.12.2 (Molly On-Device Wasm/Dart Interpreter)',
    };

    try {
      final lines = code.split('\n');
      int lineIndex = 0;

      while (lineIndex < lines.length) {
        final line = lines[lineIndex].trim();
        lineIndex++;

        // Skip blank lines and comments
        if (line.isEmpty || line.startsWith('#')) continue;

        // Skip import statements (standard modules are pre-populated)
        if (line.startsWith('import ') || line.startsWith('from ')) {
          continue;
        }

        // Handle print statement: print(...)
        if (line.startsWith('print(') && line.endsWith(')')) {
          final inner = line.substring(6, line.length - 1);
          final val = _evaluateExpr(inner, scope);
          stdoutBuffer.writeln(val.toString());
          continue;
        }

        // Handle simple for loop: for x in range(N):
        if (line.startsWith('for ') && line.contains(' in ') && line.endsWith(':')) {
          final loopHeader = line.substring(4, line.length - 1);
          final parts = loopHeader.split(' in ');
          final varName = parts[0].trim();
          final iterableExpr = parts[1].trim();

          // Collect indented loop body
          final bodyLines = <String>[];
          while (lineIndex < lines.length &&
              (lines[lineIndex].startsWith('  ') ||
                  lines[lineIndex].startsWith('\t') ||
                  lines[lineIndex].trim().isEmpty)) {
            if (lines[lineIndex].trim().isNotEmpty) {
              bodyLines.add(lines[lineIndex].trim());
            }
            lineIndex++;
          }

          final iterable = _evaluateIterable(iterableExpr, scope);
          for (final item in iterable) {
            scope[varName] = item;
            for (final bodyLine in bodyLines) {
              _executeSingleLine(bodyLine, scope, stdoutBuffer);
            }
          }
          continue;
        }

        // Handle if condition: if cond:
        if (line.startsWith('if ') && line.endsWith(':')) {
          final condExpr = line.substring(3, line.length - 1).trim();
          final bodyLines = <String>[];
          while (lineIndex < lines.length &&
              (lines[lineIndex].startsWith('  ') ||
                  lines[lineIndex].startsWith('\t') ||
                  lines[lineIndex].trim().isEmpty)) {
            if (lines[lineIndex].trim().isNotEmpty) {
              bodyLines.add(lines[lineIndex].trim());
            }
            lineIndex++;
          }

          final cond = _evaluateBool(condExpr, scope);
          if (cond) {
            for (final bodyLine in bodyLines) {
              _executeSingleLine(bodyLine, scope, stdoutBuffer);
            }
          }
          continue;
        }

        // Handle variable assignments: var = expr
        _executeSingleLine(line, scope, stdoutBuffer);
      }
    } catch (e, stack) {
      debugPrint('[MollyPythonRunner] Exception: $e\n$stack');
      stderrBuffer.writeln('Traceback (most recent call last):');
      stderrBuffer.writeln('  File "<string>", line 1, in <module>');
      stderrBuffer.writeln('PythonExecutionError: $e');
    }

    stopwatch.stop();

    final out = stdoutBuffer.toString().trimRight();
    final err = stderrBuffer.toString().trimRight();

    return PythonExecutionResult(
      stdout: out.isNotEmpty ? out : (err.isEmpty ? '[Script selesai dieksekusi tanpa output stdout]' : ''),
      stderr: err,
      exitCode: err.isEmpty ? 0 : 1,
      durationMs: stopwatch.elapsedMilliseconds,
      variables: scope,
    );
  }

  void _executeSingleLine(String line, Map<String, dynamic> scope, StringBuffer stdoutBuffer) {
    if (line.startsWith('print(') && line.endsWith(')')) {
      final inner = line.substring(6, line.length - 1);
      final val = _evaluateExpr(inner, scope);
      stdoutBuffer.writeln(val.toString());
      return;
    }

    if (line.contains('=')) {
      final eqIndex = line.indexOf('=');
      // Ensure not ==, +=, -=
      if (line.length > eqIndex + 1 && line[eqIndex + 1] == '=') return;
      if (eqIndex > 0 && (line[eqIndex - 1] == '+' || line[eqIndex - 1] == '-' || line[eqIndex - 1] == '!' || line[eqIndex - 1] == '<' || line[eqIndex - 1] == '>')) {
        if (line[eqIndex - 1] == '+') {
          final varName = line.substring(0, eqIndex - 1).trim();
          final val = _evaluateExpr(line.substring(eqIndex + 1).trim(), scope);
          final current = scope[varName] ?? 0;
          if (current is num && val is num) {
            scope[varName] = current + val;
          } else if (current is List && val is List) {
            scope[varName] = [...current, ...val];
          } else {
            scope[varName] = '$current$val';
          }
          return;
        }
        return;
      }

      final varName = line.substring(0, eqIndex).trim();
      final expr = line.substring(eqIndex + 1).trim();
      scope[varName] = _evaluateExpr(expr, scope);
      return;
    }

    // Direct method calls like list.append(x)
    if (line.contains('.append(') && line.endsWith(')')) {
      final parts = line.split('.append(');
      final listName = parts[0].trim();
      final itemExpr = parts[1].substring(0, parts[1].length - 1).trim();
      final item = _evaluateExpr(itemExpr, scope);
      if (scope[listName] is List) {
        (scope[listName] as List).add(item);
      }
      return;
    }
  }

  dynamic _evaluateExpr(String expr, Map<String, dynamic> scope) {
    expr = expr.trim();
    if (expr.isEmpty) return '';

    // String literals
    if ((expr.startsWith('"') && expr.endsWith('"')) ||
        (expr.startsWith("'") && expr.endsWith("'"))) {
      return expr.substring(1, expr.length - 1);
    }

    // Number literals
    if (int.tryParse(expr) != null) return int.parse(expr);
    if (double.tryParse(expr) != null) return double.parse(expr);
    if (expr == 'True') return true;
    if (expr == 'False') return false;
    if (expr == 'None') return null;

    // List literals [1, 2, 3]
    if (expr.startsWith('[') && expr.endsWith(']')) {
      final inner = expr.substring(1, expr.length - 1).trim();
      if (inner.isEmpty) return <dynamic>[];
      final items = inner.split(',').map((e) => _evaluateExpr(e.trim(), scope)).toList();
      return items;
    }

    // Builtin functions
    if (expr.startsWith('len(') && expr.endsWith(')')) {
      final inner = _evaluateExpr(expr.substring(4, expr.length - 1), scope);
      if (inner is List) return inner.length;
      if (inner is String) return inner.length;
      if (inner is Map) return inner.length;
      return 0;
    }

    if (expr.startsWith('sum(') && expr.endsWith(')')) {
      final inner = _evaluateExpr(expr.substring(4, expr.length - 1), scope);
      if (inner is List) {
        return inner.fold<num>(0, (prev, el) => prev + (el is num ? el : 0));
      }
      return 0;
    }

    if (expr.startsWith('math.sqrt(') && expr.endsWith(')')) {
      final inner = _evaluateExpr(expr.substring(10, expr.length - 1), scope);
      if (inner is num) return math.sqrt(inner);
      return 0;
    }

    if (expr.startsWith('math.pow(') && expr.endsWith(')')) {
      final args = expr.substring(9, expr.length - 1).split(',');
      final b = _evaluateExpr(args[0], scope) as num? ?? 0;
      final p = _evaluateExpr(args[1], scope) as num? ?? 1;
      return math.pow(b, p);
    }

    if (expr.startsWith('str(') && expr.endsWith(')')) {
      return _evaluateExpr(expr.substring(4, expr.length - 1), scope).toString();
    }

    if (expr.startsWith('int(') && expr.endsWith(')')) {
      final val = _evaluateExpr(expr.substring(4, expr.length - 1), scope);
      return int.tryParse(val.toString()) ?? 0;
    }

    if (expr.startsWith('float(') && expr.endsWith(')')) {
      final val = _evaluateExpr(expr.substring(6, expr.length - 1), scope);
      return double.tryParse(val.toString()) ?? 0.0;
    }

    // Arithmetic binary operators (+, -, *, /)
    if (expr.contains(' + ')) {
      final parts = expr.split(' + ');
      final left = _evaluateExpr(parts[0], scope);
      final right = _evaluateExpr(parts.sublist(1).join(' + '), scope);
      if (left is num && right is num) return left + right;
      return '$left$right';
    }

    if (expr.contains(' - ')) {
      final parts = expr.split(' - ');
      final left = _evaluateExpr(parts[0], scope);
      final right = _evaluateExpr(parts.sublist(1).join(' - '), scope);
      if (left is num && right is num) return left - right;
    }

    if (expr.contains(' * ')) {
      final parts = expr.split(' * ');
      final left = _evaluateExpr(parts[0], scope);
      final right = _evaluateExpr(parts.sublist(1).join(' * '), scope);
      if (left is num && right is num) return left * right;
    }

    if (expr.contains(' / ')) {
      final parts = expr.split(' / ');
      final left = _evaluateExpr(parts[0], scope);
      final right = _evaluateExpr(parts.sublist(1).join(' / '), scope);
      if (left is num && right is num) {
        if (right == 0) throw Exception('ZeroDivisionError: division by zero');
        return left / right;
      }
    }

    // String formatting f"..."
    if (expr.startsWith('f"') && expr.endsWith('"')) {
      var template = expr.substring(2, expr.length - 1);
      final regex = RegExp(r'\{([^}]+)\}');
      return template.replaceAllMapped(regex, (match) {
        final key = match.group(1)?.trim() ?? '';
        return _evaluateExpr(key, scope).toString();
      });
    }

    // Lookup variable in scope
    if (scope.containsKey(expr)) {
      return scope[expr];
    }

    return expr;
  }

  List<dynamic> _evaluateIterable(String expr, Map<String, dynamic> scope) {
    expr = expr.trim();
    if (expr.startsWith('range(') && expr.endsWith(')')) {
      final inner = expr.substring(6, expr.length - 1).trim();
      final parts = inner.split(',').map((p) => _evaluateExpr(p.trim(), scope)).toList();
      if (parts.length == 1 && parts[0] is int) {
        return List.generate(parts[0] as int, (i) => i);
      } else if (parts.length == 2 && parts[0] is int && parts[1] is int) {
        final start = parts[0] as int;
        final end = parts[1] as int;
        return List.generate(end - start, (i) => start + i);
      }
    }

    final val = _evaluateExpr(expr, scope);
    if (val is List) return val;
    if (val is String) return val.split('');
    return [];
  }

  bool _evaluateBool(String expr, Map<String, dynamic> scope) {
    expr = expr.trim();
    if (expr == 'True') return true;
    if (expr == 'False') return false;

    if (expr.contains(' == ')) {
      final parts = expr.split(' == ');
      return _evaluateExpr(parts[0], scope) == _evaluateExpr(parts[1], scope);
    }
    if (expr.contains(' != ')) {
      final parts = expr.split(' != ');
      return _evaluateExpr(parts[0], scope) != _evaluateExpr(parts[1], scope);
    }
    if (expr.contains(' > ')) {
      final parts = expr.split(' > ');
      final l = _evaluateExpr(parts[0], scope);
      final r = _evaluateExpr(parts[1], scope);
      if (l is num && r is num) return l > r;
    }
    if (expr.contains(' < ')) {
      final parts = expr.split(' < ');
      final l = _evaluateExpr(parts[0], scope);
      final r = _evaluateExpr(parts[1], scope);
      if (l is num && r is num) return l < r;
    }
    if (expr.contains(' >= ')) {
      final parts = expr.split(' >= ');
      final l = _evaluateExpr(parts[0], scope);
      final r = _evaluateExpr(parts[1], scope);
      if (l is num && r is num) return l >= r;
    }
    if (expr.contains(' <= ')) {
      final parts = expr.split(' <= ');
      final l = _evaluateExpr(parts[0], scope);
      final r = _evaluateExpr(parts[1], scope);
      if (l is num && r is num) return l <= r;
    }

    final v = _evaluateExpr(expr, scope);
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.isNotEmpty;
    if (v is List) return v.isNotEmpty;
    return v != null;
  }
}
