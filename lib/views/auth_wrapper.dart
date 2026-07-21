import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import 'home_view.dart';
import 'login_view.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const HomeView();
        }
        return const LoginView();
      },
      loading: () => const Scaffold(
        backgroundColor: AppTheme.lightMintBackground,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryGreen,
          ),
        ),
      ),
      error: (error, stack) => const Scaffold(
        backgroundColor: AppTheme.lightMintBackground,
        body: Center(
          child: Text('An error occurred loading auth state.'),
        ),
      ),
    );
  }
}
