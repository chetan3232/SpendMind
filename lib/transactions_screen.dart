import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'hive_service.dart';
import 'models.dart';
import 'theme.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _selectedCategoryFilter = 'All';
  
  // Dialog Controllers
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';
  String _selectedType = 'expense';

  final List<String> _categories = [
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

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _showAddTransactionDialog() {
    _titleController.clear();
    _amountController.clear();
    _selectedCategory = 'Food';
    _selectedType = 'expense';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              title: const Text(
                'Add Transaction',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Type selector
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => _selectedType = 'expense'),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedType == 'expense' 
                                    ? AppTheme.coralRed.withOpacity(0.15) 
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedType == 'expense' ? AppTheme.coralRed : Colors.white.withOpacity(0.05),
                                ),
                              ),
                              child: Text(
                                'Expense',
                                style: TextStyle(
                                  color: _selectedType == 'expense' ? AppTheme.coralRed : AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => _selectedType = 'income'),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedType == 'income' 
                                    ? AppTheme.emeraldGreen.withOpacity(0.15) 
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedType == 'income' ? AppTheme.emeraldGreen : Colors.white.withOpacity(0.05),
                                ),
                              ),
                              child: Text(
                                'Income',
                                style: TextStyle(
                                  color: _selectedType == 'income' ? AppTheme.emeraldGreen : AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Title
                    _buildDialogTextField(
                      controller: _titleController,
                      label: 'Merchant / Description',
                      icon: Icons.title,
                    ),
                    const SizedBox(height: 15),

                    // Amount
                    _buildDialogTextField(
                      controller: _amountController,
                      label: 'Amount (₹)',
                      icon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 15),

                    // Category Dropdown
                    if (_selectedType == 'expense') ...[
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        dropdownColor: AppTheme.cardColor,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: const TextStyle(color: AppTheme.textSecondary),
                          prefixIcon: const Icon(Icons.grid_view, color: AppTheme.vibrantPurple),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.2),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                          ),
                        ),
                        items: _categories.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => _selectedCategory = val);
                          }
                        },
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = _titleController.text.trim();
                    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
                    if (title.isEmpty || amount <= 0) return;

                    final tx = Transaction(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      title: title,
                      amount: amount,
                      category: _selectedType == 'income' ? 'Others' : _selectedCategory,
                      type: _selectedType,
                      timestamp: DateTime.now(),
                      source: 'Manual',
                      rawText: '',
                      isParsedSuccessfully: true,
                      status: 'reviewed',
                    );

                    Provider.of<HiveService>(context, listen: false).saveTransaction(tx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.vibrantPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.vibrantPurple, size: 20),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchLower = _searchController.text.toLowerCase();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Consumer<HiveService>(
            builder: (context, hive, child) {
              final includeTest = hive.isDeveloper && hive.includeTestDataInAnalytics;
              // Filter transactions based on search and category
              final list = hive.transactions.where((tx) {
                if (tx.isTest && !includeTest) return false;
                final matchSearch = tx.title.toLowerCase().contains(searchLower) ||
                    tx.category.toLowerCase().contains(searchLower);
                final matchCategory = _selectedCategoryFilter == 'All' ||
                    tx.category.toLowerCase() == _selectedCategoryFilter.toLowerCase();
                return matchSearch && matchCategory;
              }).toList();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transactions',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                            const Text(
                              'Track and review your expenses history.',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                        // Add Button
                        InkWell(
                          onTap: _showAddTransactionDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: AppTheme.glassDecoration(
                              borderRadius: 12,
                              color: AppTheme.vibrantPurple,
                              opacity: 0.2,
                            ),
                            child: const Icon(Icons.add, color: AppTheme.vibrantPurple),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Search input
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search merchant or category...',
                        hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                        filled: true,
                        fillColor: AppTheme.cardColor.withOpacity(0.4),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.vibrantPurple),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Horizontal filter chips
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildFilterChip('All'),
                          ..._categories.map((c) => _buildFilterChip(c)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Transactions list
                    Expanded(
                      child: list.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long, size: 50, color: AppTheme.textSecondary.withOpacity(0.5)),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No transactions found',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Manual add or incoming SMS will show up here.',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                final tx = list[index];
                                final isExpense = tx.type == 'expense';
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: Dismissible(
                                    key: Key(tx.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      decoration: BoxDecoration(
                                        color: AppTheme.coralRed.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.delete, color: Colors.white),
                                    ),
                                    onDismissed: (direction) {
                                      hive.deleteTransaction(tx.id);
                                    },
                                    child: AppTheme.glassCard(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: (isExpense 
                                                ? AppTheme.coralRed 
                                                : AppTheme.emeraldGreen).withOpacity(0.1),
                                            child: Icon(
                                              isExpense 
                                                  ? _getCategoryIcon(tx.category) 
                                                  : Icons.arrow_downward,
                                              color: isExpense ? AppTheme.coralRed : AppTheme.emeraldGreen,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                   children: [
                                                     Expanded(
                                                       child: Text(
                                                         tx.title,
                                                         style: const TextStyle(
                                                           color: AppTheme.textPrimary,
                                                           fontWeight: FontWeight.bold,
                                                           fontSize: 14,
                                                         ),
                                                         maxLines: 1,
                                                         overflow: TextOverflow.ellipsis,
                                                       ),
                                                     ),
                                                     if (tx.isTest) ...[
                                                       const SizedBox(width: 6),
                                                       Container(
                                                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                         decoration: BoxDecoration(
                                                           color: AppTheme.coralRed.withOpacity(0.15),
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
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Text(
                                                      DateFormat('dd MMM, hh:mm a').format(tx.timestamp),
                                                      style: const TextStyle(
                                                        color: AppTheme.textSecondary,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withOpacity(0.05),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        tx.source,
                                                        style: const TextStyle(
                                                          color: AppTheme.textSecondary,
                                                          fontSize: 9,
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${isExpense ? "-" : "+"} ₹${tx.amount.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  color: isExpense ? AppTheme.coralRed : AppTheme.emeraldGreen,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                tx.category,
                                                style: const TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
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

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedCategoryFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          setState(() {
            _selectedCategoryFilter = label;
          });
        },
        selectedColor: AppTheme.vibrantPurple.withOpacity(0.2),
        backgroundColor: AppTheme.cardColor.withOpacity(0.4),
        checkmarkColor: AppTheme.vibrantPurple,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.vibrantPurple : AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppTheme.vibrantPurple : Colors.white.withOpacity(0.05),
          ),
        ),
      ),
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
