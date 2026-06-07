import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';

/// 设置页面。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentVersion = '加载中...';
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final v = await UpdateService.currentVersion();
    if (mounted) setState(() => _currentVersion = v);
  }

  Future<void> _checkUpdate() async {
    if (_checking) return;
    setState(() => _checking = true);

    try {
      final info = await UpdateService.checkUpdate();
      if (mounted) {
        setState(() => _checking = false);
        if (info != null) {
          showDialog(context: context, builder: (_) => UpdateDialog(updateInfo: info));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已是最新版本')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _checking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('检查更新失败，请检查网络连接')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 8),
        // 版本信息
        _Section(
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.primary),
              title: const Text('当前版本'),
              subtitle: Text(_currentVersion),
            ),
          ],
        ),
        // 更新
        _Section(
          children: [
            ListTile(
              leading: const Icon(Icons.system_update, color: AppColors.primary),
              title: const Text('检查更新'),
              subtitle: const Text('检查并下载最新版本'),
              trailing: _checking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              onTap: _checkUpdate,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            '简言笔记 — 简洁记录每一天',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final List<Widget> children;
  const _Section({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(children: children),
    );
  }
}
