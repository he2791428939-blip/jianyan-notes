import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/note_providers.dart';

/// 登录/注册页面。
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();
  bool _isRegister = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pw = _pwCtrl.text.trim();
    if (email.isEmpty || pw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写完整')));
      return;
    }
    if (_isRegister && pw != _pw2Ctrl.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('两次密码不一致')));
      return;
    }
    final auth = ref.read(authProvider.notifier);
    try {
      if (_isRegister) {
        await auth.register(email, pw);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('注册成功，请登录')));
        setState(() => _isRegister = false);
      } else {
        await auth.login(email, pw);
        if (mounted) {
          final state = ref.read(authProvider);
          if (state.user != null) {
            await ref.read(noteActionsProvider.notifier).syncOnLogin(state.user!.id);
          }
          if (context.mounted) context.pop();
        }
      }
    } on Exception catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final primary = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.note_alt_outlined, size: 56, color: AppColors.primary),
                const SizedBox(height: 8),
                Text('简言笔记', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: primary)),
                const SizedBox(height: 4),
                Text(_isRegister ? '创建账号，云端同步笔记' : '登录账号，同步你的笔记',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: '邮箱地址', prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                    filled: true, fillColor: AppColors.lightSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pwCtrl, obscureText: true,
                  decoration: InputDecoration(
                    hintText: '密码', prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.primary),
                    filled: true, fillColor: AppColors.lightSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                if (_isRegister) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pw2Ctrl, obscureText: true,
                    decoration: InputDecoration(
                      hintText: '确认密码', prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.primary),
                      filled: true, fillColor: AppColors.lightSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: state.loading ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: state.loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isRegister ? '注 册' : '登 录', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() { _isRegister = !_isRegister; }),
                  child: Text(_isRegister ? '已有账号？登录' : '还没有账号？立即注册'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text('跳过，继续本地使用', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
