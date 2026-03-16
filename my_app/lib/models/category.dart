import 'package:flutter/material.dart';
import 'transaction.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final TransactionType type;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });
}

// Предопределенные категории
class CategoryData {
  // Доходы
  static const Category salary = Category(
    id: 'salary',
    name: 'Зарплата',
    icon: Icons.work,
    color: Color(0xFF4CAF50),
    type: TransactionType.income,
  );

  static const Category freelance = Category(
    id: 'freelance',
    name: 'Фриланс',
    icon: Icons.computer,
    color: Color(0xFF2196F3),
    type: TransactionType.income,
  );

  static const Category business = Category(
    id: 'business',
    name: 'Бизнес',
    icon: Icons.business_center,
    color: Color(0xFF9C27B0),
    type: TransactionType.income,
  );

  static const Category investments = Category(
    id: 'investments',
    name: 'Инвестиции',
    icon: Icons.trending_up,
    color: Color(0xFFFF9800),
    type: TransactionType.income,
  );

  static const Category gift = Category(
    id: 'gift',
    name: 'Подарок',
    icon: Icons.card_giftcard,
    color: Color(0xFFE91E63),
    type: TransactionType.income,
  );

  static const Category otherIncome = Category(
    id: 'other_income',
    name: 'Другой доход',
    icon: Icons.attach_money,
    color: Color(0xFF607D8B),
    type: TransactionType.income,
  );

  // Расходы
  static const Category food = Category(
    id: 'food',
    name: 'Продукты',
    icon: Icons.restaurant,
    color: Color(0xFFFF5722),
    type: TransactionType.expense,
  );

  static const Category transport = Category(
    id: 'transport',
    name: 'Транспорт',
    icon: Icons.directions_car,
    color: Color(0xFF3F51B5),
    type: TransactionType.expense,
  );

  static const Category entertainment = Category(
    id: 'entertainment',
    name: 'Развлечения',
    icon: Icons.movie,
    color: Color(0xFFE91E63),
    type: TransactionType.expense,
  );

  static const Category shopping = Category(
    id: 'shopping',
    name: 'Покупки',
    icon: Icons.shopping_bag,
    color: Color(0xFF9C27B0),
    type: TransactionType.expense,
  );

  static const Category utilities = Category(
    id: 'utilities',
    name: 'Коммунальные',
    icon: Icons.home,
    color: Color(0xFF607D8B),
    type: TransactionType.expense,
  );

  static const Category health = Category(
    id: 'health',
    name: 'Здоровье',
    icon: Icons.local_hospital,
    color: Color(0xFFF44336),
    type: TransactionType.expense,
  );

  static const Category education = Category(
    id: 'education',
    name: 'Образование',
    icon: Icons.school,
    color: Color(0xFF2196F3),
    type: TransactionType.expense,
  );

  static const Category otherExpense = Category(
    id: 'other_expense',
    name: 'Другой расход',
    icon: Icons.more_horiz,
    color: Color(0xFF757575),
    type: TransactionType.expense,
  );

  // Списки категорий (не константные, потому что содержат список)
  static List<Category> get incomeCategories => [
        salary,
        freelance,
        business,
        investments,
        gift,
        otherIncome,
      ];

  static List<Category> get expenseCategories => [
        food,
        transport,
        entertainment,
        shopping,
        utilities,
        health,
        education,
        otherExpense,
      ];

  static List<Category> getCategoriesByType(TransactionType type) {
    return type == TransactionType.income ? incomeCategories : expenseCategories;
  }

  static Category? getCategoryById(String id) {
    for (var category in [...incomeCategories, ...expenseCategories]) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }
}