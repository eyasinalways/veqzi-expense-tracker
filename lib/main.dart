import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // চার্টের প্যাকেজ
import 'package:google_fonts/google_fonts.dart';
import 'add_transaction.dart';
import 'database_helper.dart';
import 'profile_screen.dart';
import 'currency_helper.dart';
import 'language_helper.dart';
import 'notification_helper.dart';
import 'auth_helper.dart';
import 'pin_screen.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart';


final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CurrencyHelper.loadCurrency();
  await LanguageHelper.loadLanguage();
  await NotificationHelper.init();
  
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode');
  if (isDarkMode != null) {
    themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
  
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, ThemeMode currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Veqzi',
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4F46E5),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            cardColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black87,
              elevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle.dark, 
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
              ),
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              dialBackgroundColor: Colors.grey[100],
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white : Colors.black87),
              hourMinuteColor: WidgetStateColor.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF4F46E5) : Colors.grey[200]!),
              dialHandColor: const Color(0xFF4F46E5),
              dialTextColor: WidgetStateColor.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white : Colors.black87),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white : Colors.black87),
              dayPeriodColor: WidgetStateColor.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF4F46E5) : Colors.grey[200]!),
              cancelButtonStyle: TextButton.styleFrom(foregroundColor: Colors.black54),
              confirmButtonStyle: TextButton.styleFrom(foregroundColor: const Color(0xFF4F46E5)),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4F46E5),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle.light, 
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
              ),
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: const Color(0xFF1E1E1E),
              dialBackgroundColor: const Color(0xFF2A2A2A),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white : Colors.white70),
              hourMinuteColor: WidgetStateColor.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF4F46E5) : const Color(0xFF2A2A2A)),
              dialHandColor: const Color(0xFF4F46E5),
              dialTextColor: WidgetStateColor.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white : Colors.white70),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white : Colors.white70),
              dayPeriodColor: WidgetStateColor.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF4F46E5) : const Color(0xFF2A2A2A)),
              cancelButtonStyle: TextButton.styleFrom(foregroundColor: Colors.white54),
              confirmButtonStyle: TextButton.styleFrom(foregroundColor: const Color(0xFF4F46E5)),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;
  DateTime? _pausedTime;
  bool _isLockScreenShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAppLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAppLockOnResume();
    } else if (state == AppLifecycleState.paused || state.name == 'hidden') {
      if (AuthHelper.isExternalIntentInProgress) return;
      _pausedTime ??= DateTime.now();
      _lockAppImmediatelyIfNeeded();
    }
  }

  Future<void> _lockAppImmediatelyIfNeeded() async {
    if (AuthHelper.isExternalIntentInProgress) return;
    bool isEnabled = await AuthHelper.isAppLockEnabled();
    if (!isEnabled) return;
    int delay = await AuthHelper.getAutoLockDelay();
    if (delay == 0 && _isAuthenticated) {
      _showLockScreenOverlay();
    }
  }

  Future<void> _checkAppLockOnResume() async {
    final DateTime? pausedTimeAtResume = _pausedTime;
    _pausedTime = null; 

    if (pausedTimeAtResume == null) return;
    
    if (AuthHelper.isExternalIntentInProgress) return;

    bool isEnabled = await AuthHelper.isAppLockEnabled();
    if (!isEnabled) return;

    int delay = await AuthHelper.getAutoLockDelay(); 
    if (delay < 0) return; 

    final diff = DateTime.now().difference(pausedTimeAtResume);
    
    if (diff.inSeconds >= delay && _isAuthenticated) {
      _showLockScreenOverlay();
    }
  }

  Future<void> _checkAppLock() async {
    bool isEnabled = await AuthHelper.isAppLockEnabled();
    if (!isEnabled) {
      setState(() {
        _isAuthenticated = true;
        _isCheckingAuth = false;
      });
      return;
    }

    setState(() {
      _isCheckingAuth = false;
      _isAuthenticated = false;
    });
  }

  void _showLockScreenOverlay() {
    if (_isLockScreenShowing) return;
    _isLockScreenShowing = true;
    
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => PopScope(
          canPop: false,
          child: _CustomLockScreen(
            onUnlock: () {
              _isLockScreenShowing = false;
            },
          ),
        ),
      ),
    );
  }

  void _unlockApp() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_isAuthenticated) return const DashboardScreen();
    return _CustomLockScreen(onUnlock: _unlockApp);
  }
}

