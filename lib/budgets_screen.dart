import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'hive_service.dart';
import 'models.dart';
import 'theme.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final _limitController = TextEditingController();

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _showEditBudgetDialog(Budget budget) {
    _limitController.text = budget.limit.toStringAsFixed(0);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          title: Text(
            'Adjust ${budget.category} Budget',
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set the maximum monthly spending limit for this category.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _limitController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Budget Limit (₹)',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  prefixIcon: const Icon(Icons.currency_rupee, color: AppTheme.vibrantPurple),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.vibrantPurple),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final newLimit = double.tryParse(_limitController.text) ?? budget.limit;
                final updated = budget.copyWith(limit: newLimit);
                Provider.of<HiveService>(context, listen: false).saveBudget(updated);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vibrantPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
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
              final budgets = hive.budgets;
              
              // Math for summaries
              double totalLimit = budgets.fold(0.0, (sum, b) => sum + b.limit);
              double totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spent);
              double totalRemaining = totalLimit - totalSpent;
              if (totalRemaining < 0) totalRemaining = 0.0;

              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'Budgets',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Monitor and adapt category spending caps.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 20),

                    // Top summary widget
                    AppTheme.glassCard(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              title: 'Total Limit',
                              value: '₹${totalLimit.toStringAsFixed(0)}',
                              icon: Icons.wallet,
                              color: AppTheme.mutedBlue,
                            ),
                          ),
                          Container(width: 1, height: 40, color: AppTheme.borderColor),
                          Expanded(
                            child: _buildSummaryItem(
                              title: 'Spent',
                              value: '₹${totalSpent.toStringAsFixed(0)}',
                              icon: Icons.trending_up,
                              color: totalSpent > totalLimit ? AppTheme.coralRed : AppTheme.emeraldGreen,
                            ),
                          ),
                          Container(width: 1, height: 40, color: AppTheme.borderColor),
                          Expanded(
                            child: _buildSummaryItem(
                              title: 'Remaining',
                              value: '₹${totalRemaining.toStringAsFixed(0)}',
                              icon: Icons.savings,
                              color: AppTheme.vibrantPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Category header
                    const Text(
                      'CATEGORY CAPS',
                      style: TextStyle(
                        color: AppTheme.vibrantPurple,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // List of categories
                    Expanded(
                      child: ListView.builder(
                        itemCount: budgets.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final budget = budgets[index];
                          final percent = budget.limit > 0 ? (budget.spent / budget.limit) : 0.0;
                          final isOverrun = percent >= 1.0;
                          final isWarning = percent >= 0.8 && percent < 1.0;

                          Color progressColor = AppTheme.vibrantPurple;
                          if (isOverrun) {
                            progressColor = AppTheme.coralRed;
                          } else if (isWarning) {
                            progressColor = Colors.orange;
                          } else {
                            progressColor = AppTheme.emeraldGreen;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: InkWell(
                              onTap: () => _showEditBudgetDialog(budget),
                              borderRadius: BorderRadius.circular(16),
                              child: AppTheme.glassCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: progressColor.withOpacity(0.15),
                                              child: Icon(
                                                _getCategoryIcon(budget.category),
                                                size: 18,
                                                color: progressColor,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  budget.category,
                                                  style: const TextStyle(
                                                    color: AppTheme.textPrimary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                Text(
                                                  'Limit: ₹${budget.limit.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    color: AppTheme.textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '₹${budget.spent.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                color: isOverrun ? AppTheme.coralRed : AppTheme.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              '${(percent * 100).toStringAsFixed(0)}% used',
                                              style: TextStyle(
                                                color: isOverrun 
                                                    ? AppTheme.coralRed 
                                                    : (isWarning ? Colors.orange : AppTheme.textSecondary),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: percent > 1.0 ? 1.0 : percent,
                                        backgroundColor: Colors.white.withOpacity(0.05),
                                        color: progressColor,
                                        minHeight: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'fuel':
        return Icons.local_gas_station;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
        return Icons.receipt_long;
      case 'travel':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'subscriptions':
        return Icons.subscriptions;
      case 'healthcare':
        return Icons.medical_services;
      default:
        return Icons.grid_view;
    }
  }
}
