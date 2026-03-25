import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_chat/core/constant/app_color.dart';
import 'package:pulse_chat/core/constant/app_icons.dart';
import 'package:pulse_chat/core/constant/app_style.dart';
import 'package:pulse_chat/core/constant/string_constants.dart';
import 'package:pulse_chat/features/auth/presentation/controllers/auth_state.dart';
import 'package:pulse_chat/features/auth/presentation/providers/auth_providers.dart';
import 'package:pulse_chat/features/auth/presentation/widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      } else if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? StringConstants.loginFailed),
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  StringConstants.welcomeBack,
                  style: AppStyles.heading,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  StringConstants.signInToContinue,
                  style: AppStyles.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                AuthTextField(
                  controller: _emailController,
                  hintText: StringConstants.email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(AppIcons.email),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _passwordController,
                  hintText: StringConstants.password,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(AppIcons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? AppIcons.visibilityOff
                          : AppIcons.visibilityOn,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authState.status == AuthStatus.loading
                      ? null
                      : () {
                          ref
                              .read(authProvider.notifier)
                              .login(
                                _emailController.text.trim(),
                                _passwordController.text.trim(),
                              );
                        },
                  style: AppStyles.primaryButton,
                  child: authState.status == AuthStatus.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text(
                          StringConstants.login,
                          style: AppStyles.buttonText,
                        ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text(StringConstants.dontHaveAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