class _CustomLockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  const _CustomLockScreen({required this.onUnlock});

  @override
  State<_CustomLockScreen> createState() => _CustomLockScreenState();
}

class _CustomLockScreenState extends State<_CustomLockScreen> {
  String? _expectedPin;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    _expectedPin = await AuthHelper.getAppPin();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_expectedPin == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return PinScreen(
      mode: PinMode.verify,
      expectedPin: _expectedPin,
      onPinSet: (pin) {
        widget.onUnlock();
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _transactions = [];
  Map<String, List<Map<String, dynamic>>> _groupedTransactions = {};
  List<String> _groupedKeys = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  DateTime _selectedMonth = DateTime.now();
  int touchedIndex = -1;

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  String _formatMonthYear(DateTime date) {
    return '${_months[date.month - 1]} ${date.year}';
  }

  void _goToPreviousMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
    _refreshData();
  }

  void _goToNextMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
    _refreshData();
  }

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() async {
    final data = await DatabaseHelper.instance.queryRowsByMonth(_selectedMonth.year, _selectedMonth.month);
    final grouped = _groupTransactionsByDate(data);

    double income = 0;
    double expense = 0;

    for (var item in data) {
      if (item[DatabaseHelper.columnType] == 'income') {
        income += item[DatabaseHelper.columnAmount];
      } else {
        expense += item[DatabaseHelper.columnAmount];
      }
    }

    setState(() {
      _transactions = data;
      _groupedTransactions = grouped;
      _groupedKeys = grouped.keys.toList();
      _totalIncome = income;
      _totalExpense = expense;
    });
  }

