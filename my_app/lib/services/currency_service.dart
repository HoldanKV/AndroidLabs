import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _apiUrl = 'https://api.exchangerate-api.com/v4/latest/USD';
  
  // Кэш для курсов валют
  Map<String, dynamic>? _cachedRates;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(hours: 1);

  // Публичный метод для получения запасных курсов
  Map<String, double> getFallbackRates() {
    return {
      'USD': 91.5,
      'EUR': 99.2,
    };
  }

  Future<Map<String, double>> getRubRates() async {
    try {
      // Проверяем, нужно ли обновить кэш
      if (_shouldRefreshCache()) {
        await _fetchRates();
      }

      if (_cachedRates != null && _cachedRates!.containsKey('rates')) {
        final rates = _cachedRates!['rates'] as Map<String, dynamic>;
        
        // Получаем курсы к RUB
        double usdToRub = rates['RUB']?.toDouble() ?? 91.5;
        double eurToRub = 0;
        
        // Для EUR нужно сделать дополнительный запрос или рассчитать через USD
        if (rates.containsKey('EUR')) {
          eurToRub = usdToRub / rates['EUR'].toDouble();
        }

        return {
          'USD': usdToRub,
          'EUR': eurToRub,
        };
      }
      
      // Если не удалось получить данные, возвращаем запасные значения
      return getFallbackRates();
      
    } catch (e) {
      print('Ошибка при получении курсов валют: $e');
      return getFallbackRates();
    }
  }

  bool _shouldRefreshCache() {
    if (_cachedRates == null || _lastFetchTime == null) {
      return true;
    }
    return DateTime.now().difference(_lastFetchTime!) > _cacheDuration;
  }

  Future<void> _fetchRates() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      
      if (response.statusCode == 200) {
        _cachedRates = json.decode(response.body);
        _lastFetchTime = DateTime.now();
      } else {
        throw Exception('Failed to load rates: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при запросе к API: $e');
      rethrow;
    }
  }

  // Метод для форсированного обновления
  Future<void> refreshRates() async {
    _cachedRates = null;
    _lastFetchTime = null;
    await getRubRates();
  }
}