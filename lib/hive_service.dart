import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spendmind/models.dart';

class HiveService extends ChangeNotifier {
  static const String _settingsBoxName = 'settings_box';
  static const String _transactionsBoxName = 'transactions_box';
  static const String _budgetsBoxName = 'budgets_box';
  static const String _chatBoxName = 'chat_box';

  late Box _settingsBox;
  late Box _transactionsBox;
  late Box _budgetsBox;
  late Box _chatBox;

  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<ChatMessage> _chatMessages = [];

  List<Transaction> get transactions => _transactions;
  List<Budget> get budgets => _budgets;
  List<ChatMessage> get chatMessages => _chatMessages;

  // Initialize Hive and open all boxes
  Future<void> init() async {
    await Hive.initFlutter();
    
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _transactionsBox = await Hive.openBox(_transactionsBoxName);
    _budgetsBox = await Hive.openBox(_budgetsBoxName);
    _chatBox = await Hive.openBox(_chatBoxName);

    _loadData();
  }

  void _loadData() {
    // Load Transactions
    _transactions = _transactionsBox.values
        .map((e) => Transaction.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first

    // Load Budgets
    _budgets = _budgetsBox.values
        .map((e) => Budget.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    // If budgets are empty, initialize default budgets
    if (_budgets.isEmpty) {
      _initializeDefaultBudgets();
    } else {
      _recalculateBudgetSpentValues();
    }

    // Load Chats
    _chatMessages = _chatBox.values
        .map((e) => ChatMessage.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp)); // Chronological order
  }

  // --- SETTINGS HACKS ---
  double get monthlyIncome => _settingsBox.get('monthly_income', defaultValue: 50000.0);
  Future<void> setMonthlyIncome(double value) async {
    await _settingsBox.put('monthly_income', value);
    notifyListeners();
  }

  double get savingsGoal => _settingsBox.get('savings_goal', defaultValue: 15000.0);
  Future<void> setSavingsGoal(double value) async {
    await _settingsBox.put('savings_goal', value);
    notifyListeners();
  }

  String get geminiApiKey => _settingsBox.get('gemini_api_key', defaultValue: '');
  Future<void> setGeminiApiKey(String value) async {
    await _settingsBox.put('gemini_api_key', value);
    notifyListeners();
  }

  // --- DEVELOPER MODE SETTINGS ---
  String get userEmail => _settingsBox.get('user_email', defaultValue: '');
  Future<void> setUserEmail(String value) async {
    await _settingsBox.put('user_email', value);
    notifyListeners();
  }

  List<String> get developerEmails {
    final list = _settingsBox.get('developer_emails', defaultValue: ['gamerchetan323@gmail.com']);
    return List<String>.from(list);
  }

  Future<void> addDeveloperEmail(String email) async {
    final list = developerEmails;
    if (!list.contains(email)) {
      list.add(email);
      await _settingsBox.put('developer_emails', list);
      notifyListeners();
    }
  }

  Future<void> removeDeveloperEmail(String email) async {
    final list = developerEmails;
    if (list.contains(email)) {
      list.remove(email);
      await _settingsBox.put('developer_emails', list);
      notifyListeners();
    }
  }

  bool get isDeveloper => developerEmails.contains(userEmail);

  bool get includeTestDataInAnalytics => _settingsBox.get('include_test_data', defaultValue: false);
  Future<void> setIncludeTestDataInAnalytics(bool value) async {
    await _settingsBox.put('include_test_data', value);
    _recalculateBudgetSpentValues();
    notifyListeners();
  }

  Future<void> clearTestData() async {
    final keysToDelete = [];
    for (var key in _transactionsBox.keys) {
      final txMap = _transactionsBox.get(key);
      if (txMap != null) {
        final tx = Transaction.fromMap(Map<String, dynamic>.from(txMap));
        if (tx.isTest) {
          keysToDelete.add(key);
        }
      }
    }
    for (var key in keysToDelete) {
      await _transactionsBox.delete(key);
    }
    _loadData();
    notifyListeners();
  }

  // --- TRANSACTIONS ---
  Future<void> saveTransaction(Transaction tx) async {
    await _transactionsBox.put(tx.id, tx.toMap());
    _loadData();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionsBox.delete(id);
    _loadData();
    notifyListeners();
  }

  Future<void> clearTransactions() async {
    await _transactionsBox.clear();
    _loadData();
    notifyListeners();
  }

  // --- BUDGETS ---
  void _initializeDefaultBudgets() {
    final defaultCategories = [
      'Food',
      'Fuel',
      'Shopping',
      'Bills',
      'Travel',
      'Entertainment',
      'Subscriptions',
      'Healthcare',
      'Others'
    ];

    for (var category in defaultCategories) {
      final b = Budget(category: category, limit: 5000.0);
      _budgetsBox.put(category, b.toMap());
    }
    _loadData();
  }

  Future<void> saveBudget(Budget budget) async {
    await _budgetsBox.put(budget.category, budget.toMap());
    _loadData();
    notifyListeners();
  }

  void _recalculateBudgetSpentValues() {
    // Reset spent values
    final updatedBudgets = <String, Budget>{};
    for (var b in _budgets) {
      updatedBudgets[b.category] = b.copyWith(spent: 0.0);
    }

    final includeTest = isDeveloper && includeTestDataInAnalytics;

    // Accumulate from transactions (only expenses)
    for (var tx in _transactions) {
      if (tx.isTest && !includeTest) continue;
      if (tx.type == 'expense') {
        final category = tx.category;
        final currentBudget = updatedBudgets[category];
        if (currentBudget != null) {
          updatedBudgets[category] = currentBudget.copyWith(
            spent: currentBudget.spent + tx.amount,
          );
        } else {
          // If a custom category exists in transaction, add it dynamically or map to Others
          final others = updatedBudgets['Others'];
          if (others != null) {
            updatedBudgets['Others'] = others.copyWith(
              spent: others.spent + tx.amount,
            );
          }
        }
      }
    }

    // Update in-memory budgets
    _budgets = updatedBudgets.values.toList();
  }

  // --- CHAT HISTORY ---
  Future<void> saveChatMessage(ChatMessage message) async {
    await _chatBox.put(message.id, message.toMap());
    _loadData();
    notifyListeners();
  }

  Future<void> clearChatHistory() async {
    await _chatBox.clear();
    _loadData();
    notifyListeners();
  }
}
