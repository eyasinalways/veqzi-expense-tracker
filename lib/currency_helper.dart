import 'package:shared_preferences/shared_preferences.dart';

class CurrencyHelper {
  static String symbol = '৳';

  static Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    symbol = prefs.getString('currency') ?? '৳';
  }

  static Future<void> saveCurrency(String newSymbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', newSymbol);
    symbol = newSymbol;
  }
}
