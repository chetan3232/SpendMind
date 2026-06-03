import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'hive_service.dart';
import 'parser_service.dart';
import 'theme.dart';

// Screens
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'budgets_screen.dart';
import 'coach_screen.dart';
import 'settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with WidgetsBindingObserver {
  static const _platform = MethodChannel('com.spendmind.app/native');
  
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionsScreen(),
    const BudgetsScreen(),
    const CoachScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial sync on app start
    _syncPendingTransactions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPendingTransactions();
    }
  }

  Future<void> _syncPendingTransactions() async {
    try {
      final List<dynamic>? pendingList = 
          await _platform.invokeMethod<List<dynamic>>('getPendingTransactions');
      
      if (pendingList == null || pendingList.isEmpty) return;

      final hive = Provider.of<HiveService>(context, listen: false);
      int successCount = 0;
      int pendingCount = 0;

      for (var rawEntry in pendingList) {
        final Map<String, dynamic> data = jsonDecode(rawEntry.toString());
        final String body = data['body'] ?? '';
        final String source = data['source'] ?? 'SMS';
        
        final parsedTx = SMSParserService.parseMessage(body, source);
        if (parsedTx != null) {
          // If title was parsed as Debit/Credit transaction fallback, flag as pending review
          final isClean = parsedTx.isParsedSuccessfully && 
                          parsedTx.title != 'Debit Transaction' && 
                          parsedTx.title != 'Incoming Transfer';

          final tx = parsedTx.copyWith(
            isParsedSuccessfully: isClean,
            status: isClean ? 'reviewed' : 'pending',
          );

          await hive.saveTransaction(tx);
          if (isClean) {
            successCount++;
          } else {
            pendingCount++;
          }
        }
      }

      if (successCount > 0 || pendingCount > 0) {
        _showSyncFeedback(successCount, pendingCount);
      }
    } catch (e) {
      print('Sync transactions error: $e');
    }
  }

  void _showSyncFeedback(int success, int pending) {
    String msg = '';
    if (success > 0 && pending > 0) {
      msg = 'Auto-tracked $success expenses. $pending need review.';
    } else if (success > 0) {
      msg = 'Auto-tracked $success expenses successfully!';
    } else if (pending > 0) {
      msg = 'Captured $pending transactions needing review.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.sync, color: AppTheme.emeraldGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg, 
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.borderColor, width: 0.8)),
          color: AppTheme.background,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.background,
          selectedItemColor: AppTheme.vibrantPurple,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.track_changes_outlined),
              activeIcon: Icon(Icons.track_changes),
              label: 'Budgets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_outlined),
              activeIcon: Icon(Icons.psychology),
              label: 'Coach',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
