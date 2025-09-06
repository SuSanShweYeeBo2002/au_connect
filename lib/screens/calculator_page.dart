import 'package:flutter/material.dart';
import 'dart:math';

class CalculatorPage extends StatefulWidget {
  @override
  _CalculatorPageState createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _result = '0';
  String _expression = '';
  bool _isDegreeMode = true; // true for degrees, false for radians
  bool _isInverseMode = false; // true when Inv is active

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

  void _onPressed(String value) {
    setState(() {
      if (value == 'CE' || value == 'C') {
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
      } else if (value == 'x!') {
        // Insert factorial operator
        if (_expression.isNotEmpty && !_expression.endsWith('!')) {
          _expression += '!';
        }
      } else if (value == 'xʸ') {
        // Insert power operator
        if (_expression.isNotEmpty && !_expression.endsWith('^')) {
          _expression += '^';
        }
      } else if (value == 'Rad' || value == '●Rad') {
        _isDegreeMode = false; // Switch to radians
      } else if (value == 'Deg' || value == '●Deg') {
        _isDegreeMode = true; // Switch to degrees
      } else if (value == 'Inv') {
        _isInverseMode = !_isInverseMode; // Toggle inverse mode
      } else if (value == 'Ans') {
        // Insert previous answer
        _expression += _result;
      } else if (value == 'EXP') {
        // Insert scientific notation 'E'
        if (_expression.isNotEmpty && !_expression.endsWith('E')) {
          _expression += 'E';
        }
      } else if (value == '(') {
        _expression += '(';
      } else if (value == ')') {
        _expression += ')';
      } else if (value == 'sin' ||
          value == 'cos' ||
          value == 'tan' ||
          value == 'sin⁻¹' ||
          value == 'cos⁻¹' ||
          value == 'tan⁻¹') {
        // Handle trigonometric functions with inverse
        if (value.contains('⁻¹')) {
          String baseFunc = value.replaceAll('⁻¹', '');
          _expression += 'a$baseFunc';
        } else {
          String func = _isInverseMode ? 'a$value' : value;
          _expression += func;
        }
        if (_isInverseMode) _isInverseMode = false; // Reset after use
      } else if (value == 'ln' || value == 'eˣ') {
        if (value == 'eˣ') {
          _expression += 'exp';
        } else {
          _expression += _isInverseMode ? 'exp' : 'ln';
        }
        if (_isInverseMode) _isInverseMode = false;
      } else if (value == 'log' || value == '10ˣ') {
        if (value == '10ˣ') {
          _expression += '10^';
        } else {
          _expression += _isInverseMode ? '10^' : 'log';
        }
        if (_isInverseMode) _isInverseMode = false;
      } else {
        _expression += value;
      }
    });
  }
  // ...existing code...

  String _evaluate(String expr) {
    expr = expr.replaceAll('×', '*').replaceAll('÷', '/');
    try {
      // Handle factorials for numbers and parenthesized expressions
      expr = _replaceFactorials(expr);
      // Handle power operations (xʸ becomes ^)
      expr = expr.replaceAll('xʸ', '^');

      // Handle scientific notation (E notation)
      if (expr.contains('E')) {
        // Parse scientific notation like 1.5E3 = 1500
        return double.parse(expr).toString();
      }

      // Handle scientific functions with degree/radian conversion
      if (expr.contains('sin') && !expr.contains('asin')) {
        final val = double.parse(expr.replaceAll('sin', ''));
        final angle = _isDegreeMode ? val * pi / 180 : val;
        return sin(angle).toString();
      } else if (expr.contains('cos') && !expr.contains('acos')) {
        final val = double.parse(expr.replaceAll('cos', ''));
        final angle = _isDegreeMode ? val * pi / 180 : val;
        return cos(angle).toString();
      } else if (expr.contains('tan') && !expr.contains('atan')) {
        final val = double.parse(expr.replaceAll('tan', ''));
        final angle = _isDegreeMode ? val * pi / 180 : val;
        return tan(angle).toString();
      } else if (expr.contains('asin')) {
        final val = double.parse(expr.replaceAll('asin', ''));
        final result = asin(val);
        return (_isDegreeMode ? result * 180 / pi : result).toString();
      } else if (expr.contains('acos')) {
        final val = double.parse(expr.replaceAll('acos', ''));
        final result = acos(val);
        return (_isDegreeMode ? result * 180 / pi : result).toString();
      } else if (expr.contains('atan')) {
        final val = double.parse(expr.replaceAll('atan', ''));
        final result = atan(val);
        return (_isDegreeMode ? result * 180 / pi : result).toString();
      } else if (expr.contains('ln')) {
        final val = double.parse(expr.replaceAll('ln', ''));
        return log(val).toString();
      } else if (expr.contains('exp')) {
        final val = double.parse(expr.replaceAll('exp', ''));
        return exp(val).toString();
      } else if (expr.contains('log')) {
        final val = double.parse(expr.replaceAll('log', ''));
        return (log(val) / log(10)).toString(); // log base 10
      } else if (expr.contains('π')) {
        return pi.toString();
      } else if (expr.contains('e')) {
        return e.toString();
      } else if (expr.contains('√')) {
        final val = double.parse(expr.replaceAll('√', ''));
        return sqrt(val).toString();
      }

      // Basic arithmetic with parentheses and power operations
      final res = _parenthesesEval(expr);
      return res.toString();
    } catch (e) {
      return 'Error';
    }
  }
  // ...existing code...

