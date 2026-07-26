import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import 'register_view.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final success = await ref.read(authControllerProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      if (!success && mounted) {
        final error = ref.read(authControllerProvider).errorMessage;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.lightMintBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height - MediaQuery.of(context).padding.top,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 56),

                  // ── Logo mark ──
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      size: 28,
                      color: AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Headline ──
                  const Text(
                    'Welcome\nback.',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                      height: 1.15,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sign in to continue your research.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Form ──
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email
                        _buildFieldLabel('Email'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: 'you@example.com',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Password
                        _buildFieldLabel('Password'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _isPasswordObscured,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submitLogin(),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordObscured
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppTheme.textMuted,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _isPasswordObscured = !_isPasswordObscured),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),

                        // ── Login Button ──
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _submitLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: AppTheme.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: authState.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: AppTheme.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Divider ──
                  Row(
                    children: [
                      Expanded(
                          child: Divider(
                              color: AppTheme.borderGreen.withValues(alpha: 0.5),
                              thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'New here?',
                          style: TextStyle(
                            color: AppTheme.textMuted.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                          child: Divider(
                              color: AppTheme.borderGreen.withValues(alpha: 0.5),
                              thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Register CTA ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(authControllerProvider.notifier).clearError();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const RegisterView()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: const BorderSide(
                            color: AppTheme.primaryGreen, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Create an Account',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
        letterSpacing: 0.2,
      ),
    );
  }
}
