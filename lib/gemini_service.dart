import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:spendmind/models.dart';

class GeminiService {
  final String apiKey;
  GenerativeModel? _model;

  GeminiService({required this.apiKey}) {
    if (apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
    }
  }

  bool get isConfigured => _model != null;

  /// AI Categorizer Fallback - parses SMS text that local regex couldn't resolve
  Future<Map<String, dynamic>?> categorizeTransactionFallback(String rawText) async {
    if (!isConfigured) {
      return null;
    }

    final prompt = '''
    Analyze this raw transaction SMS/notification text:
    "$rawText"
    
    Extract the following details and return ONLY a valid JSON object. Do not include markdown code block formatting.
    Fields to extract:
    - "title": Clean merchant or recipient name (e.g. Swiggy, Netflix, HDFC, SBI credit card, John Doe). Capitalize words.
    - "amount": Double representing transaction value.
    - "category": Categorize into one of these: "Food", "Fuel", "Shopping", "Bills", "Travel", "Entertainment", "Subscriptions", "Healthcare", "Others".
    - "type": Either "expense" or "income".
    
    Example output format:
    {"title": "Swiggy", "amount": 250.0, "category": "Food", "type": "expense"}
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final text = response.text ?? '';
      
      // Clean possible JSON markers
      final cleanJson = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      
      return jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e) {
      print('Gemini categorizer error: $e');
      return null;
    }
  }

  /// AI Financial Coach Chat - responds to user query with financial context
  Future<String> getAICoachResponse({
    required List<ChatMessage> chatHistory,
    required String userInput,
    required List<Transaction> transactions,
    required double monthlyIncome,
    required double savingsGoal,
  }) async {
    if (!isConfigured) {
      return "Gemini API Key is not set. Please go to Settings to add your key and unlock the AI Coach!";
    }

    // Prepare contextual financial stats to include in prompt
    double totalExpenses = 0.0;
    double totalIncome = 0.0;
    Map<String, double> categorySpending = {};

    for (var tx in transactions) {
      if (tx.type == 'expense') {
        totalExpenses += tx.amount;
        categorySpending[tx.category] = (categorySpending[tx.category] ?? 0.0) + tx.amount;
      } else {
        totalIncome += tx.amount;
      }
    }

    final formattedSpending = categorySpending.entries
        .map((e) => "- ${e.key}: ₹${e.value.toStringAsFixed(2)}")
        .join('\n');

    final systemPrompt = '''
    You are SpendMind's AI Financial Coach, a friendly, encouraging, and highly competent personal finance expert.
    
    Here is the user's current monthly financial profile:
    - Monthly Income: ₹${monthlyIncome.toStringAsFixed(2)}
    - Savings Goal: ₹${savingsGoal.toStringAsFixed(2)}
    - Total Tracked Income this month: ₹${totalIncome.toStringAsFixed(2)}
    - Total Tracked Expenses this month: ₹${totalExpenses.toStringAsFixed(2)}
    - Category Spending:
    $formattedSpending
    
    Guidelines:
    1. Provide action-oriented, personalized, and concise advice.
    2. Suggest concrete savings tips or identify warnings (e.g. if shopping or entertainment exceeds limits).
    3. Format responses cleanly using markdown (bolding, lists, and tables). Keep responses compact and professional.
    4. If the user asks about specific items in their transaction history, review the profile details and offer precise guidance.
    ''';

    try {
      // Build conversation history contents
      final contents = <Content>[
        Content.text(systemPrompt),
      ];

      // Add recent chat messages
      final recentHistory = chatHistory.length > 10 
          ? chatHistory.sublist(chatHistory.length - 10) 
          : chatHistory;

      for (var msg in recentHistory) {
        if (msg.sender == 'user') {
          contents.add(Content.text("User: ${msg.message}"));
        } else {
          contents.add(Content.text("Coach: ${msg.message}"));
        }
      }

      // Add current user input
      contents.add(Content.text("User query: $userInput"));

      final response = await _model!.generateContent(contents);
      return response.text ?? "I'm sorry, I couldn't generate a response.";
    } catch (e) {
      return "Error: Could not connect to Gemini. Please check your API key or network. Details: $e";
    }
  }

  /// Spending Simulator Engine - models savings rate, months to goal, trajectory based on scenario
  Future<Map<String, dynamic>> getSpendingSimulationProjections({
    required double currentIncome,
    required double currentSavingsGoal,
    required Map<String, double> currentCategoryBudgets,
    required Map<String, double> simulatedBudgetChanges,
    required String scenarioText,
  }) async {
    // Generate a default mock fallback if Gemini is not configured
    final mockFallback = _generateMockSimulation(
      currentIncome, 
      currentSavingsGoal, 
      currentCategoryBudgets, 
      simulatedBudgetChanges,
      scenarioText
    );

    if (!isConfigured) {
      return mockFallback;
    }

    final prompt = '''
    Act as a financial projection calculator. Analyze the user's financial profile and apply their simulated adjustments.
    
    Current Financial Profile:
    - Monthly Income: ₹$currentIncome
    - Target Savings Goal: ₹$currentSavingsGoal
    - Current Monthly Budgets: ${jsonEncode(currentCategoryBudgets)}
    
    Simulated Changes:
    - Budget Adjustments: ${jsonEncode(simulatedBudgetChanges)}
    - Description of Scenario: "$scenarioText"
    
    Estimate a 12-month projections trajectory and return a strictly valid JSON response (no markdown markers).
    The JSON structure must match exactly:
    {
      "projectedSavingsRate": double (as a percent value, e.g. 24.5),
      "monthsToGoal": int (how many months to save up ₹$currentSavingsGoal),
      "recommendations": [
        "string containing specific advice 1",
        "string containing specific advice 2",
        "string containing specific advice 3"
      ],
      "savingsTrajectory": [
        {"month": "M1", "current": double, "simulated": double},
        {"month": "M2", "current": double, "simulated": double},
        ...
        {"month": "M12", "current": double, "simulated": double}
      ]
    }
    
    Ensure current savings grows by (monthlyIncome - sum(currentBudgets)) each month.
    Ensure simulated savings grows by (monthlyIncome - sum(currentBudgets with adjustments)) each month.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final text = response.text ?? '';
      
      final cleanJson = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
          
      return jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e) {
      print('Gemini simulator error: $e');
      return mockFallback;
    }
  }

  Map<String, dynamic> _generateMockSimulation(
    double income,
    double savingsGoal,
    Map<String, double> budgets,
    Map<String, double> changes,
    String scenarioText,
  ) {
    // Basic local calculation for offline/non-AI mode
    double currentSpent = budgets.values.fold(0.0, (sum, item) => sum + item);
    double adjustedSpent = currentSpent;
    
    changes.forEach((category, adjustment) {
      adjustedSpent += adjustment;
    });

    double currentMonthlySavings = income - currentSpent;
    double simulatedMonthlySavings = income - adjustedSpent;

    if (currentMonthlySavings < 0) currentMonthlySavings = 0;
    if (simulatedMonthlySavings < 0) simulatedMonthlySavings = 0;

    double simulatedSavingsRate = income > 0 ? (simulatedMonthlySavings / income) * 100 : 0.0;

    int monthsToGoal = simulatedMonthlySavings > 0 
        ? (savingsGoal / simulatedMonthlySavings).ceil() 
        : 999;

    List<Map<String, dynamic>> trajectory = [];
    double currentTotal = 0.0;
    double simulatedTotal = 0.0;

    final months = ['Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May'];
    for (int i = 0; i < 12; i++) {
      currentTotal += currentMonthlySavings;
      simulatedTotal += simulatedMonthlySavings;
      trajectory.add({
        'month': months[i],
        'current': currentTotal,
        'simulated': simulatedTotal,
      });
    }

    return {
      'projectedSavingsRate': double.parse(simulatedSavingsRate.toStringAsFixed(1)),
      'monthsToGoal': monthsToGoal,
      'recommendations': [
        'Monthly budget changed: Total expenses are now ₹${adjustedSpent.toStringAsFixed(0)}.',
        simulatedMonthlySavings < currentMonthlySavings 
            ? 'Warning: This scenario reduces your monthly savings by ₹${(currentMonthlySavings - simulatedMonthlySavings).toStringAsFixed(0)}.'
            : 'Excellent: This scenario increases your monthly savings by ₹${(simulatedMonthlySavings - currentMonthlySavings).toStringAsFixed(0)}.',
        'Consider setting an active budget cap on highly variable items like Shopping and Food to protect your savings goal.'
      ],
      'savingsTrajectory': trajectory,
    };
  }
}
