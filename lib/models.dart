class Transaction {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String type;
  final DateTime timestamp;
  final String source;
  final String rawText;
  final bool isParsedSuccessfully;
  final String status;
  final String note;
  final bool isTest;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.timestamp,
    required this.source,
    required this.rawText,
    required this.isParsedSuccessfully,
    required this.status,
    this.note = '',
    this.isTest = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'rawText': rawText,
      'isParsedSuccessfully': isParsedSuccessfully,
      'status': status,
      'note': note,
      'isTest': isTest,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Unknown',
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] ?? 'Others',
      type: map['type'] ?? 'expense',
      timestamp: DateTime.parse(map['timestamp']),
      source: map['source'] ?? '',
      rawText: map['rawText'] ?? '',
      isParsedSuccessfully: map['isParsedSuccessfully'] ?? false,
      status: map['status'] ?? 'pending',
      note: map['note'] ?? '',
      isTest: map['isTest'] ?? false,
    );
  }

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    String? type,
    DateTime? timestamp,
    String? source,
    String? rawText,
    bool? isParsedSuccessfully,
    String? status,
    String? note,
    bool? isTest,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      rawText: rawText ?? this.rawText,
      isParsedSuccessfully: isParsedSuccessfully ?? this.isParsedSuccessfully,
      status: status ?? this.status,
      note: note ?? this.note,
      isTest: isTest ?? this.isTest,
    );
  }
}

class BudgetModel {
  final String category;
  final double limitAmount;
  final double spentAmount;

  BudgetModel({
    required this.category,
    required this.limitAmount,
    this.spentAmount = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'limitAmount': limitAmount,
      'spentAmount': spentAmount,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      category: map['category'] ?? 'General',
      limitAmount: (map['limitAmount'] as num).toDouble(),
      spentAmount: (map['spentAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  BudgetModel copyWith({
    String? category,
    double? limitAmount,
    double? spentAmount,
  }) {
    return BudgetModel(
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      spentAmount: spentAmount ?? this.spentAmount,
    );
  }
}

class Budget {
  final String category;
  final double limit;
  final double spent;

  Budget({
    required this.category,
    required this.limit,
    this.spent = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'limit': limit,
      'spent': spent,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      category: map['category'] ?? '',
      limit: (map['limit'] as num?)?.toDouble() ?? 0.0,
      spent: (map['spent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Budget copyWith({
    String? category,
    double? limit,
    double? spent,
  }) {
    return Budget(
      category: category ?? this.category,
      limit: limit ?? this.limit,
      spent: spent ?? this.spent,
    );
  }
}

class ChatMessage {
  final String id;
  final String sender;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      sender: map['sender'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
    );
  }
}
