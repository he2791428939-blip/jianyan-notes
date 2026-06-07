import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../core/theme.dart';
import '../models/note_model.dart';
import '../providers/note_providers.dart';
import '../widgets/note_toolbar.dart';

/// 编辑页面 — 支持新建和编辑两种模式。
class EditorScreen extends ConsumerStatefulWidget {
  final String? id;

  const EditorScreen({super.key, this.id});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final _picker = ImagePicker();
  String? _imagePath;
  bool _isSaving = false;
  bool _hasChanges = false;
  NoteModel? _existingNote;

  bool get _isEditing => widget.id != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);

    if (_isEditing) {
      _loadNote();
    }
  }

  void _onChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _loadNote() async {
    final noteAsync = ref.read(noteProvider(widget.id!));
    noteAsync.whenData((note) {
      if (note != null && mounted) {
        setState(() {
          _existingNote = note;
          _titleController.text = note.title;
          _contentController.text = note.content;
          _imagePath = note.imagePath;
          _hasChanges = false;
        });
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final actions = ref.read(noteActionsProvider.notifier);
      if (_isEditing && _existingNote != null) {
        final updated = _existingNote!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          imagePath: _imagePath,
          clearImage: _imagePath == null,
        );
        await actions.update(updated);
      } else {
        await actions.create(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          imagePath: _imagePath,
        );
      }
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(source: source, maxWidth: 1920);
    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(p.join(appDir.path, 'images'));
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile =
        await File(picked.path).copy(p.join(imageDir.path, fileName));

    setState(() {
      _imagePath = savedFile.path;
      _hasChanges = true;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('放弃编辑？'),
        content: const Text('你有未保存的修改，确定要离开吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('继续编辑'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('放弃'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                context.pop();
              }
            },
          ),
          title: Text(_isEditing ? '编辑笔记' : '新建笔记'),
          actions: [
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: _hasChanges ? _save : null,
                    child: Text(
                      '保存',
                      style: TextStyle(
                        color: _hasChanges
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ],
        ),
        body: Column(
          children: [
            if (_imagePath != null)
              Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    color: AppColors.surface,
                    child: Image.file(
                      File(_imagePath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          AppColors.textPrimary.withValues(alpha: 0.6),
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            size: 16, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _imagePath = null;
                            _hasChanges = true;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(hintText: '标题...'),
                textInputAction: TextInputAction.next,
              ),
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: TextField(
                  controller: _contentController,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                  decoration: const InputDecoration(hintText: '开始写笔记...'),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ),
            NoteToolbar(onPickImage: _pickImage),
          ],
        ),
      ),
    );
  }
}
