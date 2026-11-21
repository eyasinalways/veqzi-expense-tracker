import 'package:shared_preferences/shared_preferences.dart';

class LanguageHelper {
  static String currentLang = 'bn'; // 'bn' for Bangla, 'en' for English

  static Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    currentLang = prefs.getString('language') ?? 'bn';
  }

  static Future<void> saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    currentLang = lang;
  }

  static String t(String bn, String en) {
    return currentLang == 'en' ? en : bn;
  }
}
