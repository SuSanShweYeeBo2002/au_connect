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
      if (value == 'AC') {
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
    final buttonLabels = [
      ['AC', '%', '√', 'π', 'e'],
      ['x²', 'x³', 'sin', 'cos', 'tan'],
      ['cos⁻¹', 'tan⁻¹', 'eˣ', '1/x', 'sin⁻¹'],
      ['7', '8', '9', '(', ')'],
      ['4', '5', '6', '÷', '⌫'],
      ['1', '2', '3', '×', '-'],
      ['0', '.', '=', '+', 'n!'],
    ];
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final isWide = screenWidth > 600;
    final maxWidth = isWide ? 420.0 : screenWidth * 0.98;
    final buttonFontSize = isWide ? 26.0 : screenWidth * 0.045;
    final resultFontSize = isWide ? 48.0 : screenWidth * 0.09;
    final exprFontSize = isWide ? 24.0 : screenWidth * 0.045;
    final gridSpacing = isWide ? 18.0 : 10.0;
    final gridPadding = isWide ? 12.0 : 4.0;
    final resultPadding = isWide ? 28.0 : 18.0;
    final resultVertical = isWide ? 28.0 : 18.0;
    return Scaffold(
      backgroundColor: Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: Color(0xFF64B5F6),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Container(
              width: maxWidth,
              child: Column(
                children: [
                  SizedBox(height: isWide ? 36 : 18),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: gridPadding),
                    padding: EdgeInsets.symmetric(
                      vertical: resultVertical,
                      horizontal: resultPadding,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _expression,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: exprFontSize,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _result,
                            style: TextStyle(
                              color: Color(0xFF1976D2),
                              fontSize: resultFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isWide ? 36 : 18),
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.symmetric(horizontal: gridPadding),
                      itemCount: buttonLabels.expand((e) => e).length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 1,
                        crossAxisSpacing: gridSpacing,
                        mainAxisSpacing: gridSpacing,
                      ),
                      itemBuilder: (context, index) {
                        final btn = buttonLabels
                            .expand((e) => e)
                            .toList()[index];
                        if (btn.isEmpty) return SizedBox.shrink();
                        final isAction = btn == 'AC';
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAction
                                ? Colors.yellow[700]
                                : Colors.white,
                            foregroundColor: isAction
                                ? Colors.black
                                : Color(0xFF1976D2),
                            elevation: isAction ? 2 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => _onPressed(btn),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              btn,
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
