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
/// 返回时自动保存。
class EditorScreen extends ConsumerStatefulWidget {
  final String? id;
  final String? initialFolder;

  const EditorScreen({super.key, this.id, this.initialFolder});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final FocusNode _titleFocus;
  late final FocusNode _contentFocus;
  final _picker = ImagePicker();
  String? _imagePath;
  String _folder = '';
  bool _isSaving = false;
  NoteModel? _existingNote;
  bool _didSave = false;

  bool get _isEditing => widget.id != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _titleFocus = FocusNode();
    _contentFocus = FocusNode();
    _folder = widget.initialFolder ?? '';

    if (_isEditing) {
      _loadNote();
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
          _folder = note.folder;
        });
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving || _didSave) return;
    setState(() => _isSaving = true);

    try {
      final actions = ref.read(noteActionsProvider.notifier);
      if (_isEditing && _existingNote != null) {
        final updated = _existingNote!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          imagePath: _imagePath,
          folder: _folder,
          clearImage: _imagePath == null,
        );
        await actions.update(updated);
      } else {
        await actions.create(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          imagePath: _imagePath,
          folder: _folder,
        );
      }
      _didSave = true;
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

  /// 返回上一页：先保存，再 pop。
  Future<void> _goBack() async {
    await _save();
    if (mounted) {
      context.pop();
    }
  }

  // ── 文本格式操作 ──────────────────────────────────

  /// 获取当前焦点所在的 TextEditingController。
  TextEditingController? get _focusedController {
    if (_titleFocus.hasFocus) return _titleController;
    if (_contentFocus.hasFocus) return _contentController;
    return _contentController; // 默认正文
  }

  /// 在光标处插入 markdown 包围标记，或包裹选中文本。
  void _wrapSelection(String open, String close) {
    final ctrl = _focusedController!;
    final text = ctrl.text;
    final sel = ctrl.selection;
    final start = sel.start;
    final end = sel.end;

    if (start < 0) return;

    if (sel.isCollapsed) {
      // 无选中：插入 **|**
      const placeholder = '文本';
      final newText = text.replaceRange(start, end, '$open$placeholder$close');
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + open.length + placeholder.length),
      );
    } else {
      // 有选中：用标记包裹选中文本
      final selected = text.substring(start, end);
      final newText = text.replaceRange(start, end, '$open$selected$close');
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + open.length + selected.length + close.length),
      );
    }
  }

  void _insertBold() => _wrapSelection('**', '**');
  void _insertItalic() => _wrapSelection('*', '*');
  void _insertHeading() {
    final ctrl = _focusedController!;
    final text = ctrl.text;
    // 在当前行首插入 ##
    final lineStart = _lineStart(text, ctrl.selection.start);
    final newText = text.replaceRange(lineStart, lineStart, '## ');
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: lineStart + 3),
    );
  }

  void _insertList() {
    final ctrl = _focusedController!;
    final text = ctrl.text;
    final lineStart = _lineStart(text, ctrl.selection.start);
    final newText = text.replaceRange(lineStart, lineStart, '- ');
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: lineStart + 2),
    );
  }

  int _lineStart(String text, int pos) {
    if (pos <= 0) return 0;
    final prevNewline = text.lastIndexOf('\n', pos - 1);
    return prevNewline == -1 ? 0 : prevNewline + 1;
  }

  void _pickImage() async {
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

    setState(() => _imagePath = savedFile.path);
  }

  Widget _buildFolderRow() {
    final foldersAsync = ref.watch(foldersProvider);
    final dbFolders = foldersAsync.maybeWhen(data: (f) => f, orElse: () => <String>[]);

    // 合并本地新建但还没存笔记的分类
    final allFolders = [...dbFolders];
    if (_folder.isNotEmpty && !allFolders.contains(_folder)) {
      allFolders.insert(0, _folder);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _FolderChip(
              label: '无分类',
              selected: _folder.isEmpty,
              onTap: () => setState(() => _folder = ''),
            ),
            ...allFolders.map((f) => _FolderChip(
                  label: f,
                  selected: _folder == f,
                  onTap: () => setState(() => _folder = f),
                )),
            _FolderChip(
              label: '+ 新建',
              selected: false,
              isAdd: true,
              onTap: () => _showNewFolderDialog(),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewFolderDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建分类'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入分类名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                setState(() => _folder = name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
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
                  onPressed: _goBack,
                  child: const Text(
                    '保存',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          // 分类选择器
          _buildFolderRow(),
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
                        setState(() => _imagePath = null);
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
              focusNode: _titleFocus,
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
                focusNode: _contentFocus,
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
          NoteToolbar(
            onPickImage: _pickImage,
            onBold: _insertBold,
            onItalic: _insertItalic,
            onHeading: _insertHeading,
            onList: _insertList,
          ),
        ],
      ),
      ),
    );
  }
}

// ── 分类标签 ──────────────────────────────────────────

class _FolderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isAdd;
  final VoidCallback onTap;

  const _FolderChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isAdd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isAdd
                ? Colors.transparent
                : selected
                    ? AppColors.primary
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isAdd
                  ? AppColors.textSecondary.withValues(alpha: 0.4)
                  : selected
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected
                  ? Colors.white
                  : isAdd
                      ? AppColors.primary
                      : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
