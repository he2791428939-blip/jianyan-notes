import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/note_model.dart';
import '../providers/note_providers.dart';

/// 回收站 — 已删除笔记可恢复或彻底删除。
class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashAsync = ref.watch(trashProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textSec = dark ? AppColors.darkTextSec : AppColors.lightTextSec;

    return trashAsync.when(
      data: (notes) {
        if (notes.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.delete_outline, size: 64, color: textSec.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('回收站是空的', style: TextStyle(fontSize: 16, color: textSec.withValues(alpha: 0.6))),
            const SizedBox(height: 4),
            Text('删除的笔记会出现在这里', style: TextStyle(fontSize: 13, color: textSec.withValues(alpha: 0.45))),
          ]));
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              color: AppColors.danger.withValues(alpha: 0.06),
              child: Row(children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.danger.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Text('${notes.length} 条笔记在回收站中',
                    style: TextStyle(fontSize: 13, color: textSec.withValues(alpha: 0.8))),
              ]),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: notes.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                itemBuilder: (_, i) => _TrashItem(
                  note: notes[i],
                  dark: dark,
                  onRestore: () => _confirmRestore(context, ref, notes[i]),
                  onDelete: () => _confirmDeleteForever(context, ref, notes[i]),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }

  void _confirmRestore(BuildContext context, WidgetRef ref, NoteModel note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复笔记'),
        content: Text('恢复「${note.title.isEmpty ? '无标题' : note.title}」吗？会回到之前的分类。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () { ref.read(noteActionsProvider.notifier).restore(note.id); Navigator.pop(ctx); },
              child: const Text('恢复')),
        ],
      ),
    );
  }

  void _confirmDeleteForever(BuildContext context, WidgetRef ref, NoteModel note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('彻底删除'),
        content: Text('「${note.title.isEmpty ? '无标题' : note.title}」将被永久删除，不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () { ref.read(noteActionsProvider.notifier).deleteForever(note); Navigator.pop(ctx); },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('彻底删除'),
          ),
        ],
      ),
    );
  }
}

class _TrashItem extends StatelessWidget {
  final NoteModel note;
  final bool dark;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _TrashItem({required this.note, required this.dark, required this.onRestore, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final text = dark ? AppColors.darkText : AppColors.lightText;
    final textSec = dark ? AppColors.darkTextSec : AppColors.lightTextSec;

    return ListTile(
      leading: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
            color: AppColors.cardColor(note.colorIndex, dark: dark), borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Text(note.title.isNotEmpty ? note.title.characters.first : '📝',
            style: TextStyle(fontSize: 20, color: AppColors.cardIconColor(note.colorIndex))),
      ),
      title: Text(note.title.isEmpty ? '无标题' : note.title,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: text)),
      subtitle: note.deletedAt != null
          ? Text('删除于 ${DateFormat('M月d日 HH:mm').format(note.deletedAt!)}',
              style: TextStyle(fontSize: 12, color: textSec.withValues(alpha: 0.7)))
          : null,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: const Icon(Icons.restore, size: 20), tooltip: '恢复', onPressed: onRestore,
            color: AppColors.primary),
        IconButton(icon: const Icon(Icons.delete_forever, size: 20), tooltip: '彻底删除', onPressed: onDelete,
            color: AppColors.danger.withValues(alpha: 0.7)),
      ]),
    );
  }
}
