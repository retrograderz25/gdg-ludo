import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';

// Provider để truy cập Auth client
final authProvider = Provider<GoTrueClient>((ref) {
  return ref.watch(supabaseClientProvider).auth;
});

// Stream Provider để lắng nghe trạng thái đăng nhập
final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authProvider).onAuthStateChange;
});

// Provider để xử lý các hành động (signIn, signUp, signOut)
final authActionProvider = Provider((ref) {
  return AuthActionNotifier(ref.watch(authProvider));
});

class AuthActionNotifier {
  final GoTrueClient _auth;
  AuthActionNotifier(this._auth);

  Future<void> signUp({required String email, required String password}) async {
    await _auth.signUp(email: email, password: password);
  }

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}