  num _basicEval(String expr) {
    // Handle scientific notation first
    if (expr.contains('E')) {
      try {
        return double.parse(expr);
      } catch (e) {
        // If parsing fails, continue with other operations
      }
    }

    // Handle power operations first (right-to-left associativity)
    if (expr.contains('^')) {
      return _handlePower(expr);
    }

    // Only supports +, -, *, /
    // This is a simple parser, not for complex expressions
    expr = expr.replaceAll('--', '+');
    List<String> tokens = expr
        .split(RegExp(r'([+\-*/])'))
        .where((t) => t.isNotEmpty)
        .toList();
    List<String> ops = expr
        .split(RegExp(r'[0-9.E]+'))
        .where((t) => t.isNotEmpty)
        .toList();

    num result = double.tryParse(tokens[0]) ?? 0;
    for (int i = 0; i < ops.length && i < tokens.length - 1; i++) {
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

  num _handlePower(String expr) {
    // Handle power operations (^) with right-to-left associativity
    int lastPowerIndex = expr.lastIndexOf('^');
    if (lastPowerIndex == -1) {
      return double.tryParse(expr) ?? 0;
    }

    String leftPart = expr.substring(0, lastPowerIndex);
    String rightPart = expr.substring(lastPowerIndex + 1);

    num base = _basicEval(leftPart);
    num exponent = _handlePower(rightPart); // Recursive for right associativity

    return pow(base, exponent);
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
      [
        _isDegreeMode ? 'Rad' : '●Rad',
        _isDegreeMode ? '●Deg' : 'Deg',
        'x!',
        'CE',
      ],
      [
        'Inv',
        _isInverseMode ? 'sin⁻¹' : 'sin',
        _isInverseMode ? 'cos⁻¹' : 'cos',
        _isInverseMode ? 'tan⁻¹' : 'tan',
      ],
      [_isInverseMode ? 'eˣ' : 'ln', _isInverseMode ? '10ˣ' : 'log', '√', 'xʸ'],
      ['π', 'e', '(', ')'],
      ['Ans', 'EXP', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '⌫', '='],
    ];
    final maxWidth = 380.0;
    final buttonFontSize = 20.0;
    final gridSpacing = 6.0;
    final gridPadding = 16.0;
    // Campus page background color
    const campusBg = Color(0xFFE3F2FD);
    const buttonBg = Color(0xFFE1F5FE);
    const buttonAccent = Color(0xFF0288D1);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: campusBg,
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
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Ans display
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.refresh, color: Colors.grey),
                            Text(
                              'Ans = ${_result != '0' ? _result : '0'}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        // Current result
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Text(
                            _expression.isEmpty ? '0' : _expression,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 36,
                              fontWeight: FontWeight.w300,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Buttons
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: gridPadding,
                        vertical: 8,
                      ),
                      child: Column(
                        children: buttonLabels.map((row) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: row.map((btn) {
                                if (btn.isEmpty)
                                  return Expanded(child: SizedBox.shrink());
                                final isAccent = [
                                  'CE',
                                  '%',
                                  '÷',
                                  '×',
                                  '-',
                                  '+',
                                  '=',
                                  '⌫',
                                  'sin',
                                  'cos',
                                  'tan',
                                  'sin⁻¹',
                                  'cos⁻¹',
                                  'tan⁻¹',
                                  'Rad',
                                  '●Rad',
                                  'Deg',
                                  '●Deg',
                                  'Inv',
                                  'ln',
                                  'eˣ',
                                  'log',
                                  '10ˣ',
                                  'e',
                                  'π',
                                  'xʸ',
                                  '√',
                                  'x!',
                                  '(',
                                  ')',
                                  'Ans',
                                  'EXP',
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
                                            color:
                                                (btn == '●Rad' || btn == '●Deg')
                                                ? Color(
                                                    0xFF4CAF50,
                                                  ) // Green for active mode
                                                : (![
                                                        '0',
                                                        '1',
                                                        '2',
                                                        '3',
                                                        '4',
                                                        '5',
                                                        '6',
                                                        '7',
                                                        '8',
                                                        '9',
                                                        '.',
                                                      ].contains(btn) &&
                                                      btn.isNotEmpty)
                                                ? buttonAccent
                                                : buttonBg,
                                            borderRadius: BorderRadius.circular(
                                              32,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          height: 50,
                                          child: Text(
                                            btn,
                                            style: TextStyle(
                                              fontSize: buttonFontSize,
                                              fontWeight: FontWeight.w600,
                                              color: isAccent
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
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
