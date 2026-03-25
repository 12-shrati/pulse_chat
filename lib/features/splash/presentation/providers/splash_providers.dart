import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_chat/features/auth/presentation/providers/auth_providers.dart';
import 'package:pulse_chat/features/splash/presentation/controllers/splash_controller.dart';
import 'package:pulse_chat/features/splash/presentation/controllers/splash_state.dart';

export 'package:pulse_chat/features/splash/presentation/controllers/splash_state.dart';

final splashProvider = StateNotifierProvider<SplashController, SplashState>((
  ref,
) {
  final authRepository = ref.watch(authRepositoryProvider);
  return SplashController(authRepository);
});
