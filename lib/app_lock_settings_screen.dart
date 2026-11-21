import 'package:flutter/material.dart';
import 'auth_helper.dart';
import 'language_helper.dart';
import 'pin_screen.dart';

class AppLockSettingsScreen extends StatefulWidget {
  const AppLockSettingsScreen({super.key});

  @override
  State<AppLockSettingsScreen> createState() => _AppLockSettingsScreenState();
}

class _AppLockSettingsScreenState extends State<AppLockSettingsScreen> {
  bool _isAppLockEnabled = false;
  int _autoLockDelay = 0; // 0 = Immediately

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    bool enabled = await AuthHelper.isAppLockEnabled();
    int delay = await AuthHelper.getAutoLockDelay();
    setState(() {
      _isAppLockEnabled = enabled;
      _autoLockDelay = delay;
    });
  }

  Future<void> _toggleAppLock(bool value) async {
    if (value) {
      // Trying to enable
      String? currentPin = await AuthHelper.getAppPin();
      if (!mounted) return;
      if (currentPin == null) {
        // First time, need to set PIN
        final success = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PinScreen(
              mode: PinMode.create,
              onPinSet: (pin) async {
                await AuthHelper.setAppPin(pin);
                await AuthHelper.setAppLockEnabled(true);
              },
            ),
          ),
        );
        if (success == true) {
          setState(() {
            _isAppLockEnabled = true;
          });
        }
      } else {
        // PIN exists, just enable
        await AuthHelper.setAppLockEnabled(true);
        setState(() {
          _isAppLockEnabled = true;
        });
      }
    } else {
      // Trying to disable - must verify current PIN first
      String? currentPin = await AuthHelper.getAppPin();
      if (!mounted) return;
      if (currentPin != null) {
        final success = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PinScreen(
              mode: PinMode.verify,
              expectedPin: currentPin,
            ),
          ),
        );
        if (success == true) {
          await AuthHelper.setAppLockEnabled(false);
          setState(() {
            _isAppLockEnabled = false;
          });
        }
      } else {
        await AuthHelper.setAppLockEnabled(false);
        setState(() {
          _isAppLockEnabled = false;
        });
      }
    }
  }

  Future<void> _changePin() async {
    String? currentPin = await AuthHelper.getAppPin();
    if (!mounted) return;
    if (currentPin != null) {
      // First verify old PIN
      final verified = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PinScreen(
            mode: PinMode.verify,
            expectedPin: currentPin,
          ),
        ),
      );
      
      if (verified == true && mounted) {
        // Now set new PIN
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PinScreen(
              mode: PinMode.change,
              onPinSet: (pin) async {
                await AuthHelper.setAppPin(pin);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(LanguageHelper.t('পিন পরিবর্তন সফল হয়েছে!', 'PIN changed successfully!')),
                  backgroundColor: Colors.green,
                ));
              },
            ),
          ),
        );
      }
    }
  }

  void _showDelayPicker() {
    final List<Map<String, dynamic>> delays = [
      {'value': 0, 'name': LanguageHelper.t('সাথে সাথে (Immediately)', 'Immediately')},
      {'value': 60, 'name': LanguageHelper.t('১ মিনিট পর', 'After 1 minute')},
      {'value': 300, 'name': LanguageHelper.t('৫ মিনিট পর', 'After 5 minutes')},
      {'value': 600, 'name': LanguageHelper.t('১০ মিনিট পর', 'After 10 minutes')},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(LanguageHelper.t('অটো লক টাইম', 'Auto Lock Time')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: delays.map((d) {
              return ListTile(
                title: Text(d['name'] as String, style: const TextStyle(fontSize: 16)),
                trailing: _autoLockDelay == d['value'] ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () async {
                  await AuthHelper.setAutoLockDelay(d['value'] as int);
                  if (!mounted) return;
                  setState(() {
                    _autoLockDelay = d['value'] as int;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _getDelayText(int delay) {
    if (delay == 0) return LanguageHelper.t('সাথে সাথে (Immediately)', 'Immediately');
    if (delay == 60) return LanguageHelper.t('১ মিনিট পর', 'After 1 minute');
    if (delay == 300) return LanguageHelper.t('৫ মিনিট পর', 'After 5 minutes');
    if (delay == 600) return LanguageHelper.t('১০ মিনিট পর', 'After 10 minutes');
    return '$delay seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageHelper.t('অ্যাপ লক সেটিংস', 'App Lock Settings')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.security, color: Colors.purple),
                  title: Text(LanguageHelper.t('অ্যাপ লক', 'App Lock'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_isAppLockEnabled 
                      ? LanguageHelper.t('চালু আছে', 'Enabled') 
                      : LanguageHelper.t('বন্ধ আছে', 'Disabled'), 
                      style: const TextStyle(fontSize: 12)),
                  trailing: Switch(
                    value: _isAppLockEnabled,
                    onChanged: _toggleAppLock,
                    activeColor: const Color(0xFF4F46E5),
                  ),
                ),
                if (_isAppLockEnabled) ...[
                  const Divider(height: 1, indent: 50, endIndent: 20),
                  ListTile(
                    leading: const Icon(Icons.password, color: Colors.blue),
                    title: Text(LanguageHelper.t('পিন পরিবর্তন করুন', 'Change PIN'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: _changePin,
                  ),
                  const Divider(height: 1, indent: 50, endIndent: 20),
                  ListTile(
                    leading: const Icon(Icons.timer, color: Colors.orange),
                    title: Text(LanguageHelper.t('অটো লক টাইম', 'Auto Lock Delay'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(_getDelayText(_autoLockDelay), style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: _showDelayPicker,
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
