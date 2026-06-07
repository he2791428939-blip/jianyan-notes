import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> _addCustomBg() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920);
    if (picked == null) return;

    final bg = await ref.read(allBackgroundsProvider.notifier).addCustom(picked.path);
    await ref.read(backgroundProvider.notifier).select(bg);
  }

  void _showDeleteDialog(AppBackground bg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除背景'),
        content: const Text('确定要删除这个自定义背景吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              ref.read(allBackgroundsProvider.notifier).removeCustom(bg.id);
              ref.read(backgroundProvider.notifier).select(AppBackground.presets[0]);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allBgAsync = ref.watch(allBackgroundsProvider);
    final currentBgAsync = ref.watch(backgroundProvider);

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
                  allBgAsync.when(
                    data: (all) => Text(
                      '${all.length} 种可选',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 80,
              child: allBgAsync.when(
                data: (all) {
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      // 预设 + 自定义
                      ...all.map((bg) => _buildBgTile(bg, currentBgAsync)),
                      // "+" 添加按钮
                      _buildAddTile(),
                    ],
                  );
                },
                loading: () => const Center(
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, __) => const SizedBox.shrink(),
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

  Widget _buildBgTile(AppBackground bg, AsyncValue<AppBackground> currentAsync) {
    final selected = currentAsync.maybeWhen(data: (b) => b.id == bg.id, orElse: () => false);

    Widget tile = GestureDetector(
      onTap: () => ref.read(backgroundProvider.notifier).select(bg),
      onLongPress: bg.isPreset ? null : () => _showDeleteDialog(bg),
      child: Container(
        width: 64,
        margin: const EdgeInsets.symmetric(horizontal: 4),
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
          image: bg.imagePath != null
              ? DecorationImage(image: FileImage(File(bg.imagePath!)), fit: BoxFit.cover)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 22)
            else
              const SizedBox(width: 22, height: 22),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: tile,
    );
  }

  Widget _buildAddTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: _addCustomBg,
        child: Container(
          width: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3), width: 1.5, style: BorderStyle.solid),
            color: AppColors.surface,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 22, color: AppColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 2),
              Text('添加', style: TextStyle(fontSize: 10, color: AppColors.textSecondary.withValues(alpha: 0.5))),
            ],
          ),
        ),
      ),
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
