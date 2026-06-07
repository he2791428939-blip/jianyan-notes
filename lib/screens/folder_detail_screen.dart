import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/note_providers.dart';
import '../widgets/note_card.dart';

/// 分类详情 — 展示该分类下的所有笔记。
class FolderDetailScreen extends ConsumerWidget {
  final String folder;

  const FolderDetailScreen({super.key, required this.folder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allNotesAsync = ref.watch(notesProvider);

    return allNotesAsync.when(
      data: (all) {
        final notes = folder.isEmpty
            ? all.where((n) => n.folder.isEmpty).toList()
            : all.where((n) => n.folder == folder).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(folder.isEmpty ? '未分类' : folder),
          ),
          body: notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.note_alt_outlined,
                          size: 56,
                          color: AppColors.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text('此分类下暂无笔记',
                          style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.6))),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: notes.length,
                  itemBuilder: (_, i) => NoteCard(
                    note: notes[i],
                    onTap: () => context.push('/note/${notes[i].id}'),
                  ),
                ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(folder.isEmpty ? '未分类' : folder)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(folder.isEmpty ? '未分类' : folder)),
        body: Center(child: Text('加载失败: $e')),
      ),
    );
  }
}
