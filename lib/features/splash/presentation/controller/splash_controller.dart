import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_chat/features/splash/domain/splash_state.dart';



class SplashController extends StateNotifier<SplashState> {
  SplashController() : super(SplashState(status: SplashStatus.loading));

  Future<void> initializeApp() async {
    try {
      // Simulate initialization (DB, config, etc.)
      await Future.delayed(const Duration(seconds: 2));

      state = state.copyWith(status: SplashStatus.success);
    } catch (e) {
      state = state.copyWith(status: SplashStatus.error);
    }
  }
}