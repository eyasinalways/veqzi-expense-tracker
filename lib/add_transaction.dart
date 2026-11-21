import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'currency_helper.dart';
import 'database_helper.dart';
import 'language_helper.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedType = 'expense';
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  bool _isScanning = false; // স্ক্যানিং চলাকালীন লোডিং দেখানোর জন্য

  final List<String> _categories = ['Food', 'Transport', 'Rent', 'Salary', 'Others'];
  final Map<String, IconData> _categoryIcons = {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Rent': Icons.home,
    'Salary': Icons.account_balance_wallet,
    'Others': Icons.category,
  };

  // Pass your Gemini API key via: flutter run --dart-define=GEMINI_API_KEY=your_key
  final String apiKey = const String.fromEnvironment('GEMINI_API_KEY');

  // জেমিনি এআই দিয়ে রসিদ স্ক্যান করার ম্যাজিক ফাংশন
  Future<void> _scanReceipt() async {
    final picker = ImagePicker();
    // ক্যামেরা দিয়ে ছবি তোলার অপশন
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return; // ছবি না তুললে ফিরে যাবে

    setState(() {
      _isScanning = true;
    });

    try {
      // জেমিনির ভিশন মডেল কল করা
      final model = GenerativeModel(model: 'gemini-3.8-flash', apiKey: apiKey);
      final bytes = await File(image.path).readAsBytes();

      // এআই-কে নির্দেশ দেওয়া হচ্ছে কীভাবে ডেটা দিতে হবে
      final prompt = TextPart("Extract the main store/item name and the total amount from this receipt. Return ONLY in this exact format: Name|Amount (for example: Super Shop|1500). Do not add any extra text or currency symbols.");
      final imagePart = DataPart('image/jpeg', bytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final result = response.text?.trim() ?? '';

      // এআই-এর দেওয়া ডেটা আলাদা করে ফর্মে বসানো
      if (result.contains('|')) {
        final parts = result.split('|');
        setState(() {
          _titleController.text = parts[0].trim();
          _amountController.text = parts[1].trim();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LanguageHelper.t('রসিদ স্ক্যান সফল হয়েছে! ফর্মে বসে গেছে।', 'Receipt scanned successfully! Form filled.'))));
        }
      } else {
        throw Exception(LanguageHelper.t("রসিদ পড়া যায়নি", "Couldn't read receipt"));
      }
    } catch (e) {
      if (mounted) {
        // এই লাইনটি আসল সমস্যাটি স্ক্রিনে মেসেজ আকারে দেখাবে
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${LanguageHelper.t('এরর: ', 'Error: ')}$e')));
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _presentDatePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _saveData() async {
    String title = _titleController.text.trim();
    String amountText = _amountController.text.trim();
    String note = _noteController.text.trim();

    if (title.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LanguageHelper.t('অনুগ্রহ করে নাম ও টাকার পরিমাণ দিন!', 'Please enter name and amount!'))));
      return;
    }

    double? amount = double.tryParse(amountText);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LanguageHelper.t('টাকার পরিমাণ সঠিক নয়!', 'Invalid amount!'))));
      return;
    }

    try {
      Map<String, dynamic> row = {
        DatabaseHelper.columnTitle: title,
        DatabaseHelper.columnAmount: amount,
        DatabaseHelper.columnDate: _selectedDate.toString(),
        DatabaseHelper.columnCategory: _selectedCategory,
        DatabaseHelper.columnType: _selectedType,
        DatabaseHelper.columnNote: note,
      };

      await DatabaseHelper.instance.insert(row);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LanguageHelper.t('ডেটাবেস এরর!', 'Database Error!'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar for bottom sheet
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(LanguageHelper.t('নতুন হিসাব', 'Add Transaction'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // এআই স্ক্যান বাটন
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _scanReceipt,
              icon: _isScanning
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.document_scanner_outlined),
              label: Text(_isScanning ? LanguageHelper.t('রসিদ পড়া হচ্ছে...', 'Reading receipt...') : LanguageHelper.t('এআই দিয়ে রসিদ স্ক্যান করুন', 'Scan receipt with AI')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                foregroundColor: const Color(0xFF4F46E5),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                minimumSize: const Size(double.infinity, 55),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: LanguageHelper.t('নাম (যেমন: বাজার)', 'Name (e.g., Groceries)'),
                prefixIcon: const Icon(Icons.edit_note),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '${LanguageHelper.t('পরিমাণ', 'Amount')} (${CurrencyHelper.symbol})',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: LanguageHelper.t('নোট বা বিস্তারিত (ঐচ্ছিক)', 'Note or Details (Optional)'),
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedType = 'income');
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedType == 'income' ? Colors.green.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _selectedType == 'income' ? Colors.green : Colors.grey.withValues(alpha: 0.3),
                          width: _selectedType == 'income' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_downward, color: _selectedType == 'income' ? Colors.green : Colors.grey),
                          const SizedBox(width: 8),
                          Text(LanguageHelper.t('আয়', 'Income'), style: TextStyle(
                            color: _selectedType == 'income' ? Colors.green : Colors.grey,
                            fontWeight: _selectedType == 'income' ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedType = 'expense');
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedType == 'expense' ? Colors.red.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _selectedType == 'expense' ? Colors.red : Colors.grey.withValues(alpha: 0.3),
                          width: _selectedType == 'expense' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_upward, color: _selectedType == 'expense' ? Colors.red : Colors.grey),
                          const SizedBox(width: 8),
                          Text(LanguageHelper.t('ব্যয়', 'Expense'), style: TextStyle(
                            color: _selectedType == 'expense' ? Colors.red : Colors.grey,
                            fontWeight: _selectedType == 'expense' ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(LanguageHelper.t('ক্যাটাগরি নির্বাচন করুন', 'Select Category'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = cat);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4F46E5) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                      ] : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_categoryIcons[cat] ?? Icons.category, size: 18, color: isSelected ? Colors.white : Colors.grey),
                        const SizedBox(width: 6),
                        Text(cat, style: TextStyle(
                          color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${LanguageHelper.t('তারিখ: ', 'Date: ')}${DateFormat('dd MMM, yyyy').format(_selectedDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  TextButton(
                    onPressed: _presentDatePicker,
                    child: Text(LanguageHelper.t('পরিবর্তন', 'Change'), style: const TextStyle(color: Color(0xFF4F46E5))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _saveData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                minimumSize: const Size(double.infinity, 55),
              ),
              child: Text(LanguageHelper.t('সেভ করুন', 'Save'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}