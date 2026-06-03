import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'hive_service.dart';
import 'models.dart';
import 'parser_service.dart';
import 'theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _platform = MethodChannel('com.spendmind.app/native');

  final _emailController = TextEditingController();
  final _incomeController = TextEditingController();
  final _goalController = TextEditingController();
  final _apiKeyController = TextEditingController();

  // Developer Mode Simulator Variables
  String _selectedSourceApp = 'Google Pay';
  String _selectedDevCategory = 'Food';
  final _devMerchantController = TextEditingController();
  final _devAmountController = TextEditingController();
  final _devSmsSenderController = TextEditingController(text: 'HDFC-Bank');
  final _devSmsBodyController = TextEditingController(text: 'Alert: ₹150.00 spent at Zomato using HDFC Credit Card on 03-Jun.');
  final _newDevEmailController = TextEditingController();

  bool _smsPermissionGranted = false;
  bool _notificationPermissionGranted = false;
  bool _batteryOptimizationIgnored = false;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    final hive = Provider.of<HiveService>(context, listen: false);
    _emailController.text = hive.userEmail;
    _incomeController.text = hive.monthlyIncome.toStringAsFixed(0);
    _goalController.text = hive.savingsGoal.toStringAsFixed(0);
    _apiKeyController.text = hive.geminiApiKey;

    _checkPermissions();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _incomeController.dispose();
    _goalController.dispose();
    _apiKeyController.dispose();
    _devMerchantController.dispose();
    _devAmountController.dispose();
    _devSmsSenderController.dispose();
    _devSmsBodyController.dispose();
    _newDevEmailController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final smsStatus = await Permission.sms.status;
    
    bool notifGranted = false;
    bool batteryIgnored = false;
    try {
      notifGranted = await _platform.invokeMethod<bool>('hasNotificationPermission') ?? false;
      batteryIgnored = await _platform.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;
    } catch (e) {
      print('Failed checking permissions: $e');
    }

    setState(() {
      _smsPermissionGranted = smsStatus.isGranted;
      _notificationPermissionGranted = notifGranted;
      _batteryOptimizationIgnored = batteryIgnored;
    });
  }

  Future<void> _requestSmsPermission() async {
    final status = await Permission.sms.request();
    setState(() {
      _smsPermissionGranted = status.isGranted;
    });
    _showSnackBar(status.isGranted ? 'SMS Permission Granted' : 'SMS Permission Denied');
  }

  Future<void> _requestNotificationPermission() async {
    try {
      await _platform.invokeMethod('requestNotificationPermission');
      // Wait briefly for user response before re-checking
      Future.delayed(const Duration(seconds: 2), _checkPermissions);
    } catch (e) {
      _showSnackBar('Failed to request notification permission');
    }
  }

  Future<void> _requestBatteryOptimizations() async {
    try {
      await _platform.invokeMethod('requestIgnoreBatteryOptimizations');
      Future.delayed(const Duration(seconds: 2), _checkPermissions);
    } catch (e) {
      _showSnackBar('Failed to request battery optimization override');
    }
  }

  void _saveSettings() async {
    final hive = Provider.of<HiveService>(context, listen: false);
    final email = _emailController.text.trim();
    final income = double.tryParse(_incomeController.text) ?? hive.monthlyIncome;
    final goal = double.tryParse(_goalController.text) ?? hive.savingsGoal;
    final apiKey = _apiKeyController.text.trim();

    await hive.setUserEmail(email);
    await hive.setMonthlyIncome(income);
    await hive.setSavingsGoal(goal);
    await hive.setGeminiApiKey(apiKey);

    _showSnackBar('Settings Saved Successfully');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hive = Provider.of<HiveService>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Configure your profile parameters and system tools.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 25),

                // Financial Configuration Cards
                const Text(
                  'PROFILE DETAILS',
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
                      _buildTextField(
                        controller: _emailController,
                        label: 'Profile Email Address',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _incomeController,
                        label: 'Monthly Income (₹)',
                        icon: Icons.wallet,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _goalController,
                        label: 'Savings Goal Target (₹)',
                        icon: Icons.track_changes,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // AI Credentials Card
                const Text(
                  'AI POWER ENGINE',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _apiKeyController,
                        label: 'Gemini API Key',
                        icon: Icons.vpn_key,
                        obscureText: _obscureApiKey,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureApiKey = !_obscureApiKey;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'This API key is stored locally on your device and is only used to connect to Google Gemini services.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // System Integrations Card
                const Text(
                  'SYSTEM PERMISSIONS',
                  style: TextStyle(
                    color: AppTheme.vibrantPurple,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                AppTheme.glassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildPermissionTile(
                        title: 'SMS Transaction Access',
                        subtitle: 'Intercept incoming banking messages',
                        isGranted: _smsPermissionGranted,
                        onPressed: _requestSmsPermission,
                      ),
                      const Divider(color: AppTheme.borderColor, height: 1),
                      _buildPermissionTile(
                        title: 'Notification Listener',
                        subtitle: 'Read push notifications from UPI apps',
                        isGranted: _notificationPermissionGranted,
                        onPressed: _requestNotificationPermission,
                      ),
                      const Divider(color: AppTheme.borderColor, height: 1),
                      _buildPermissionTile(
                        title: 'Ignore Battery Optimizations',
                        subtitle: 'Maintain tracking stability in background',
                        isGranted: _batteryOptimizationIgnored,
                        onPressed: _requestBatteryOptimizations,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Save button
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.vibrantPurple.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Save Configuration',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // Developer Mode panel
                if (hive.isDeveloper) ...[
                  const SizedBox(height: 35),
                  _buildDeveloperTools(hive),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.vibrantPurple),
        suffixIcon: suffixIcon,
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

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isGranted ? AppTheme.emeraldGreen.withOpacity(0.15) : AppTheme.vibrantPurple.withOpacity(0.15),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isGranted ? AppTheme.emeraldGreen : AppTheme.vibrantPurple,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isGranted ? Icons.check_circle : Icons.arrow_forward_ios,
                  size: 14,
                  color: isGranted ? AppTheme.emeraldGreen : AppTheme.textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  isGranted ? 'Enabled' : 'Configure',
                  style: TextStyle(
                    color: isGranted ? AppTheme.emeraldGreen : AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- DEVELOPER PANEL UI ---
  Widget _buildDeveloperTools(HiveService hive) {
    final List<String> sourceApps = [
      'Google Pay', 'PhonePe', 'Paytm', 'FamApp', 'Amazon Pay', 'BHIM', 'CRED'
    ];
    final List<String> categories = [
      'Food', 'Fuel', 'Shopping', 'Bills', 'Travel', 'Entertainment', 'Subscriptions', 'Healthcare', 'Others'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.developer_mode, color: AppTheme.coralRed, size: 22),
            const SizedBox(width: 8),
            Text(
              'DEVELOPER CONTROL PANEL',
              style: TextStyle(
                color: AppTheme.coralRed,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.coralRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.coralRed, width: 0.8),
              ),
              child: const Text(
                'TEST MODE',
                style: TextStyle(color: AppTheme.coralRed, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // 1. Fake Transaction Generator
        _buildDevSectionHeader('Fake Transaction Generator', Icons.receipt_long),
        AppTheme.glassCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSourceApp,
                      dropdownColor: AppTheme.cardColor,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: _getDevInputDecoration('Source App'),
                      items: sourceApps.map((app) {
                        return DropdownMenuItem(value: app, child: Text(app));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSourceApp = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedDevCategory,
                      dropdownColor: AppTheme.cardColor,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: _getDevInputDecoration('Category'),
                      items: categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedDevCategory = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDevTextField(
                controller: _devMerchantController,
                label: 'Merchant Name (e.g. Swiggy, Uber)',
                icon: Icons.store,
              ),
              const SizedBox(height: 12),
              _buildDevTextField(
                controller: _devAmountController,
                label: 'Amount (₹)',
                icon: Icons.currency_rupee,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () => _generateFakeTransaction(hive),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.vibrantPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Generate Transaction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Parser Simulator (SMS & Push Notification)
        _buildDevSectionHeader('SMS & Notification Parser Simulator', Icons.sms),
        AppTheme.glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SIMULATE BANK SMS BROADCAST',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDevTextField(
                controller: _devSmsSenderController,
                label: 'SMS Sender Header',
                icon: Icons.portrait,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _devSmsBodyController,
                maxLines: 2,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: _getDevInputDecoration('SMS Body Text'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: () => _generateFakeSMS(hive),
                  icon: const Icon(Icons.sync, size: 16, color: AppTheme.emeraldGreen),
                  label: const Text('Simulate SMS Broadcast', style: TextStyle(color: AppTheme.emeraldGreen, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.emeraldGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const Divider(color: AppTheme.borderColor, height: 30),
              const Text(
                'SIMULATE UPI PUSH NOTIFICATIONS',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildNotificationChip(
                    label: 'Google Pay Swiggy',
                    text: 'Paid ₹250 to Swiggy',
                    app: 'Google Pay',
                    hive: hive,
                  ),
                  _buildNotificationChip(
                    label: 'PhonePe Swiggy',
                    text: 'You have paid ₹250 to Swiggy',
                    app: 'PhonePe',
                    hive: hive,
                  ),
                  _buildNotificationChip(
                    label: 'FamApp Spend',
                    text: '₹250 spent using FamApp',
                    app: 'FamApp',
                    hive: hive,
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. Bulk Seeder & Diagnostics
        _buildDevSectionHeader('Bulk Operations & Diagnostics', Icons.speed),
        AppTheme.glassCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _generateBulkTestTransactions(hive),
                      icon: const Icon(Icons.grid_view_rounded, size: 16, color: Colors.white),
                      label: const Text('Seed 15 Test Tx', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.vibrantPurple.withOpacity(0.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _clearTestTransactions(hive),
                      icon: const Icon(Icons.delete_sweep, size: 16, color: AppTheme.coralRed),
                      label: const Text('Wipe Test Data', style: TextStyle(color: AppTheme.coralRed, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.coralRed),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppTheme.borderColor, height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Simulated Transactions:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  Text(
                    '${hive.transactions.where((tx) => tx.isTest).length}',
                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 4. Configurable Developer Emails
        _buildDevSectionHeader('Configurable Developer Emails', Icons.people_outline),
        AppTheme.glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDevTextField(
                      controller: _newDevEmailController,
                      label: 'New Developer Email',
                      icon: Icons.add_to_home_screen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final email = _newDevEmailController.text.trim();
                        if (email.isNotEmpty && email.contains('@')) {
                          hive.addDeveloperEmail(email);
                          _newDevEmailController.clear();
                          _showSnackBar('Developer account added: $email');
                        } else {
                          _showSnackBar('Enter a valid email address.');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.vibrantPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                'AUTHORIZED DEVELOPER ACCOUNTS:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: hive.developerEmails.map((email) {
                  final isPrimary = email == 'gamerchetan323@gmail.com';
                  return Chip(
                    backgroundColor: Colors.black.withOpacity(0.3),
                    label: Text(email, style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                    deleteIcon: isPrimary ? null : const Icon(Icons.close, size: 14, color: AppTheme.coralRed),
                    onDeleted: isPrimary ? null : () {
                      hive.removeDeveloperEmail(email);
                      _showSnackBar('Removed developer account: $email');
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: AppTheme.borderColor),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDevSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      decoration: _getDevInputDecoration(label).copyWith(
        prefixIcon: Icon(icon, color: AppTheme.vibrantPurple, size: 16),
      ),
    );
  }

  InputDecoration _getDevInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      filled: true,
      fillColor: Colors.black.withOpacity(0.2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.vibrantPurple),
      ),
    );
  }

  Widget _buildNotificationChip({
    required String label,
    required String text,
    required String app,
    required HiveService hive,
  }) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _generateFakeNotification(hive, text, app),
      backgroundColor: AppTheme.cardColor.withOpacity(0.4),
      labelStyle: const TextStyle(color: AppTheme.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.emeraldGreen.withOpacity(0.5)),
      ),
    );
  }

  void _generateFakeTransaction(HiveService hive) async {
    final merchant = _devMerchantController.text.trim();
    final amount = double.tryParse(_devAmountController.text.trim()) ?? 0.0;
    if (merchant.isEmpty || amount <= 0) {
      _showSnackBar('Please enter valid merchant name and amount.');
      return;
    }
    final tx = Transaction(
      id: 'test_${DateTime.now().microsecondsSinceEpoch}',
      title: merchant,
      amount: amount,
      category: _selectedDevCategory,
      type: 'expense',
      timestamp: DateTime.now(),
      source: _selectedSourceApp,
      rawText: 'Simulated payment of ₹$amount to $merchant via $_selectedSourceApp',
      isParsedSuccessfully: true,
      status: 'reviewed',
      isTest: true,
    );
    await hive.saveTransaction(tx);
    _showSnackBar('Generated fake transaction for $merchant (₹$amount).');
    _devMerchantController.clear();
    _devAmountController.clear();
  }

  void _generateFakeSMS(HiveService hive) async {
    final sender = _devSmsSenderController.text.trim();
    final body = _devSmsBodyController.text.trim();
    if (sender.isEmpty || body.isEmpty) {
      _showSnackBar('Please enter sender and SMS body.');
      return;
    }
    final parsedTx = SMSParserService.parseMessage(body, sender);
    if (parsedTx != null) {
      final tx = parsedTx.copyWith(isTest: true);
      await hive.saveTransaction(tx);
      _showSnackBar('SMS parsed successfully! Saved as ${tx.title} (₹${tx.amount.toStringAsFixed(0)}).');
    } else {
      // Create a pending transaction if parse failed, to match prod SMSReceiver behavior!
      final tx = Transaction(
        id: 'test_sms_pending_${DateTime.now().microsecondsSinceEpoch}',
        title: 'Debit Transaction',
        amount: 0.0,
        category: 'Others',
        type: 'expense',
        timestamp: DateTime.now(),
        source: sender,
        rawText: body,
        isParsedSuccessfully: false,
        status: 'pending',
        isTest: true,
      );
      await hive.saveTransaction(tx);
      _showSnackBar('SMS could not be parsed. Created pending review item on Dashboard.');
    }
  }

  void _generateFakeNotification(HiveService hive, String templateText, String sourceAppName) async {
    final parsedTx = SMSParserService.parseMessage(templateText, sourceAppName);
    if (parsedTx != null) {
      final tx = parsedTx.copyWith(isTest: true);
      await hive.saveTransaction(tx);
      _showSnackBar('Notification parsed: ${tx.title} (₹${tx.amount.toStringAsFixed(0)}).');
    } else {
      _showSnackBar('Failed to parse simulated notification.');
    }
  }

  void _generateBulkTestTransactions(HiveService hive) async {
    final now = DateTime.now();
    final randomMerchants = {
      'Food': ['Swiggy', 'Zomato', 'McDonalds', 'Starbucks', 'KFC'],
      'Fuel': ['HP Petrol', 'Indian Oil', 'Shell Station'],
      'Shopping': ['Amazon Pay', 'Flipkart Shopping', 'Zara Clothing', 'Myntra'],
      'Bills': ['Electricity Bill', 'Airtel Recharge', 'Water Utility'],
      'Travel': ['Uber Ride', 'Ola Cab', 'Metro Ticket'],
      'Entertainment': ['BookMyShow Movies', 'Steam Games', 'PlayStation Store'],
      'Subscriptions': ['Netflix Premium', 'Spotify Music', 'YouTube Premium'],
      'Healthcare': ['Apollo Pharmacy', 'PharmEasy', 'Dental Clinic'],
    };

    final List<String> categories = randomMerchants.keys.toList();
    int count = 0;

    for (int i = 0; i < 15; i++) {
      final cat = categories[i % categories.length];
      final merchantList = randomMerchants[cat]!;
      final merchant = merchantList[i % merchantList.length];
      final amount = (100 + (i * 125)).toDouble();
      
      // Distribute dates in current month
      final daysOffset = i * 2;
      final txDate = now.subtract(Duration(days: daysOffset));

      final tx = Transaction(
        id: 'test_bulk_${i}_${DateTime.now().microsecondsSinceEpoch}',
        title: merchant,
        amount: amount,
        category: cat,
        type: 'expense',
        timestamp: txDate,
        source: 'Bulk Simulator',
        rawText: 'Bulk test transaction for $merchant',
        isParsedSuccessfully: true,
        status: 'reviewed',
        isTest: true,
      );
      await hive.saveTransaction(tx);
      count++;
    }
    _showSnackBar('Seeded $count test transactions across categories.');
  }

  void _clearTestTransactions(HiveService hive) async {
    await hive.clearTestData();
    _showSnackBar('All test transactions wiped out.');
  }
}
