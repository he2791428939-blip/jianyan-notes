import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/note_model.dart';
import '../providers/note_providers.dart';
import '../widgets/markdown_text.dart';

class DetailScreen extends ConsumerWidget {
  final String id;
  const DetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteProvider(id));
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? AppColors.darkText : AppColors.lightText;
    final textSec = dark ? AppColors.darkTextSec : AppColors.lightTextSec;

    return noteAsync.when(
      data: (note) {
        if (note == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('笔记')),
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.note_alt_outlined, size: 56, color: textSec.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text('笔记不存在或已被删除', style: TextStyle(fontSize: 15, color: textSec)),
              ]),
            ),
          );
        }

        final n = note;
        return Scaffold(
          appBar: AppBar(
            title: const Text('笔记'),
            actions: [
              IconButton(icon: const Icon(Icons.edit_outlined), tooltip: '编辑',
                  onPressed: () => context.push('/editor/${n.id}')),
              IconButton(icon: const Icon(Icons.delete_outline), tooltip: '删除',
                  onPressed: () => _showDeleteDialog(context, ref, n)),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (n.imagePath != null && n.imagePath!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(n.imagePath!), width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            height: 200, color: dark ? AppColors.darkSurface : AppColors.lightSurface,
                            child: Icon(Icons.broken_image, color: textSec))),
                  ),
                ),
              if (n.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(n.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: text)),
                ),
              if (n.content.isNotEmpty)
                MarkdownText(n.content, baseSize: 16, textColor: text, accentColor: AppColors.primary, lineHeight: 1.7),
              if (n.title.isEmpty && n.content.isEmpty)
                Center(child: Text('空笔记', style: TextStyle(color: textSec))),
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Text('更新于 ${DateFormat('yyyy年M月d日 HH:mm').format(n.updatedAt)}',
                    style: TextStyle(fontSize: 12, color: textSec)),
              ),
              if (n.folder.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('📁 ${n.folder}',
                        style: TextStyle(fontSize: 12, color: AppColors.primary)),
                  ),
                ),
            ]),
          ),
        );
      },
      loading: () => Scaffold(appBar: AppBar(title: const Text('笔记')), body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(title: const Text('笔记')), body: Center(child: Text('加载失败: $e'))),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, NoteModel note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除笔记'),
        content: Text('确定要删除「${note.title.isEmpty ? '无标题' : note.title}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          TextButton(
            onPressed: () {
              ref.read(noteActionsProvider.notifier).delete(note);
              Navigator.of(ctx).pop();
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
