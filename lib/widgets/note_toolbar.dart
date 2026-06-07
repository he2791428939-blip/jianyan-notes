import 'package:flutter/material.dart';
import '../core/theme.dart';

/// 编辑页面底部工具栏。
class NoteToolbar extends StatelessWidget {
  final VoidCallback onPickImage;
  final VoidCallback? onBold;
  final VoidCallback? onItalic;

  const NoteToolbar({
    super.key,
    required this.onPickImage,
    this.onBold,
    this.onItalic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.15),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _ToolbarButton(
            icon: Icons.image_outlined,
            label: '图片',
            onTap: onPickImage,
          ),
          const SizedBox(width: 24),
          _ToolbarButton(
            icon: Icons.format_bold,
            label: '加粗',
            onTap: onBold ?? () {},
          ),
          const SizedBox(width: 24),
          _ToolbarButton(
            icon: Icons.format_italic,
            label: '斜体',
            onTap: onItalic ?? () {},
          ),
          const Spacer(),
          Text(
            'V1 仅支持图片',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: AppColors.textPrimary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
