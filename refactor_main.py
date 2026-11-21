import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add grouped transaction maps to State
content = content.replace(
    '  List<Map<String, dynamic>> _transactions = [];\n',
    '  List<Map<String, dynamic>> _transactions = [];\n  Map<String, List<Map<String, dynamic>>> _groupedTransactions = {};\n  List<String> _groupedKeys = [];\n'
)

# 2. Update _refreshData
refresh_data_replacement = '''  void _refreshData() async {
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
  }'''
content = re.sub(r'  void _refreshData\(\) async \{.*?\n  \}', refresh_data_replacement, content, flags=re.DOTALL)

# 3. Optimize List in build method
# Replace Builder and ListView.builder with SliverList.builder
list_target_pattern = r'Builder\(\s*builder: \(context\) \{\s*final groupedTransactions = _groupTransactionsByDate\(_transactions\);\s*final keys = groupedTransactions\.keys\.toList\(\);\s*return ListView\.builder\([^)]*\s*itemCount: keys\.length,\s*itemBuilder: \(context, index\) \{([^\}]+)\}\s*\);\s*\},\s*\)'
# Actually, the block is big. Let's just find the starting `_transactions.isEmpty` block up to `const SliverToBoxAdapter(child: SizedBox(height: 20)),`
old_list_code = '''            _transactions.isEmpty
                ? Center(
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
                  ).animate().fade(duration: 500.ms, delay: 300.ms).scale(begin: const Offset(0.8, 0.8))
                : Builder(
                    builder: (context) {
                      final groupedTransactions = _groupTransactionsByDate(_transactions);
                      final keys = groupedTransactions.keys.toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: keys.length,
                        itemBuilder: (context, index) {
                          String dateHeader = keys[index];
                          List<Map<String, dynamic>> dayTransactions = groupedTransactions[dateHeader]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                                child: Text(
                                  dateHeader,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              ...dayTransactions.map((tx) {
                                bool isIncome = tx[DatabaseHelper.columnType] == 'income';
                                String formattedTime = '১২:০০ PM';
                                String formattedDate = tx[DatabaseHelper.columnDate];
                                try {
                                  DateTime dt = DateTime.parse(tx[DatabaseHelper.columnDate]);
                                  formattedTime = DateFormat('hh:mm a').format(dt);
                                  formattedDate = DateFormat('dd MMM, yyyy').format(dt);
                                } catch (e) {
                                  // Fallback
                                }

                                int txId = tx[DatabaseHelper.columnId];

                                return Dismissible(
                                  key: Key(txId.toString()),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    margin: const EdgeInsets.only(bottom: 12),
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
                          ).animate().fade(duration: 400.ms, delay: (index * 100 + 300).ms).slideY(begin: 0.1, end: 0);
                        },
                      );
                    },
                  ),'''

new_list_code = '''            _transactions.isEmpty
                ? Center(
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
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          ...dayTransactions.map((tx) {
                            bool isIncome = tx[DatabaseHelper.columnType] == 'income';
                            String formattedTime = '১২:০০ PM';
                            String formattedDate = tx[DatabaseHelper.columnDate];
                            try {
                              DateTime dt = DateTime.parse(tx[DatabaseHelper.columnDate]);
                              formattedTime = DateFormat('hh:mm a').format(dt);
                              formattedDate = DateFormat('dd MMM, yyyy').format(dt);
                            } catch (e) {}

                            int txId = tx[DatabaseHelper.columnId];

                            return Dismissible(
                              key: Key(txId.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 12),
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
                  ),'''

content = content.replace(old_list_code, new_list_code)

# 4. Remove all flutter_animate calls in main.dart
content = re.sub(r'\.animate\(\)\.fade\(duration: \d+.*?ms\)\.slideY\(begin: [0-9.]+, end: [0-9.]+\)', '', content)
content = re.sub(r'\.animate\(\)\.fade\(delay: \d+.*?ms\)', '', content)
content = re.sub(r'\.animate\(\)\.fade\(duration: \d+.*?ms, delay: \d+.*?ms\)\.scale\(begin: const Offset\([0-9.]+, [0-9.]+\)\)', '', content)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Refactored main.dart successfully.')
