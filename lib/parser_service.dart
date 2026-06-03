import 'package:spendmind/models.dart';

class SMSParserService {
  // Dictionary of known merchants and their categories
  static const Map<String, String> _merchantCategories = {
    // Food
    'swiggy': 'Food',
    'zomato': 'Food',
    'mcdonald': 'Food',
    'kfc': 'Food',
    'starbucks': 'Food',
    'domino': 'Food',
    'pizza': 'Food',
    'restaurant': 'Food',
    'cafe': 'Food',
    'burger': 'Food',
    'dhaba': 'Food',
    'bake': 'Food',
    'tea': 'Food',
    'chai': 'Food',

    // Groceries & Shopping
    'amazon': 'Shopping',
    'flipkart': 'Shopping',
    'myntra': 'Shopping',
    'ajio': 'Shopping',
    'zara': 'Shopping',
    'h&m': 'Shopping',
    'nykaa': 'Shopping',
    'blinkit': 'Shopping',
    'instamart': 'Shopping',
    'zepto': 'Shopping',
    'dmart': 'Shopping',
    'bigbasket': 'Shopping',
    'grocery': 'Shopping',
    'mart': 'Shopping',
    'supermarket': 'Shopping',
    'retail': 'Shopping',

    // Fuel
    'hpcl': 'Fuel',
    'bpcl': 'Fuel',
    'iocl': 'Fuel',
    'shell': 'Fuel',
    'petrol': 'Fuel',
    'fuel': 'Fuel',
    'cng': 'Fuel',
    'pump': 'Fuel',

    // Bills & Utilities
    'electricity': 'Bills',
    'water': 'Bills',
    'jio': 'Bills',
    'airtel': 'Bills',
    'vi ': 'Bills',
    'idea': 'Bills',
    'bsnl': 'Bills',
    'act fibernet': 'Bills',
    'broadband': 'Bills',
    'dth': 'Bills',
    'recharge': 'Bills',
    'billpay': 'Bills',

    // Travel
    'uber': 'Travel',
    'ola': 'Travel',
    'rapido': 'Travel',
    'irctc': 'Travel',
    'metro': 'Travel',
    'rail': 'Travel',
    'cab': 'Travel',
    'auto': 'Travel',
    'flight': 'Travel',
    'makemytrip': 'Travel',
    'goibibo': 'Travel',
    'redbus': 'Travel',

    // Subscriptions
    'netflix': 'Subscriptions',
    'spotify': 'Subscriptions',
    'youtube premium': 'Subscriptions',
    'amazon prime': 'Subscriptions',
    'prime video': 'Subscriptions',
    'disney': 'Subscriptions',
    'hotstar': 'Subscriptions',
    'sony liv': 'Subscriptions',
    'apple.com': 'Subscriptions',
    'icloud': 'Subscriptions',

    // Entertainment
    'bookmyshow': 'Entertainment',
    'pvr': 'Entertainment',
    'inox': 'Entertainment',
    'movies': 'Entertainment',
    'steam': 'Entertainment',
    'nintendo': 'Entertainment',
    'playstation': 'Entertainment',
    'gaming': 'Entertainment',
    'club': 'Entertainment',
    'pub': 'Entertainment',

    // Healthcare
    'apollo': 'Healthcare',
    '1mg': 'Healthcare',
    'pharmacy': 'Healthcare',
    'medical': 'Healthcare',
    'hospital': 'Healthcare',
    'clinic': 'Healthcare',
    'dentist': 'Healthcare',
    'doctor': 'Healthcare',
    'pharma': 'Healthcare',
  };

