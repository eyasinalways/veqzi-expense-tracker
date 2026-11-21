import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'currency_helper.dart';
import 'language_helper.dart';
import 'notification_helper.dart';
import 'app_lock_settings_screen.dart';
import 'main.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _isReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadReminderSettings();
  }

  Future<void> _loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isReminderEnabled = prefs.getBool('isReminderEnabled') ?? false;
      int hour = prefs.getInt('reminderHour') ?? 20;
      int minute = prefs.getInt('reminderMinute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _toggleReminder(bool value) async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isReminderEnabled', value);
    setState(() {
      _isReminderEnabled = value;
    });

    if (value) {
      await NotificationHelper.requestPermissions();
      await NotificationHelper.scheduleDailyReminder(_reminderTime);
    } else {
      await NotificationHelper.cancelReminder();
    }
  }

  Future<void> _pickReminderTime() async {
    HapticFeedback.lightImpact();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _reminderTime) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('reminderHour', picked.hour);
      await prefs.setInt('reminderMinute', picked.minute);
      setState(() {
        _reminderTime = picked;
      });
      if (_isReminderEnabled) {
        await NotificationHelper.scheduleDailyReminder(_reminderTime);
      }
    }
  }

  void _showCurrencyPicker() {
    HapticFeedback.lightImpact();
    final List<String> currencies = ['৳', '\$', '€', '£', '₹'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 5,
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 24),
              Text(LanguageHelper.t('কারেন্সি বেছে নিন', 'Choose Currency'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 15, runSpacing: 15,
                alignment: WrapAlignment.center,
                children: currencies.map((currency) {
                  bool isSelected = CurrencyHelper.symbol == currency;
                  return GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await CurrencyHelper.saveCurrency(currency);
                      if (!mounted) return;
                      setState(() {});
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF4F46E5) : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.withValues(alpha: 0.2), width: 2),
                        boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                      ),
                      child: Text(currency, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showLanguagePicker() {
    HapticFeedback.lightImpact();
    final List<Map<String, String>> languages = [
      {'code': 'bn', 'name': 'বাংলা (Bangla)'},
      {'code': 'en', 'name': 'English'},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 5,
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 24),
              Text(LanguageHelper.t('ভাষা বেছে নিন', 'Choose Language'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ...languages.map((lang) {
                bool isSelected = LanguageHelper.currentLang == lang['code'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.withValues(alpha: 0.2), width: 2),
                    ),
                    tileColor: isSelected ? const Color(0xFF4F46E5).withValues(alpha: 0.1) : Theme.of(context).cardColor,
                    title: Text(lang['name']!, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? const Color(0xFF4F46E5) : null)),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5)) : const Icon(Icons.circle_outlined, color: Colors.grey),
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await LanguageHelper.saveLanguage(lang['code']!);
                      if (!mounted) return;
                      setState(() {});
                      Navigator.pop(context);
                    },
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.5), letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: onTap != null ? () {
          if (onTap != _showCurrencyPicker && onTap != _showLanguagePicker && onTap != _pickReminderTime) {
            HapticFeedback.lightImpact();
          }
          onTap();
        } : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = themeNotifier.value == ThemeMode.dark || (themeNotifier.value == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF4F46E5),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(LanguageHelper.t('অ্যাপ সেটিংস', 'App Settings'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(LanguageHelper.t('প্রেফারেন্স', 'Preferences')),
                  _buildSettingTile(
                    icon: Icons.attach_money_rounded,
                    iconColor: Colors.green,
                    title: LanguageHelper.t('কারেন্সি', 'Currency'),
                    subtitle: '${LanguageHelper.t('বর্তমান: ', 'Current: ')}${CurrencyHelper.symbol}',
                    onTap: _showCurrencyPicker,
                  ).animate().fade(duration: 400.ms, delay: 50.ms).slideX(begin: 0.1),
                  _buildSettingTile(
                    icon: Icons.language_rounded,
                    iconColor: Colors.blueAccent,
                    title: LanguageHelper.t('ভাষা', 'Language'),
                    subtitle: LanguageHelper.currentLang == 'bn' ? 'বাংলা' : 'English',
                    onTap: _showLanguagePicker,
                  ).animate().fade(duration: 400.ms, delay: 100.ms).slideX(begin: 0.1),
                  _buildSettingTile(
                    icon: isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    iconColor: Colors.purpleAccent,
                    title: LanguageHelper.t('ডার্ক মোড', 'Dark Mode'),
                    subtitle: LanguageHelper.t('থিম পরিবর্তন করুন', 'Change app theme'),
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: (val) async {
                        HapticFeedback.lightImpact();
                        themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('isDarkMode', val);
                        setState(() {});
                      },
                      activeColor: const Color(0xFF4F46E5),
                    ),
                  ).animate().fade(duration: 400.ms, delay: 150.ms).slideX(begin: 0.1),

                  const SizedBox(height: 25),
                  _buildSectionHeader(LanguageHelper.t('নোটিফিকেশন', 'Notifications')),
                  _buildSettingTile(
                    icon: Icons.notifications_active_rounded,
                    iconColor: Colors.orangeAccent,
                    title: LanguageHelper.t('ডেইলি রিমাইন্ডার', 'Daily Reminder'),
                    subtitle: _isReminderEnabled 
                        ? '${LanguageHelper.t('সময়: ', 'Time: ')}${_reminderTime.format(context)}' 
                        : LanguageHelper.t('বন্ধ আছে', 'Disabled'),
                    trailing: Switch(
                      value: _isReminderEnabled,
                      onChanged: _toggleReminder,
                      activeColor: const Color(0xFF4F46E5),
                    ),
                    onTap: _isReminderEnabled ? _pickReminderTime : null,
                  ).animate().fade(duration: 400.ms, delay: 200.ms).slideX(begin: 0.1),

                  const SizedBox(height: 25),
                  _buildSectionHeader(LanguageHelper.t('সিকিউরিটি', 'Security')),
                  _buildSettingTile(
                    icon: Icons.security_rounded,
                    iconColor: Colors.redAccent,
                    title: LanguageHelper.t('অ্যাপ লক সেটিংস', 'App Lock Settings'),
                    subtitle: LanguageHelper.t('পিন ও বায়োমেট্রিক সিকিউরিটি', 'PIN and Biometric security'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AppLockSettingsScreen()));
                    },
                  ).animate().fade(duration: 400.ms, delay: 250.ms).slideX(begin: 0.1),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
