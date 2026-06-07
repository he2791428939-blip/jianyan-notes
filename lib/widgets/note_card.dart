import 'dart:io';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/note_model.dart';

/// 网格卡片组件 — 用于首页笔记列表。
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
            Expanded(
              flex: 3,
              child: hasImage
                  ? Image.file(
                      File(note.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ColorBlock(
                        bgColor: bgColor,
                        iconColor: iconColor,
                        title: note.title,
                      ),
                    )
                  : _ColorBlock(
                      bgColor: bgColor,
                      iconColor: iconColor,
                      title: note.title,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                note.title.isEmpty ? '无标题' : note.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
