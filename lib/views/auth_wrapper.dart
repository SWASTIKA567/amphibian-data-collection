import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';
import 'login_view.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginView();
        }

        final profileAsync = ref.watch(currentUserProfileProvider);
        return profileAsync.when(
          data: (profile) {
            if (profile != null) {
              return const MainNavigationScreen();
            }

            // If the user is logged in but has no profile in Firestore, and registration is not in progress,
            // we have a corrupted/incomplete account. Let's auto-sign them out.
            final controllerState = ref.watch(authControllerProvider);
            if (!controllerState.isLoading) {
              Future.microtask(() => ref.read(authControllerProvider.notifier).signOut());
            }

            return const LoginView();
          },
          loading: () => const LoginView(),
          error: (error, stack) => const LoginView(),
        );
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
