import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

// Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Stream Provider listening to Firebase Auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Current User Profile Provider from Firestore
final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return null;
  return ref.read(authServiceProvider).getUserProfile(user.uid);
});

// Auth State class for UI status (loading, error, user profile)
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final UserModel? userProfile;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.userProfile,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    UserModel? userProfile,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      userProfile: userProfile ?? this.userProfile,
    );
  }
}

// Auth Controller (StateNotifier) in MVC architecture
class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthController(this._authService) : super(const AuthState());

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Handle User Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.loginWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFirebaseError(e.code, e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // Handle User Registration
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    // Basic Form Validations
    if (name.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter your name.');
      return false;
    }

    if (email.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter your email.');
      return false;
    }

    if (password.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter a password.');
      return false;
    }

    if (password.length < 6) {
      state = state.copyWith(errorMessage: 'Password must be at least 6 characters long.');
      return false;
    }

    if (password != confirmPassword) {
      state = state.copyWith(errorMessage: 'Passwords do not match.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userModel = await _authService.registerWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, userProfile: userModel);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFirebaseError(e.code, e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // Handle User Sign Out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _authService.signOut();
    state = const AuthState();
  }

  // User-friendly error message mapping
  String _mapFirebaseError(String code, String? defaultMsg) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'invalid-email':
        return 'The email address provided is invalid.';
      case 'weak-password':
        return 'The password provided is too weak.';
      default:
        return defaultMsg ?? 'An authentication error occurred. Please try again.';
    }
  }
}

// Controller Provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthController(authService);
});
