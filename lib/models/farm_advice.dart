import 'package:flutter/material.dart';

enum AdviceType { thunderstorm, rainToday, hot, wind, fieldWork, normal }

class FarmAdvice {
  final AdviceType type;
  final IconData icon;
  final Color color;

  const FarmAdvice({
    required this.type,
    required this.icon,
    required this.color,
  });
}