  /// Main entry point to parse a raw string text from SMS/Notification
  static Transaction? parseMessage(String rawText, String sourceAppName) {
    if (rawText.isEmpty) return null;

    final String text = rawText.toLowerCase();

    // 1. Determine type (income vs expense)
    String type = 'expense';
    bool isCredit = false;

    if (text.contains('credited') ||
        text.contains('received') ||
        text.contains('refunded') ||
        text.contains('deposited') ||
        text.contains('added to') ||
        text.contains('received from') ||
        (RegExp(r'\bcr\b').hasMatch(text) && !text.contains('credit card'))) {
      type = 'income';
      isCredit = true;
    }

    // 2. Extract Amount
    double amount = 0.0;
    bool amountFound = false;

    // RegEx patterns for amount extraction
    final List<RegExp> amountRegexes = [
      RegExp(r'(?:inr|rs|rs\.|inr\.)\s*([\d,]+\.?\d*)'),
      RegExp(r'debited\s*(?:by|for)?\s*(?:inr|rs|rs\.)\s*([\d,]+\.?\d*)'),
      RegExp(r'credited\s*(?:with|for)?\s*(?:inr|rs|rs\.)\s*([\d,]+\.?\d*)'),
      RegExp(r'paid\s*(?:inr|rs|rs\.)\s*([\d,]+\.?\d*)'),
      RegExp(r'sent\s*(?:inr|rs|rs\.)\s*([\d,]+\.?\d*)'),
      RegExp(r'([\d,]+\.?\d*)\s*(?:debited|credited)'),
    ];

    for (final regex in amountRegexes) {
      final match = regex.firstMatch(text);
      if (match != null) {
        final amountString = match.group(1)?.replaceAll(',', '');
        if (amountString != null) {
          final parsed = double.tryParse(amountString);
          if (parsed != null && parsed > 0) {
            amount = parsed;
            amountFound = true;
            break;
          }
        }
      }
    }

    // 3. Extract Merchant/Receiver/Sender Title
    String title = '';
    
    // Attempt to extract merchant name based on keywords
    final List<RegExp> merchantRegexes = [
      RegExp(r'(?:to|at|info|towards|for)\s+([a-z0-9\s@\.\-_]{3,25})'),
      RegExp(r'(?:paid|sent)\s+to\s+([a-z0-9\s@\.\-_]{3,25})'),
      RegExp(r'merchant\s*:\s*([a-z0-9\s@\.\-_]{3,25})'),
      RegExp(r'vpa\s+([a-z0-9\s@\.\-_]{3,25})'),
      RegExp(r'link\s+to\s+([a-z0-9\s@\.\-_]{3,25})'),
    ];

    for (final regex in merchantRegexes) {
      final match = regex.firstMatch(text);
      if (match != null) {
        final rawTitle = match.group(1)?.trim();
        if (rawTitle != null && rawTitle.isNotEmpty) {
          title = _cleanMerchantTitle(rawTitle);
          break;
        }
      }
    }

    if (title.isEmpty) {
      if (isCredit) {
        title = 'Incoming Transfer';
      } else {
        title = 'Debit Transaction';
      }
    }

    // 4. Auto Categorize using local dictionary lookup
    String category = isCredit ? 'Others' : _categorizeMerchant(title);

    // If it's a known subscription merchant, ensure category is 'Subscriptions'
    if (!isCredit) {
      for (final merchant in _merchantCategories.keys) {
        if (title.toLowerCase().contains(merchant) && _merchantCategories[merchant] == 'Subscriptions') {
          category = 'Subscriptions';
          break;
        }
      }
    }

    // 5. Generate transaction object
    if (!amountFound || amount == 0.0) return null;

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final now = DateTime.now();

    final isParsed = title.isNotEmpty && title != 'Debit Transaction' && title != 'Incoming Transfer';

    return Transaction(
      id: id,
      title: title,
      amount: amount,
      category: category,
      type: type,
      timestamp: now,
      source: sourceAppName,
      rawText: rawText,
      isParsedSuccessfully: isParsed,
      status: isParsed ? 'reviewed' : 'pending',
    );
  }

  static String _cleanMerchantTitle(String title) {
    var clean = title.toLowerCase();

    // Strip common noise phrases and anything trailing them
    clean = clean.replaceAll(RegExp(r'(?:ref|vpa|ref\s*no|txn|on\s+|date|using|avl|bal|subscription|card\s+|ending\s+|via\s+|a/c\s+).*'), '');

    // Strip trailing punctuation and spaces
    clean = clean.trim().replaceAll(RegExp(r'[\.\-\_\s]+$'), '');

    // Capitalize words
    if (clean.isEmpty) return '';
    return clean.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  static String _categorizeMerchant(String merchantName) {
    final nameLower = merchantName.toLowerCase();
    for (final merchant in _merchantCategories.keys) {
      if (nameLower.contains(merchant)) {
        return _merchantCategories[merchant]!;
      }
    }
    return 'Others';
  }
}
