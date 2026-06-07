import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../providers/bg_provider.dart';
import '../providers/note_providers.dart';
import '../providers/theme_provider.dart';
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
  String _serverUrl = '';
  bool _checking = false;
  bool _urlEditing = false;
  late final TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final v = await UpdateService.currentVersion();
    final u = await UpdateService.getCustomUrl();
    if (mounted) {
      setState(() {
        _currentVersion = v;
        _serverUrl = u.isNotEmpty ? u : 'jsDelivr CDN (内置)';
        _urlCtrl.text = u;
      });
    }
  }

  Future<void> _saveUrl() async {
    final url = _urlCtrl.text.trim();
    await UpdateService.saveCustomUrl(url);
    setState(() {
      _serverUrl = url;
      _urlEditing = false;
    });
  }

  Future<void> _checkUpdate() async {
    if (_checking) return;
    setState(() => _checking = true);
    final (info, error) = await UpdateService.checkUpdate();
    if (mounted) {
      setState(() => _checking = false);
      if (info != null) {
        showDialog(context: context, builder: (_) => UpdateDialog(updateInfo: info));
      } else if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已是最新版本')),
        );
      }
    }
  }

  // ── 背景相关 ────────────────────────────────────────

  Future<void> _addCustomBg() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920);
    if (picked == null) return;
    final bg = await ref.read(allBackgroundsProvider.notifier).addCustom(picked.path);
    await ref.read(backgroundProvider.notifier).select(bg);
  }

  void _showBgDeleteDialog(AppBackground bg) {
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

  // ── UI ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final allBgAsync = ref.watch(allBackgroundsProvider);
    final curBgAsync = ref.watch(backgroundProvider);

    return ListView(
      children: [
        const SizedBox(height: 8),

        // ═══ 主题 ═══
        _Section(
          children: [
            SwitchListTile(
              secondary: Icon(
                ref.watch(darkModeProvider) ? Icons.dark_mode : Icons.light_mode,
                color: AppColors.primary,
              ),
              title: const Text('深色模式'),
              subtitle: Text(ref.watch(darkModeProvider) ? '已开启 — 夜间更护眼' : '已关闭'),
              value: ref.watch(darkModeProvider),
              onChanged: (_) => ref.read(darkModeProvider.notifier).toggle(),
            ),
          ],
        ),

        // ═══ 回收站 ═══
        _Section(
          children: [
            Consumer(builder: (context, ref, _) {
              final trashAsync = ref.watch(trashProvider);
              final count = trashAsync.maybeWhen(data: (l) => l.length, orElse: () => 0);
              return ListTile(
                leading: Icon(count > 0 ? Icons.delete : Icons.delete_outline, color: count > 0 ? AppColors.danger : AppColors.primary),
                title: const Text('回收站'),
                subtitle: Text(count > 0 ? '$count 条待清理' : '暂无已删除笔记',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.7))),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onTap: () => context.push('/trash'),
              );
            }),
          ],
        ),

        // ═══ 背景选择 ═══
        _Section(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                const Icon(Icons.palette_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text('首页背景', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                const Spacer(),
                allBgAsync.when(
                  data: (all) => Text('${all.length} 种可选',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.6))),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ]),
            ),
            SizedBox(
              height: 80,
              child: allBgAsync.when(
                data: (all) => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    ...all.map((bg) => _bgTile(bg, curBgAsync)),
                    _addBgTile(),
                  ],
                ),
                loading: () => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),

        // ═══ 更新服务器 ═══
        _Section(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                const Icon(Icons.dns_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text('更新服务器', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                const Spacer(),
                if (_urlEditing)
                  TextButton(onPressed: _saveUrl, child: const Text('保存'))
                else
                  TextButton(onPressed: () => setState(() => _urlEditing = true), child: const Text('编辑')),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _urlCtrl,
                readOnly: !_urlEditing,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'http://你的IP:8888',
                  hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                  border: _urlEditing ? const OutlineInputBorder() : InputBorder.none,
                  contentPadding: _urlEditing ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10) : EdgeInsets.zero,
                  filled: _urlEditing,
                  fillColor: AppColors.surface,
                ),
              ),
            ),
          ],
        ),

        // ═══ 版本 + 更新 ═══
        _Section(
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.primary),
              title: const Text('当前版本'),
              subtitle: Text(_currentVersion),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.system_update, color: AppColors.primary),
              title: const Text('检查更新'),
              subtitle: Text(
                  _urlCtrl.text.isNotEmpty
                      ? _serverUrl
                      : _serverUrl.isNotEmpty
                          ? '内置默认 · 无需配置'
                          : '请先配置服务器地址',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.6))),
              trailing: _checking
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              onTap: _checkUpdate,
            ),
          ],
        ),

        const SizedBox(height: 24),
        Center(child: Text('简言笔记 — 简洁记录每一天',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.5)))),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _bgTile(AppBackground bg, AsyncValue<AppBackground> curAsync) {
    final sel = curAsync.maybeWhen(data: (b) => b.id == bg.id, orElse: () => false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => ref.read(backgroundProvider.notifier).select(bg),
        onLongPress: bg.isPreset ? null : () => _showBgDeleteDialog(bg),
        child: Container(
          width: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.15),
              width: sel ? 2.5 : 1,
            ),
            gradient: bg.gradient != null
                ? LinearGradient(colors: bg.gradient!, begin: Alignment.topCenter, end: Alignment.bottomCenter)
                : null,
            color: bg.color,
            image: bg.imagePath != null
                ? DecorationImage(image: FileImage(File(bg.imagePath!)), fit: BoxFit.cover)
                : null,
          ),
          child: Center(
            child: sel
                ? const Icon(Icons.check_circle, color: AppColors.primary, size: 22)
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _addBgTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: _addCustomBg,
        child: Container(
          width: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3), width: 1.5),
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

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
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
