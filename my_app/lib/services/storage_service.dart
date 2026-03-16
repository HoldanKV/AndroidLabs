import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class StorageService {
  static const String _transactionsKey = 'transactions';
  static const String _firstLaunchKey = 'first_launch';

  // Сохранение транзакций
  static Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Преобразуем список транзакций в список JSON объектов
    List<Map<String, dynamic>> transactionsJson = transactions.map((t) {
      return {
        'id': t.id,
        'title': t.title,
        'amount': t.amount,
        'date': t.date.toIso8601String(),
        'type': t.type == TransactionType.income ? 'income' : 'expense',
        'category': t.category,
        'note': t.note ?? '',
      };
    }).toList();
    
    // Сохраняем в SharedPreferences
    String jsonString = json.encode(transactionsJson);
    await prefs.setString(_transactionsKey, jsonString);
  }

  // Загрузка транзакций
  static Future<List<Transaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Проверяем, первый ли запуск
    bool isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;
    
    String? transactionsString = prefs.getString(_transactionsKey);
    
    if (transactionsString != null && transactionsString.isNotEmpty) {
      // Если есть сохраненные транзакции, загружаем их
      List<dynamic> transactionsJson = json.decode(transactionsString);
      
      return transactionsJson.map((json) {
        return Transaction(
          id: json['id'],
          title: json['title'],
          amount: json['amount'].toDouble(),
          date: DateTime.parse(json['date']),
          type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
          category: json['category'],
          note: json['note']?.isNotEmpty == true ? json['note'] : null,
        );
      }).toList();
    } else if (isFirstLaunch) {
      // Если первый запуск, добавляем демо-данные
      await prefs.setBool(_firstLaunchKey, false);
      return _getDemoTransactions();
    } else {
      // Если не первый запуск и нет транзакций, возвращаем пустой список
      return [];
    }
  }

  // Очистка всех данных
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_transactionsKey);
    await prefs.setBool(_firstLaunchKey, true);
  }

  // Демо-данные для первого запуска
  static List<Transaction> _getDemoTransactions() {
    return [
      Transaction(
        id: '1',
        title: 'Зарплата',
        amount: 75000,
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: TransactionType.income,
        category: 'salary',
      ),
      Transaction(
        id: '2',
        title: 'Продукты',
        amount: 3500,
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: TransactionType.expense,
        category: 'food',
      ),
      Transaction(
        id: '3',
        title: 'Такси',
        amount: 500,
        date: DateTime.now(),
        type: TransactionType.expense,
        category: 'transport',
      ),
      Transaction(
        id: '4',
        title: 'Фриланс',
        amount: 15000,
        date: DateTime.now().subtract(const Duration(days: 3)),
        type: TransactionType.income,
        category: 'freelance',
      ),
      Transaction(
        id: '5',
        title: 'Ресторан',
        amount: 2500,
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: TransactionType.expense,
        category: 'entertainment',
      ),
    ];
  }
}