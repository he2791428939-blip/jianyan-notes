import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/update_service.dart';

/// 更新对话框 — 含下载进度。
class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _downloading = false;
  bool _downloadDone = false;
  double _progress = 0;
  String? _error;

  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _error = null;
    });

    try {
      final path = await UpdateService.downloadApk(
        widget.updateInfo.url,
        (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadDone = true;
        });
      }
      // 短暂延迟让用户看到"下载完成"状态
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await UpdateService.installApk(path);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = '下载失败: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.system_update, color: AppColors.primary),
          SizedBox(width: 8),
          Text('发现新版本'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本 ${widget.updateInfo.version}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
            const SizedBox(height: 8),
            if (widget.updateInfo.notes.isNotEmpty) ...[
              Text(widget.updateInfo.notes,
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.lightTextSec.withValues(alpha: 0.85))),
              const SizedBox(height: 12),
            ],
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.danger)),
              ),
            if (_downloading) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 6,
                  backgroundColor: AppColors.lightSurface,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 6),
              Text('${(_progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.lightTextSec.withValues(alpha: 0.7))),
            ],
            if (_downloadDone)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 6),
                    Text('下载完成，正在安装...',
                        style: TextStyle(fontSize: 14, color: Colors.green)),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (!_downloading && !_downloadDone)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('以后再说'),
          ),
        if (!_downloading && !_downloadDone)
          ElevatedButton(
            onPressed: _startDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('立即更新'),
          ),
      ],
    );
  }
}
