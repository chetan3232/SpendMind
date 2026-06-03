import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'hive_service.dart';
import 'models.dart';
import 'gemini_service.dart';
import 'theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isResolvingAi = false;

  void _showReviewBottomSheet(Transaction tx) {
    final titleController = TextEditingController(text: tx.title);
    final amountController = TextEditingController(text: tx.amount.toStringAsFixed(0));
    String selectedCategory = tx.category == 'Others' ? 'Food' : tx.category;
    String selectedType = tx.type;

    final List<String> categories = [
      'Food', 'Fuel', 'Shopping', 'Bills', 'Travel', 'Entertainment', 'Subscriptions', 'Healthcare', 'Others'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Review Tracked Transaction',
                          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        if (!_isResolvingAi)
                          TextButton.icon(
                            onPressed: () async {
                              setModalState(() => _isResolvingAi = true);
                              final hive = Provider.of<HiveService>(context, listen: false);
                              final gemini = GeminiService(apiKey: hive.geminiApiKey);
                              
                              final resolved = await gemini.categorizeTransactionFallback(tx.rawText);
                              if (resolved != null) {
                                titleController.text = resolved['title'] ?? titleController.text;
                                amountController.text = (resolved['amount'] as num?)?.toStringAsFixed(0) ?? amountController.text;
                                if (categories.contains(resolved['category'])) {
                                  selectedCategory = resolved['category'];
                                }
                                if (resolved['type'] == 'expense' || resolved['type'] == 'income') {
                                  selectedType = resolved['type']!;
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('AI categorization failed or API key not set.')),
                                  );
                                }
                              }
                              setModalState(() => _isResolvingAi = false);
                            },
                            icon: const Icon(Icons.psychology, size: 16, color: AppTheme.vibrantPurple),
                            label: const Text('AI Resolve', style: TextStyle(color: AppTheme.vibrantPurple, fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('RAW CAPTURED TEXT:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(tx.rawText, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Forms
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => selectedType = 'expense'),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedType == 'expense' ? AppTheme.coralRed.withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: selectedType == 'expense' ? AppTheme.coralRed : Colors.white.withValues(alpha: 0.05)),
                              ),
                              child: Text('Expense', style: TextStyle(color: selectedType == 'expense' ? AppTheme.coralRed : AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => selectedType = 'income'),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedType == 'income' ? AppTheme.emeraldGreen.withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: selectedType == 'income' ? AppTheme.emeraldGreen : Colors.white.withValues(alpha: 0.05)),
                              ),
                              child: Text('Income', style: TextStyle(color: selectedType == 'income' ? AppTheme.emeraldGreen : AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      decoration: _getInputDecoration('Merchant Name', Icons.title),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: amountController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      keyboardType: TextInputType.number,
                      decoration: _getInputDecoration('Amount (₹)', Icons.currency_rupee),
                    ),
                    const SizedBox(height: 15),

                    if (selectedType == 'expense') ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        dropdownColor: AppTheme.cardColor,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        decoration: _getInputDecoration('Category', Icons.grid_view),
                        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (_isResolvingAi)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: CircularProgressIndicator(color: AppTheme.vibrantPurple),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Provider.of<HiveService>(context, listen: false).deleteTransaction(tx.id);
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.coralRed),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Ignore / Delete', style: TextStyle(color: AppTheme.coralRed, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final title = titleController.text.trim();
                                final amount = double.tryParse(amountController.text) ?? tx.amount;
                                if (title.isEmpty) return;

                                final updated = tx.copyWith(
                                  title: title,
                                  amount: amount,
                                  category: selectedType == 'income' ? 'Others' : selectedCategory,
                                  type: selectedType,
                                  status: 'reviewed',
                                  isParsedSuccessfully: true,
                                );

                                Provider.of<HiveService>(context, listen: false).saveTransaction(updated);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.vibrantPurple,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Confirm Parse', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _getInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textSecondary),
      prefixIcon: Icon(icon, color: AppTheme.vibrantPurple, size: 20),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.2),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.vibrantPurple),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Consumer<HiveService>(
            builder: (context, hive, child) {
              final includeTest = hive.isDeveloper && hive.includeTestDataInAnalytics;
              final transactions = hive.transactions.where((tx) => !tx.isTest || includeTest).toList();
              
              // Totals calculations
              double totalSpent = 0.0;
              Map<String, double> categoryDistribution = {};
              final pendingReviews = <Transaction>[];

              for (var tx in transactions) {
                if (tx.status == 'pending' || !tx.isParsedSuccessfully) {
                  pendingReviews.add(tx);
                }
                
                if (tx.type == 'expense') {
                  totalSpent += tx.amount;
                  categoryDistribution[tx.category] = (categoryDistribution[tx.category] ?? 0.0) + tx.amount;
                }
              }

              final income = hive.monthlyIncome;
              final savingsGoal = hive.savingsGoal;
              final currentSavings = income - totalSpent;
              
              double savingsPercentage = savingsGoal > 0 
                  ? (currentSavings > 0 ? (currentSavings / savingsGoal) : 0.0)
                  : 0.0;
              if (savingsPercentage > 1.0) savingsPercentage = 1.0;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header greeting
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Welcome to', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            Text(
                              'SpendMind',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                          ],
                        ),
                        // Mini Settings Avatar / Test Mode Badge
                        Row(
                          children: [
                            if (hive.isDeveloper) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.coralRed.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.coralRed, width: 0.8),
                                ),
                                child: const Text(
                                  'TEST MODE',
                                  style: TextStyle(
                                    color: AppTheme.coralRed,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.vibrantPurple.withValues(alpha: 0.15),
                              child: const Icon(Icons.account_balance_wallet, color: AppTheme.vibrantPurple),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    if (hive.isDeveloper) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.tune, color: AppTheme.textSecondary, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'DEVELOPER TOGGLE',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text('Include Test Data', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                              const SizedBox(width: 6),
                              SizedBox(
                                height: 20,
                                width: 35,
                                child: Switch(
                                  value: hive.includeTestDataInAnalytics,
                                  onChanged: (val) {
                                    hive.setIncludeTestDataInAnalytics(val);
                                  },
                                  activeThumbColor: AppTheme.emeraldGreen,
                                  inactiveThumbColor: AppTheme.textSecondary,
                                  inactiveTrackColor: Colors.white10,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Top Glass Savings Ring & Overview Stats
                    AppTheme.glassCard(
                      child: Row(
                        children: [
                          // Circular progress ring
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: Stack(
                              children: [
                                Center(
                                  child: SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: CircularProgressIndicator(
                                      value: savingsPercentage,
                                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                                      color: AppTheme.emeraldGreen,
                                      strokeWidth: 8,
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${(savingsPercentage * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Text(
                                        'Saved',
                                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          
                          // Overview data
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('MONTHLY HIGHLIGHTS', style: TextStyle(color: AppTheme.vibrantPurple, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                                const SizedBox(height: 6),
                                _buildHighlightRow('Income', '₹${income.toStringAsFixed(0)}', AppTheme.emeraldGreen),
                                const SizedBox(height: 6),
                                _buildHighlightRow('Expenses', '₹${totalSpent.toStringAsFixed(0)}', AppTheme.coralRed),
                                const Divider(color: AppTheme.borderColor, height: 12),
                                _buildHighlightRow('Net Savings', '₹${currentSavings.toStringAsFixed(0)}', currentSavings >= 0 ? AppTheme.emeraldGreen : AppTheme.coralRed),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // "Review Needed" panel
                    if (pendingReviews.isNotEmpty) ...[
                      const Text(
                        'REVIEW NEEDED',
                        style: TextStyle(
                          color: AppTheme.coralRed,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildReviewPanel(pendingReviews),
                      const SizedBox(height: 25),
                    ],

                    // Chart Section (PieChart Category Distribution)
                    const Text(
                      'EXPENSE VELOCITY BREAKDOWN',
                      style: TextStyle(
                        color: AppTheme.vibrantPurple,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppTheme.glassCard(
                      child: Column(
                        children: [
                          if (categoryDistribution.isEmpty)
                            const SizedBox(
                              height: 150,
                              child: Center(
                                child: Text('No expenses recorded yet.', style: TextStyle(color: AppTheme.textSecondary)),
                              ),
                            )
                          else ...[
                            SizedBox(
                              height: 160,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 40,
                                  sections: categoryDistribution.entries.map((e) {
                                    final catColor = _getCategoryColor(e.key);
                                    return PieChartSectionData(
                                      color: catColor,
                                      value: e.value,
                                      title: '₹${e.value.toStringAsFixed(0)}',
                                      radius: 25,
                                      titleStyle: const TextStyle(
                                        fontSize: 9, 
                                        fontWeight: FontWeight.bold, 
                                        color: Colors.white,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Legends wrapped in wrapping layout
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              alignment: WrapAlignment.center,
                              children: categoryDistribution.keys.map((cat) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(color: _getCategoryColor(cat), shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(cat, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                  ],
                                );
                              }).toList(),
                            )
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Recent logs overview
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'RECENT TRANSACTIONS',
                          style: TextStyle(
                            color: AppTheme.vibrantPurple,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                        const Text(
                          'View all history',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Show top 3 recent transactions
                    if (transactions.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('No transaction logs.', style: TextStyle(color: AppTheme.textSecondary)),
                        ),
                      )
                    else
                      ...transactions.take(3).map((tx) {
                        final isExpense = tx.type == 'expense';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: AppTheme.glassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Icon(
                                  isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: isExpense ? AppTheme.coralRed : AppTheme.emeraldGreen,
                                  size: 16,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          tx.title,
                                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (tx.isTest) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.coralRed.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppTheme.coralRed, width: 0.6),
                                          ),
                                          child: const Text(
                                            'TEST',
                                            style: TextStyle(color: AppTheme.coralRed, fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isExpense ? "-" : "+"} ₹${tx.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: isExpense ? AppTheme.coralRed : AppTheme.emeraldGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
        )
      ],
    );
  }

  Widget _buildReviewPanel(List<Transaction> pending) {
    return AppTheme.glassCard(
      padding: const EdgeInsets.all(16),
      color: AppTheme.coralRed,
      opacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.coralRed, size: 20),
              const SizedBox(width: 8),
              Text(
                '${pending.length} Transactions Need Review',
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 105,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: pending.length,
              itemBuilder: (context, index) {
                final tx = pending[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: InkWell(
                    onTap: () => _showReviewBottomSheet(tx),
                    child: Container(
                      width: 180,
                      padding: const EdgeInsets.all(12),
                      decoration: AppTheme.glassDecoration(
                        borderRadius: 12,
                        color: Colors.white,
                        opacity: 0.03,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.source,
                            style: const TextStyle(color: AppTheme.vibrantPurple, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tx.rawText,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontStyle: FontStyle.italic),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Click to Review', style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 8, color: AppTheme.textSecondary),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return AppTheme.emeraldGreen;
      case 'fuel':
        return Colors.orange;
      case 'shopping':
        return AppTheme.mutedBlue;
      case 'bills':
        return AppTheme.coralRed;
      case 'travel':
        return Colors.cyan;
      case 'entertainment':
        return AppTheme.vibrantPurple;
      case 'subscriptions':
        return Colors.pink;
      case 'healthcare':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
