import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/bg_provider.dart';
import '../services/background_service.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';

/// 设置页面。
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
    final currentBg = ref.watch(backgroundProvider);

    return ListView(
      children: [
        const SizedBox(height: 8),
        // 背景选择
        _Section(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.palette_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('首页背景', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text('${AppBackground.presets.length} 种可选',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.6))),
                ],
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: AppBackground.presets.map((bg) {
                  final selected = currentBg.maybeWhen(
                    data: (b) => b.id == bg.id,
                    orElse: () => false,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => ref.read(backgroundProvider.notifier).select(bg),
                      child: Container(
                        width: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.15),
                            width: selected ? 2.5 : 1,
                          ),
                          gradient: bg.gradient != null
                              ? LinearGradient(colors: bg.gradient!, begin: Alignment.topCenter, end: Alignment.bottomCenter)
                              : null,
                          color: bg.color,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (selected)
                              const Icon(Icons.check_circle, color: AppColors.primary, size: 22)
                            else
                              const Icon(Icons.circle_outlined,
                                  size: 22,
                                  color: Color(0x00000000)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
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
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              onTap: _checkUpdate,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Text('简言笔记 — 简洁记录每一天',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.5))),
        ),
        const SizedBox(height: 32),
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
