import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'screens/folders_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Reset database to fix image URLs - REMOVE THIS AFTER FIRST SUCCESSFUL RUN
  print("Resetting database to fix image URLs...");
  final dbHelper = DatabaseHelper();
  await dbHelper.resetDatabase();
  print("Database reset complete!");
  
  runApp(const CardOrganizerApp());
}

class CardOrganizerApp extends StatelessWidget {
  const CardOrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: const FoldersScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}