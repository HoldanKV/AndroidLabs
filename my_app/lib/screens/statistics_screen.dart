import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class StatisticsScreen extends StatelessWidget {
  final List<Transaction> transactions;

  const StatisticsScreen({super.key, required this.transactions});

  double get totalIncome {
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getExpensesByCategory() {
    Map<String, double> categoryExpenses = {};
    
    for (var transaction in transactions.where((t) => t.type == TransactionType.expense)) {
      categoryExpenses[transaction.category] = 
          (categoryExpenses[transaction.category] ?? 0) + transaction.amount;
    }
    
    return categoryExpenses;
  }

  @override
  Widget build(BuildContext context) {
    final expensesByCategory = getExpensesByCategory();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Краткий обзор
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatRow(
                      'Всего доходов:',
                      '${totalIncome.toStringAsFixed(2)} ₽',
                      Colors.green,
                    ),
                    const Divider(height: 20),
                    _buildStatRow(
                      'Всего расходов:',
                      '${totalExpense.toStringAsFixed(2)} ₽',
                      Colors.red,
                    ),
                    const Divider(height: 20),
                    _buildStatRow(
                      'Баланс:',
                      '${(totalIncome - totalExpense).toStringAsFixed(2)} ₽',
                      Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Расходы по категориям
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Расходы по категориям',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (expensesByCategory.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Нет данных о расходах',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      )
                    else
                      ...expensesByCategory.entries.map((entry) {
                        final category = CategoryData.getCategoryById(entry.key);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildCategoryStat(
                            category?.name ?? 'Другое',
                            entry.value,
                            category?.color ?? Colors.grey,
                            category?.icon ?? Icons.help,
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryStat(String name, double amount, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} ₽',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}