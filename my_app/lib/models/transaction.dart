import 'package:flutter/material.dart';

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String category;
  final String? note;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    this.note,
  });
}

enum TransactionType {
  income,
  expense,
}

extension TransactionTypeExtension on TransactionType {
  String get name {
    switch (this) {
      case TransactionType.income:
        return 'Доход';
      case TransactionType.expense:
        return 'Расход';
    }
  }

  Color get color {
    switch (this) {
      case TransactionType.income:
        return const Color(0xFF4CAF50);
      case TransactionType.expense:
        return const Color(0xFFF44336);
    }
  }
}