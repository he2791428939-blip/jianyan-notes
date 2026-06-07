import 'package:flutter/material.dart';
import '../core/theme.dart';

/// 编辑页面底部工具栏 — 图片、加粗、斜体、标题、列表。
class NoteToolbar extends StatelessWidget {
  final VoidCallback onPickImage;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onHeading;
  final VoidCallback onList;

  const NoteToolbar({
    super.key,
    required this.onPickImage,
    required this.onBold,
    required this.onItalic,
    required this.onHeading,
    required this.onList,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.12),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _TB(icon: Icons.image_outlined, label: '图片', onTap: onPickImage),
          _TB(icon: Icons.format_bold, label: 'B', onTap: onBold),
          _TB(icon: Icons.format_italic, label: 'I', onTap: onItalic),
          _TB(icon: Icons.title, label: 'H', onTap: onHeading),
          _TB(icon: Icons.format_list_bulleted, label: '列', onTap: onList),
          const Spacer(),
          Text('Markdown', style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}

class _TB extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _TB({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: AppColors.textPrimary),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
