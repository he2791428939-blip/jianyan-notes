import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../models/note_model.dart';
import '../providers/note_providers.dart';
import '../widgets/note_card.dart';
import 'folders_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? AppColors.darkText : AppColors.lightText;
    final textSec = dark ? AppColors.darkTextSec : AppColors.lightTextSec;

    final pages = [
      notesAsync.when(
        data: (notes) => _buildNotesGrid(notes, dark, text, textSec),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
      const FoldersScreen(),
      const SettingsScreen(),
    ];

    final body = IndexedStack(index: _tab, children: pages);

    return Scaffold(
      appBar: _tab == 2
          ? AppBar(title: const Text('设置'))
          : AppBar(
              title: const Text('我的笔记'),
              actions: [
                if (_tab == 0)
                  IconButton(icon: const Icon(Icons.search), tooltip: '搜索', onPressed: () {
                    showSearch(context: context, delegate: _NoteSearchDelegate(
                      notes: notesAsync.maybeWhen(data: (n) => n, orElse: () => []),
                      dark: dark,
                      onTap: (id) => context.push('/note/$id'),
                      onDelete: (note) => _showDeleteDialog(context, note),
                    ));
                  }),
                if (_tab == 0)
                  IconButton(icon: const Icon(Icons.add), tooltip: '新建笔记', onPressed: () => context.push('/editor')),
              ],
            ),
      body: body,
      floatingActionButton: _tab == 0
          ? FloatingActionButton(onPressed: () => context.push('/editor'), child: const Icon(Icons.add))
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          const BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), label: '分类'),
          BottomNavigationBarItem(
            icon: Consumer(builder: (context, ref, _) {
              final trash = ref.watch(trashProvider);
              final hasTrash = trash.maybeWhen(data: (l) => l.isNotEmpty, orElse: () => false);
              return hasTrash
                  ? Badge(child: const Icon(Icons.settings_outlined))
                  : const Icon(Icons.settings_outlined);
            }),
            label: '设置',
          ),
        ],
      ),
    );
  }

  Widget _buildNotesGrid(List<NoteModel> notes, bool dark, Color text, Color textSec) {
    if (notes.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.note_add_outlined, size: 64, color: textSec.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('还没有笔记', style: TextStyle(fontSize: 16, color: textSec.withValues(alpha: 0.7))),
          const SizedBox(height: 8),
          Text('点击右下角 ＋ 创建第一条笔记', style: TextStyle(fontSize: 14, color: textSec.withValues(alpha: 0.5))),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(notesProvider),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.72,
        ),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return Dismissible(
            key: Key(note.id),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white, size: 28),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('删除笔记'),
                  content: Text('确定要删除「${note.title.isNotEmpty ? note.title : '无标题'}」吗？'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                      child: const Text('删除'),
                    ),
                  ],
                ),
              ) ?? false;
            },
            onDismissed: (_) => ref.read(noteActionsProvider.notifier).delete(note),
            child: NoteCard(
              note: note,
              dark: dark,
              onTap: () => context.push('/note/${note.id}'),
              onLongPress: () => _showDeleteDialog(context, note),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, NoteModel note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除笔记'),
        content: Text('确定要删除「${note.title.isEmpty ? '无标题' : note.title}」吗？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          TextButton(
            onPressed: () {
              ref.read(noteActionsProvider.notifier).delete(note);
              Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

// ── 搜索代理 ──────────────────────────────────────────

class _NoteSearchDelegate extends SearchDelegate<String> {
  final List<NoteModel> notes;
  final bool dark;
  final void Function(String id) onTap;
  final void Function(NoteModel note) onDelete;

  _NoteSearchDelegate({required this.notes, required this.dark, required this.onTap, required this.onDelete})
      : super(searchFieldLabel: '搜索标题或正文...');

  List<NoteModel> _results(String q) {
    if (q.isEmpty) return notes;
    final l = q.toLowerCase();
    return notes.where((n) => n.title.toLowerCase().contains(l) || n.content.toLowerCase().contains(l)).toList();
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) => _buildList(context, _results(query));

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context, _results(query));

  Widget _buildList(BuildContext context, List<NoteModel> items) {
    final textSec = dark ? AppColors.darkTextSec : AppColors.lightTextSec;
    if (query.isEmpty && items.isEmpty) return const SizedBox.shrink();
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off, size: 48, color: textSec.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text('没有找到「$query」', style: TextStyle(color: textSec.withValues(alpha: 0.6))),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
      itemBuilder: (_, i) {
        final n = items[i];
        return Dismissible(
          key: Key('search_${n.id}'),
          direction: DismissDirection.endToStart,
          background: Container(color: AppColors.danger, alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
          confirmDismiss: (_) async {
            onDelete(n);
            close(context, '');
            return false; // 不执行 onDismissed，由 onDelete 处理
          },
          child: ListTile(
            leading: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                  color: AppColors.cardColor(n.colorIndex, dark: dark), borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Text(n.title.isNotEmpty ? n.title.characters.first : '📝',
                  style: TextStyle(fontSize: 20, color: AppColors.cardIconColor(n.colorIndex))),
            ),
            title: Text(n.title.isEmpty ? '无标题' : n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: n.content.isNotEmpty
                ? Text(n.content, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: textSec.withValues(alpha: 0.8)))
                : null,
            onTap: () {
              onTap(n.id);
              close(context, n.id);
            },
          ),
        );
      },
    );
  }
}
