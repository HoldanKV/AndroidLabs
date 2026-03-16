import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../widgets/transaction_card.dart';
import '../services/currency_service.dart';
import '../services/storage_service.dart';
import 'add_transaction_screen.dart';
import 'statistics_screen.dart';
import 'categories_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> transactions = [];
  int _selectedIndex = 0;
  
  // Для курсов валют
  Map<String, double>? _exchangeRates;
  bool _isLoadingRates = true;
  String? _ratesError;
  DateTime? _lastRatesUpdate;
  
  final CurrencyService _currencyService = CurrencyService();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _loadExchangeRates();
  }

  // Загрузка транзакций из хранилища
  Future<void> _loadTransactions() async {
    List<Transaction> loadedTransactions = await StorageService.loadTransactions();
    setState(() {
      transactions = loadedTransactions;
    });
  }

  // Сохранение транзакций в хранилище
  Future<void> _saveTransactions() async {
    await StorageService.saveTransactions(transactions);
  }

  Future<void> _loadExchangeRates() async {
    setState(() {
      _isLoadingRates = true;
      _ratesError = null;
    });

    try {
      final rates = await _currencyService.getRubRates();
      setState(() {
        _exchangeRates = rates;
        _isLoadingRates = false;
        _lastRatesUpdate = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _ratesError = 'Не удалось загрузить курсы валют';
        _isLoadingRates = false;
        _exchangeRates = _currencyService.getFallbackRates();
      });
    }
  }

  Future<void> _refreshRates() async {
    await _loadExchangeRates();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Курсы обновлены: ${DateFormat.Hm().format(DateTime.now())}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  double get totalBalance {
    double balance = 0;
    for (var transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        balance += transaction.amount;
      } else {
        balance -= transaction.amount;
      }
    }
    return balance;
  }

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

  void _addTransaction(Transaction transaction) async {
    setState(() {
      transactions.insert(0, transaction);
    });
    await _saveTransactions(); // Сохраняем после добавления
  }

  void _deleteTransaction(String id) async {
    setState(() {
      transactions.removeWhere((t) => t.id == id);
    });
    await _saveTransactions(); // Сохраняем после удаления
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Транзакция удалена')),
      );
    }
  }

  // Метод для очистки всех данных (для тестирования)
  Future<void> _clearAllData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить все данные'),
        content: const Text('Вы уверены? Все транзакции будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await StorageService.clearAllData();
              await _loadTransactions(); // Перезагружаем с демо-данными
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Все данные очищены')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      StatisticsScreen(transactions: transactions), // Передаем транзакции
      const CategoriesScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Статистика',
          ),
          NavigationDestination(
            icon: Icon(Icons.category),
            label: 'Категории',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTransactionScreen(),
                  ),
                );
                if (result != null && result is Transaction) {
                  _addTransaction(result);
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildHomePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Финансовый трекер',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Кнопка очистки (для тестирования, можно убрать)
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearAllData,
          ),
          // Кнопка обновления курсов
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoadingRates ? null : _refreshRates,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRates,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // Карточка с курсами валют
              _buildExchangeRatesCard(),
              
              // Карточка баланса
              _buildBalanceCard(),
              
              // Заголовок последних транзакций
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Последние транзакции',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Всего: ${transactions.length}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Список транзакций
              transactions.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.length > 5 ? 5 : transactions.length,
                      itemBuilder: (context, index) {
                        return TransactionCard(
                          transaction: transactions[index],
                          onDelete: _deleteTransaction,
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExchangeRatesCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Курсы валют к RUB',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_lastRatesUpdate != null)
                Text(
                  DateFormat('HH:mm').format(_lastRatesUpdate!),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_isLoadingRates)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_ratesError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _ratesError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          else if (_exchangeRates != null)
            Row(
              children: [
                Expanded(
                  child: _buildCurrencyCard(
                    'USD',
                    _exchangeRates!['USD'] ?? 0,
                    Icons.currency_exchange,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCurrencyCard(
                    'EUR',
                    _exchangeRates!['EUR'] ?? 0,
                    Icons.euro,
                    Colors.blue,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCurrencyCard(String code, double rate, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${rate.toStringAsFixed(2)} ₽',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade900],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Общий баланс',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${totalBalance.toStringAsFixed(2)} ₽',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Доходы',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+${totalIncome.toStringAsFixed(2)} ₽',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 30,
                width: 1,
                color: Colors.white30,
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Расходы',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '-${totalExpense.toStringAsFixed(2)} ₽',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет транзакций',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Нажмите + чтобы добавить',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}