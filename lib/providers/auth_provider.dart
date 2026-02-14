import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// Provides the AuthService instance.
///
/// Provider is a Riverpod concept: it's a globally accessible container
/// for a value. Any widget can read it with ref.watch() or ref.read().
/// Think of it like a singleton, but with lifecycle management.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Streams the current auth state (logged in user or null).
///
/// StreamProvider wraps a Stream and exposes it as an AsyncValue.
/// In your widgets:
///   final authState = ref.watch(authStateProvider);
///   authState.when(
///     data: (user) => ...,   // User? - null means logged out
///     loading: () => ...,     // Still checking auth
///     error: (e, st) => ..., // Auth check failed
///   );
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Convenience provider for the current user ID.
/// Returns null if not logged in.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});
