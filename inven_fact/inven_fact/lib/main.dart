import 'package:flutter/material.dart';
import 'package:inven_fact/config/theme.dart';
import 'package:inven_fact/screens/welcome_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;

void main() {
  // Inicializar sqflite_common_ffi solo en Windows
  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Inventario',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // O .light, .dark
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
