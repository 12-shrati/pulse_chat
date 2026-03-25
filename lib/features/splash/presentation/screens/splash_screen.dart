import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_chat/core/constant/app_color.dart';
import 'package:pulse_chat/core/constant/app_style.dart';
import 'package:pulse_chat/core/constant/string_constants.dart';
import 'package:pulse_chat/features/splash/presentation/providers/splash_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(splashProvider.notifier).initializeApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(splashProvider, (previous, next) {
      if (next.status == SplashStatus.authenticated) {
        context.go('/home');
      } else if (next.status == SplashStatus.unauthenticated) {
        context.go('/login');
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(StringConstants.appName, style: AppStyles.splashTitle),
            SizedBox(height: 10),
            Text(StringConstants.appTagline, style: AppStyles.splashSubtitle),
            SizedBox(height: 40),
            CircularProgressIndicator(color: AppColors.white),
          ],
        ),
      ),
    );
  }
}
