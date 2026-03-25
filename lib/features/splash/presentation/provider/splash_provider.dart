import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_chat/features/splash/domain/splash_state.dart';
import 'package:pulse_chat/features/splash/presentation/controller/splash_controller.dart';

final splashProvider =
    StateNotifierProvider<SplashController, SplashState>((ref) {
  return SplashController();
});