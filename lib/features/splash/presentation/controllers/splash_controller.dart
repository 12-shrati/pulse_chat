import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_chat/core/database/database_helper.dart';
import 'package:pulse_chat/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse_chat/features/splash/presentation/controllers/splash_state.dart';

class SplashController extends StateNotifier<SplashState> {
  final AuthRepository _authRepository;

  SplashController(this._authRepository) : super(const SplashState());

  Future<void> initializeApp() async {
    try {
      // Initialize database
      await DatabaseHelper.instance.database;

      // Simulate extra initialization
      await Future.delayed(const Duration(seconds: 2));

      // Check for valid session
      final user = await _authRepository.restoreSession();
      if (user != null) {
        state = state.copyWith(status: SplashStatus.authenticated);
      } else {
        state = state.copyWith(status: SplashStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: SplashStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
