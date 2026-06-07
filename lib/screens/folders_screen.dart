import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/note_providers.dart';

/// 分类管理页 — 列表 + 计数 + 新建/重命名/删除。
class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final foldersAsync = ref.watch(foldersProvider);

    return notesAsync.when(
      data: (allNotes) {
        final uncategorized = allNotes.where((n) => n.folder.isEmpty).length;
        final folders = foldersAsync.maybeWhen(
          data: (f) => f,
          orElse: () => allNotes
              .map((n) => n.folder)
              .where((f) => f.isNotEmpty)
              .toSet()
              .toList()
            ..sort(),
        );

        return Scaffold(
          appBar: AppBar(title: const Text('分类管理')),
          body: folders.isEmpty && uncategorized == allNotes.length
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_open,
                          size: 56,
                          color: AppColors.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text('还没有分类',
                          style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.6))),
                      const SizedBox(height: 4),
                      Text('编辑笔记时可以添加分类',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.45))),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    if (uncategorized > 0)
                      _FolderTile(
                        icon: Icons.inbox_outlined,
                        label: '未分类',
                        count: uncategorized,
                        color: AppColors.cardColors[0],
                        iconColor: AppColors.cardIconColors[0],
                        onTap: () => context.push('/folder/', extra: ''),
                      ),
                    ...folders.map((f) {
                      final count = allNotes.where((n) => n.folder == f).length;
                      final idx = f.hashCode.abs() % AppColors.cardColors.length;
                      return _FolderTile(
                        icon: Icons.folder_outlined,
                        label: f,
                        count: count,
                        color: AppColors.cardColors[idx],
                        iconColor: AppColors.cardIconColors[idx],
                        onTap: () =>
                            context.push('/folder/${Uri.encodeComponent(f)}', extra: f),
                      );
                    }),
                  ],
                ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }
}

class _FolderTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _FolderTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count 条',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withValues(alpha: 0.7))),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
      onTap: onTap,
    );
  }
}