  Future<void> _exportToCSV() async {
    List<List<dynamic>> rows = [];
    rows.add(['Date', 'Time', 'Title', 'Category', 'Type', 'Amount', 'Note']);

    for (var tx in _transactions) {
      String dateStr = tx[DatabaseHelper.columnDate];
      String timeStr = '';
      try {
        DateTime date = DateTime.parse(dateStr);
        dateStr = DateFormat('dd MMM yyyy').format(date);
        timeStr = DateFormat('hh:mm a').format(date);
      } catch (_) {}

      rows.add([
        dateStr,
        timeStr,
        tx[DatabaseHelper.columnTitle],
        tx[DatabaseHelper.columnCategory],
        tx[DatabaseHelper.columnType],
        tx[DatabaseHelper.columnAmount],
        tx[DatabaseHelper.columnNote] ?? '',
      ]);
    }

    String csvData = csv.encode(rows);

    final dir = await getTemporaryDirectory();
    final fileName = 'Expense_Report_${_selectedMonth.year}_${_selectedMonth.month.toString().padLeft(2, '0')}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvData);

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)], 
      text: 'Expense Report for ${_formatMonthYear(_selectedMonth)}'
    ));
  }

  // ক্যাটাগরি অনুযায়ী খরচের হিসাব বের করার ফাংশন
  Map<String, double> _getCategoryExpenses() {
    Map<String, double> categoryMap = {};
    for (var tx in _transactions) {
      if (tx[DatabaseHelper.columnType] == 'expense') {
        String cat = tx[DatabaseHelper.columnCategory];
        double amount = tx[DatabaseHelper.columnAmount];
        categoryMap[cat] = (categoryMap[cat] ?? 0) + amount;
      }
    }
    return categoryMap;
  }

  // ক্যাটাগরির জন্য আলাদা আলাদা রঙ
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food': return Colors.orange;
      case 'Transport': return Colors.blue;
      case 'Rent': return Colors.purple;
      case 'Others': return Colors.grey;
      default: return Colors.teal;
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate(List<Map<String, dynamic>> transactions) {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var tx in transactions) {
      DateTime date = DateTime.parse(tx[DatabaseHelper.columnDate]);
      DateTime dateOnly = DateTime(date.year, date.month, date.day);

      String header = DateFormat('dd MMM yyyy').format(dateOnly);

      if (!grouped.containsKey(header)) {
        grouped[header] = [];
      }
      grouped[header]!.add(tx);
    }
    return grouped;
  }

  void _showTransactionDetails(Map<String, dynamic> tx, bool isIncome, String formattedDate) {
    String note = tx[DatabaseHelper.columnNote] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tx[DatabaseHelper.columnTitle], style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${LanguageHelper.t('পরিমাণ: ', 'Amount: ')}${CurrencyHelper.symbol}${tx[DatabaseHelper.columnAmount]}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.red),
              ),
              const SizedBox(height: 15),
              Text('${LanguageHelper.t('ধরণ: ', 'Type: ')}${isIncome ? LanguageHelper.t("আয়", "Income") : LanguageHelper.t("ব্যয়", "Expense")}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 5),
              Text('${LanguageHelper.t('ক্যাটাগরি: ', 'Category: ')}${tx[DatabaseHelper.columnCategory]}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 5),
              Text('${LanguageHelper.t('তারিখ: ', 'Date: ')}$formattedDate', style: const TextStyle(fontSize: 16)),

              if (note.isNotEmpty) ...[
                const Divider(height: 20, thickness: 1),
                Text(LanguageHelper.t('নোট:', 'Note:'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 4),
                Text(note, style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic)),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LanguageHelper.t('বন্ধ করুন', 'Close'), style: const TextStyle(color: Colors.teal, fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double currentBalance = _totalIncome - _totalExpense;
    Map<String, double> categoryExpenses = _getCategoryExpenses();
    
    final now = DateTime.now();
    bool canGoNext = _selectedMonth.year < now.year || (_selectedMonth.year == now.year && _selectedMonth.month < now.month);

    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageHelper.t('আমার হিসাব', 'Expense Tracker'), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        // এই actions অংশটুকু নতুন করে বসান
        actions: [
          IconButton(
            icon: const Icon(Icons.download, size: 28, color: Color(0xFF4F46E5)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(LanguageHelper.t('রিপোর্ট তৈরি হচ্ছে...', 'Preparing report...')),
                  duration: const Duration(seconds: 2),
                ),
              );
              _exportToCSV();
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, size: 32, color: Color(0xFF4F46E5)),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
              _refreshData(); // Profile theke back ashar sathe sathe auto data update hobe
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Month Navigator
          SliverPadding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 10.0),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 30, color: Color(0xFF4F46E5)),
                    onPressed: _goToPreviousMonth,
                  ),
                  Text(
                    _formatMonthYear(_selectedMonth),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, size: 30, color: canGoNext ? const Color(0xFF4F46E5) : Colors.grey),
                    onPressed: canGoNext ? _goToNextMonth : null,
                  ),
                ],
              ),
            ),
          ),

          // Sticky Summary Cards
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              minHeight: 200.0,
              maxHeight: 200.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                alignment: Alignment.center,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: // ১. ব্যালেন্স কার্ড
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ]
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(LanguageHelper.t('বর্তমান ব্যালেন্স', 'Current Balance'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: currentBalance),
                            duration: const Duration(seconds: 1),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Text('${CurrencyHelper.symbol} ${value.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold));
                            }
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMiniSummary(LanguageHelper.t('আয়', 'Income'), _totalIncome, Icons.arrow_downward, Colors.greenAccent),
                              Container(width: 1, height: 30, color: Colors.white30),
                              _buildMiniSummary(LanguageHelper.t('ব্যয়', 'Expense'), _totalExpense, Icons.arrow_upward, Colors.redAccent),
                            ],
                          )
                        ],
                      ),
                    ),
              ),
            ),
          ),

          // Pie Chart and Transaction List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // ৩. খরচের পাই-চার্ট
            if (_totalExpense > 0) ...[
              Text(LanguageHelper.t('খরচের গ্রাফ', 'Expense Graph'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 140, // চার্টের উচ্চতা
                child: PieChart(
                  swapAnimationDuration: const Duration(milliseconds: 800),
                  swapAnimationCurve: Curves.easeInOut,
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sectionsSpace: 2,
                    centerSpaceRadius: 35,
                    sections: categoryExpenses.entries.toList().asMap().entries.map((mapEntry) {
                      final i = mapEntry.key;
                      final entry = mapEntry.value;
                      final isTouched = i == touchedIndex;
                      final fontSize = isTouched ? 14.0 : 12.0;
                      final radius = isTouched ? 45.0 : 40.0;
                      final percentage = (entry.value / _totalExpense * 100).toStringAsFixed(0);
                      
                      return PieChartSectionData(
                        color: _getCategoryColor(entry.key),
                        value: entry.value,
                        title: isTouched ? '${CurrencyHelper.symbol}${entry.value.toStringAsFixed(0)}' : '$percentage%',
                        radius: radius,
                        titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ৪. ট্রানজ্যাকশন লিস্ট
            Text(LanguageHelper.t('সাম্প্রতিক লেনদেন', 'Recent Transactions'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            ],
              ),
            ),
          ),
          if (_transactions.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_long, size: 60, color: Color(0xFF4F46E5)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        LanguageHelper.t('কোনো লেনদেন পাওয়া যায়নি', 'No transactions found'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        LanguageHelper.t('আপনার নতুন হিসাব যোগ করতে "+" বাটনে ক্লিক করুন', 'Click the "+" button to add a new record'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverList.builder(
                itemCount: _groupedKeys.length,
                itemBuilder: (context, index) {
                  String dateHeader = _groupedKeys[index];
                  List<Map<String, dynamic>> dayTransactions = _groupedTransactions[dateHeader]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: Text(
                          dateHeader,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleMedium?.color,
                          ),
                        ),
                      ),
                      ...dayTransactions.map((tx) {
                        final isIncome = tx[DatabaseHelper.columnType] == 'income';
                        final txId = tx[DatabaseHelper.columnId];

                        DateTime dateTime = DateTime.parse(tx[DatabaseHelper.columnDate]);
                        String formattedDate = DateFormat('dd MMM, yyyy').format(dateTime);
                        String formattedTime = DateFormat('hh:mm a').format(dateTime);

                        return Dismissible(
                          key: Key(txId.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.delete, color: Colors.white, size: 30),
                          ),
                          onDismissed: (direction) async {
                            await DatabaseHelper.instance.delete(txId);
                            _refreshData();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              onTap: () => _showTransactionDetails(tx, isIncome, formattedDate),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isIncome ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isIncome ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(tx[DatabaseHelper.columnTitle], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text('${tx[DatabaseHelper.columnCategory]} • $formattedTime', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ),
                              trailing: Text(
                                '${isIncome ? '+' : '-'} ${CurrencyHelper.symbol}${tx[DatabaseHelper.columnAmount]}',
                                style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          HapticFeedback.lightImpact();
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddTransactionScreen(),
          );
          _refreshData();
        },
        backgroundColor: const Color(0xFF4F46E5),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(LanguageHelper.t('নতুন', 'New'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMiniSummary(String title, double amount, IconData icon, Color color) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text('${CurrencyHelper.symbol} ${amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _StickyHeaderDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: child,
      ),
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}