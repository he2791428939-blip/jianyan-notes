import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/note_model.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool dark;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onLongPress,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.cardColor(note.colorIndex, dark: dark);
    final iconColor = AppColors.cardIconColor(note.colorIndex);
    final hasImage = note.imagePath != null && note.imagePath!.isNotEmpty;
    final text = dark ? AppColors.darkText : AppColors.lightText;
    final textSec = dark ? AppColors.darkTextSec : AppColors.lightTextSec;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: hasImage
                  ? Image.file(File(note.imagePath!), fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ColorBlock(bgColor: bgColor, iconColor: iconColor, title: note.title))
                  : _ColorBlock(bgColor: bgColor, iconColor: iconColor, title: note.title),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
              child: Text(note.title.isEmpty ? '无标题' : note.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
            ),
            if (note.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
                child: Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: textSec.withValues(alpha: 0.85), height: 1.35)),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(_formatTime(note.updatedAt),
                  style: TextStyle(fontSize: 11, color: textSec.withValues(alpha: 0.6))),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
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
  const _ColorBlock({required this.bgColor, required this.iconColor, required this.title});

  @override
  Widget build(BuildContext context) {
    final char = title.isNotEmpty ? title.characters.first : '📝';
    final isEmoji = char.runes.any((r) => r > 127);
    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: Text(isEmoji ? char : (title.isNotEmpty ? char : '📝'),
          style: TextStyle(fontSize: isEmoji ? 32 : 28, color: iconColor, fontWeight: FontWeight.w600)),
    );
  }
}
