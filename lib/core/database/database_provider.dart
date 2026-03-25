import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

/// Override this in ProviderScope with the initialized Database instance.
final databaseInstanceProvider = Provider<Database>((ref) {
  throw UnimplementedError(
    'databaseInstanceProvider must be overridden with a ready Database instance.',
  );
});
