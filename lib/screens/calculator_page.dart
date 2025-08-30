import 'package:flutter/material.dart';
import 'dart:math';

class CalculatorPage extends StatefulWidget {
  @override
  _CalculatorPageState createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  // Replace all factorials in the expression
  String _replaceFactorials(String expr) {
    // Handles numbers and parenthesized expressions before '!'
    final reg = RegExp(r'((?:\d+|\([^()]+\)))!');
    while (reg.hasMatch(expr)) {
      expr = expr.replaceAllMapped(reg, (match) {
        String group = match.group(1)!;
        num val;
        if (group.startsWith('(') && group.endsWith(')')) {
          // Evaluate inside parentheses
          val = _parenthesesEval(group.substring(1, group.length - 1));
        } else {
          val = num.tryParse(group) ?? 0;
        }
        // Only allow integer factorials
        int n = val.floor();
        if (n < 0 || val != n) return 'Error';
        return _factorial(n).toString();
      });
    }
    return expr;
  }

  String _result = '0';
  void _onPressed(String value) {
    setState(() {
      if (value == 'AC' || value == 'C') {
        _expression = '';
        _result = '0';
      } else if (value == '=') {
        try {
          _result = _evaluate(_expression);
        } catch (e) {
          _result = 'Error';
        }
      } else if (value == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (value == 'n!') {
        // Insert factorial operator
        if (_expression.isNotEmpty && !_expression.endsWith('!')) {
          _expression += '!';
        }
      } else {
        _expression += value;
      }
    });
  }

  String _expression = '';
  // ...existing code...

  String _evaluate(String expr) {
    expr = expr.replaceAll('×', '*').replaceAll('÷', '/');
    try {
      // Handle factorials for numbers and parenthesized expressions
      expr = _replaceFactorials(expr);
      // For scientific functions
      if (expr.contains('sin')) {
        final val = double.parse(expr.replaceAll('sin', ''));
        return sin(val * pi / 180).toString();
      } else if (expr.contains('cos')) {
        final val = double.parse(expr.replaceAll('cos', ''));
        return cos(val * pi / 180).toString();
      } else if (expr.contains('tan')) {
        final val = double.parse(expr.replaceAll('tan', ''));
        return tan(val * pi / 180).toString();
      } else if (expr.contains('π')) {
        return pi.toString();
      } else if (expr.contains('e')) {
        return e.toString();
      } else if (expr.contains('√')) {
        final val = double.parse(expr.replaceAll('√', ''));
        return sqrt(val).toString();
      } else if (expr.contains('x²')) {
        final val = double.parse(expr.replaceAll('x²', ''));
        return pow(val, 2).toString();
      } else if (expr.contains('x³')) {
        final val = double.parse(expr.replaceAll('x³', ''));
        return pow(val, 3).toString();
      }
      // Basic arithmetic with parentheses
      final res = _parenthesesEval(expr);
      return res.toString();
    } catch (e) {
      return 'Error';
    }
  }
  // ...existing code...

  num _basicEval(String expr) {
    // Only supports +, -, *, /
    // This is a simple parser, not for complex expressions
    expr = expr.replaceAll('--', '+');
    List<String> tokens = expr
        .split(RegExp(r'([+\-*/])'))
        .where((t) => t.isNotEmpty)
        .toList();
    List<String> ops = expr
        .split(RegExp(r'[0-9.]+'))
        .where((t) => t.isNotEmpty)
        .toList();
    num result = double.tryParse(tokens[0]) ?? 0;
    for (int i = 0; i < ops.length; i++) {
      num next = double.tryParse(tokens[i + 1]) ?? 0;
      switch (ops[i]) {
        case '+':
          result += next;
          break;
        case '-':
          result -= next;
          break;
        case '*':
          result *= next;
          break;
        case '/':
          result /= next;
          break;
      }
    }
    return result;
  }

  int _factorial(int n) {
    if (n <= 1) return 1;
    return n * _factorial(n - 1);
  }

  num _parenthesesEval(String expr) {
    expr = expr.replaceAll(' ', '');
    if (!expr.contains('(')) {
      return _basicEval(expr);
    }
    int open = expr.lastIndexOf('(');
    int close = expr.indexOf(')', open);
    if (open == -1 || close == -1) return _basicEval(expr);
    String before = expr.substring(0, open);
    String inside = expr.substring(open + 1, close);
    String after = expr.substring(close + 1);
    num val = _parenthesesEval(inside);
    String newExpr = before + val.toString() + after;
    return _parenthesesEval(newExpr);
  }

  @override
  Widget build(BuildContext context) {
    // Button layout: each row contains exactly 4 buttons
    final buttonLabels = [
      ['sin', 'cos', 'tan', '()'],
      ['deg', 'in', 'log', 'e'],
      ['π', 'xʸ', '√', '!'],
      ['C', '%', '÷', '⌫'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['00', '0', '.', '='],
    ];
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final maxWidth = 360.0;
    final buttonFontSize = 22.0;
    final resultFontSize = 28.0;
    final exprFontSize = 32.0;
    final gridSpacing = 8.0;
    final gridPadding = 16.0;
    final resultPadding = 0.0;
    final resultVertical = 0.0;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Container(
            width: maxWidth,
            margin: EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(
                    top: 18,
                    left: 18,
                    right: 18,
                    bottom: 0,
                  ),
                  child: Center(
                    child: Text(
                      'Scientific Calculator',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // Expression/result
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          _expression,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: exprFontSize,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _result,
                        style: TextStyle(
                          color: Color(0xFFFF7043),
                          fontSize: resultFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
                // Buttons
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: gridPadding,
                    vertical: 8,
                  ),
                  child: Column(
                    children: buttonLabels.map((row) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: row.map((btn) {
                          if (btn.isEmpty)
                            return Expanded(child: SizedBox.shrink());
                          final isOrange = [
                            'C',
                            '%',
                            '÷',
                            '×',
                            '-',
                            '+',
                            '=',
                            'sin',
                            'cos',
                            'tan',
                            'deg',
                            'in',
                            'log',
                            'e',
                            'π',
                            'xʸ',
                            '√',
                            '!',
                          ].contains(btn);
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(gridSpacing / 2),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(32),
                                  onTap: () => _onPressed(btn),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isOrange
                                          ? Color(
                                              0xFFFFA726,
                                            ).withOpacity(btn == '=' ? 1 : 0.15)
                                          : Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                    alignment: Alignment.center,
                                    height: 56,
                                    child: Text(
                                      btn,
                                      style: TextStyle(
                                        fontSize: buttonFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: isOrange
                                            ? Color(0xFFFF7043)
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
