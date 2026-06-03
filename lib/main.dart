import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'hive_service.dart';
import 'main_navigation.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final hiveService = HiveService();
  await hiveService.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => hiveService,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendMind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const MainNavigation(),
    );
  }
}
