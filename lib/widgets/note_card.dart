import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/note_model.dart';

/// 网格卡片 — 颜色块/图片 + 标题 + 正文预览 + 时间戳。
class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.cardColor(note.colorIndex);
    final iconColor = AppColors.cardIconColor(note.colorIndex);
    final hasImage = note.imagePath != null && note.imagePath!.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 上半部分 — 颜色块或图片预览
            Expanded(
              flex: 2,
              child: hasImage
                  ? Image.file(
                      File(note.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ColorBlock(
                        bgColor: bgColor, iconColor: iconColor, title: note.title),
                    )
                  : _ColorBlock(
                      bgColor: bgColor, iconColor: iconColor, title: note.title),
            ),
            // 标题
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
              child: Text(
                note.title.isEmpty ? '无标题' : note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // 正文预览
            if (note.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
                child: Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                ),
              ),
            const Spacer(),
            // 时间戳
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                _formatTime(note.updatedAt),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return DateFormat('M月d日').format(t);
  }
}

class _ColorBlock extends StatelessWidget {
  final Color bgColor;
  final Color iconColor;
  final String title;

  const _ColorBlock({
    required this.bgColor,
    required this.iconColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final char = title.isNotEmpty ? title.characters.first : '📝';
    final isEmoji = char.runes.any((r) => r > 127);

    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: Text(
        isEmoji ? char : (title.isNotEmpty ? char : '📝'),
        style: TextStyle(
          fontSize: isEmoji ? 32 : 28,
          color: iconColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
