import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 认证状态 Notifier。
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthState {
  final User? user;
  final bool loading;
  final String? error;

  const AuthState({this.user, this.loading = false, this.error});

  bool get isLoggedIn => user != null;

  AuthState copyWith({User? user, bool? loading, String? error}) =>
      AuthState(user: user ?? this.user, loading: loading ?? this.loading,
          error: error ?? ''); // 空串表示清除错误
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // 监听 Supabase 的认证状态变化
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      state = state.copyWith(user: data.session?.user, loading: false);
    });

    final user = Supabase.instance.client.auth.currentUser;
    return AuthState(user: user);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true, error: '');
    try {
      await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
      state = state.copyWith(loading: false);
    } on AuthException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(loading: false, error: '登录失败，请检查网络');
      rethrow;
    }
  }

  Future<void> register(String email, String password) async {
    state = state.copyWith(loading: true, error: '');
    try {
      await Supabase.instance.client.auth.signUp(email: email, password: password);
      state = state.copyWith(loading: false);
    } on AuthException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(loading: false, error: '注册失败，请检查网络');
      rethrow;
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    state = AuthState();
  }

  void clearError() => state = state.copyWith(error: '');
}
