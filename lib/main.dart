import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_chat/core/constant/app_color.dart';
import 'package:pulse_chat/core/constant/string_constants.dart';
import 'package:pulse_chat/core/database/database_helper.dart';
import 'package:pulse_chat/core/database/database_provider.dart';
import 'package:pulse_chat/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database before app starts
  final database = await DatabaseHelper.instance.database;

  runApp(
    ProviderScope(
      overrides: [databaseInstanceProvider.overrideWithValue(database)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: StringConstants.appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
      ),
      routerConfig: router,
    );
  }
}
