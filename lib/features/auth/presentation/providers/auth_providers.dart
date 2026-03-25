import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_chat/core/database/database_provider.dart';
import 'package:pulse_chat/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:pulse_chat/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pulse_chat/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse_chat/features/auth/domain/usecases/auth_usecases.dart';
import 'package:pulse_chat/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pulse_chat/features/auth/presentation/controllers/auth_state.dart';

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final db = ref.watch(databaseInstanceProvider);
  return AuthLocalDataSource(db);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final localDataSource = ref.watch(authLocalDataSourceProvider);
  return AuthRepositoryImpl(localDataSource);
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
  );
});
