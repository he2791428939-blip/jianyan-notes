import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/note_providers.dart';

/// 笔记详情页 — 只读展示。
class DetailScreen extends ConsumerWidget {
  final String id;

  const DetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteProvider(id));

    return noteAsync.when(
      data: (note) {
        if (note == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('笔记')),
            body: const Center(child: Text('笔记不存在或已被删除')),
          );
        }

        final n = note; // local variable to help type inference
        return Scaffold(
          appBar: AppBar(
            title: const Text('笔记'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: '编辑',
                onPressed: () => context.push('/editor/${n.id}'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: '删除',
                onPressed: () =>
                    _showDeleteDialog(context, ref, n.id, n.title),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (n.imagePath != null && n.imagePath!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(n.imagePath!),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: AppColors.surface,
                          child: const Icon(Icons.broken_image,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                if (n.title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      n.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                if (n.content.isNotEmpty)
                  Text(
                    n.content,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      height: 1.7,
                    ),
                  ),
                if (n.title.isEmpty && n.content.isEmpty)
                  const Center(
                    child: Text(
                      '空笔记',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Text(
                    '更新于 ${DateFormat('yyyy年M月d日 HH:mm').format(n.updatedAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('笔记')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('笔记')),
        body: Center(child: Text('加载失败: $e')),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context, WidgetRef ref, String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除笔记'),
        content:
            Text('确定要删除「${title.isEmpty ? '无标题' : title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(noteActionsProvider.notifier).delete(id);
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
