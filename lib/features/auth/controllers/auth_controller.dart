import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/user_repository.dart';

final authServiceProvider = Provider<AuthService>((_) => AuthService());
final userRepositoryProvider =
    Provider<UserRepository>((_) => UserRepository());

/// Live Firebase auth state. `null` while loading or signed out.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

/// Convenience: current uid (null if signed out).
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

class AuthController extends StateNotifier<AsyncValue<User?>> {
  AuthController(this._auth, this._users) : super(const AsyncData(null));

  final AuthService _auth;
  final UserRepository _users;

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      final user = await _auth.signInWithGoogle();
      if (user != null) {
        await _users.upsertOnSignIn(user);
      }
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  return AuthController(
    ref.read(authServiceProvider),
    ref.read(userRepositoryProvider),
  );
});
