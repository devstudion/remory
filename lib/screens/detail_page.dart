import 'package:flutter/material.dart';
import '../models/memory.dart';
import '../services/supabase_service.dart';

class MemoryDetailPage extends StatefulWidget {
  final Memory memory;
  final Function(Memory) onDelete;
  final Function(Memory, String) onUpdateCategory;

  const MemoryDetailPage({
    super.key,
    required this.memory,
    required this.onDelete,
    required this.onUpdateCategory,
  });

  @override
  State<MemoryDetailPage> createState() => _MemoryDetailPageState();
}

class _MemoryDetailPageState extends State<MemoryDetailPage> {
  late Memory _currentMemory;
  final _memoController = TextEditingController();
  bool _isEditingMemo = false;
  bool _isSavingMemo = false;

  @override
  void initState() {
    super.initState();
    _currentMemory = widget.memory;
    _memoController.text = _currentMemory.memo ?? '';
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _saveMemo() async {
    setState(() => _isSavingMemo = true);
    try {
      final newMemo = _memoController.text.trim().isEmpty ? null : _memoController.text.trim();
      await SupabaseService.instance.updateMemo(_currentMemory, newMemo);
      setState(() {
        _currentMemory = Memory(
          id: _currentMemory.id,
          imageUrl: _currentMemory.imageUrl,
          category: _currentMemory.category,
          memo: newMemo,
          userId: _currentMemory.userId,
          createdAt: _currentMemory.createdAt,
        );
        _isEditingMemo = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メモを更新しました'), backgroundColor: Color(0xFF8D6E63)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('メモの更新に失敗しました: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingMemo = false);
      }
    }
  }

  Future<void> _moveCategory() async {
    String? newCat = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFFFAF6F0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '移動先のカテゴリを選択',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
            ),
            const SizedBox(height: 16),
            ...['手紙', '年賀状', '作品', 'その他'].map(
              (c) => ListTile(
                title: Text(
                  c,
                  style: TextStyle(
                    color: const Color(0xFF5D4037),
                    fontWeight: _currentMemory.category == c ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: _currentMemory.category == c
                    ? const Icon(Icons.check_circle, color: Color(0xFF8D6E63))
                    : null,
                onTap: () => Navigator.pop(context, c),
              ),
            ),
          ],
        ),
      ),
    );

    if (newCat != null && newCat != _currentMemory.category) {
      try {
        await widget.onUpdateCategory(_currentMemory, newCat);
        setState(() {
          _currentMemory = Memory(
            id: _currentMemory.id,
            imageUrl: _currentMemory.imageUrl,
            category: newCat,
            memo: _currentMemory.memo,
            userId: _currentMemory.userId,
            createdAt: _currentMemory.createdAt,
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('カテゴリを「$newCat」に移動しました'), backgroundColor: const Color(0xFF8D6E63)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('移動に失敗しました: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAF6F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.favorite_rounded, color: Color(0xFF8D6E63)),
            SizedBox(width: 8),
            Text('思い出を手放しますか？', style: TextStyle(color: Color(0xFF5D4037), fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          '写真はここにデジタル保存されています。本物は感謝の気持ちを込めて、安心して手放しましょう。\n\n本当にこのデータを削除しますか？',
          style: TextStyle(color: Color(0xFF5D4037), height: 1.5, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('やめる', style: TextStyle(color: Color(0xFF8D6E63), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete(_currentMemory);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('手放す (削除)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete();
              } else if (value == 'move') {
                _moveCategory();
              }
            },
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'move',
                child: Row(
                  children: [
                    Icon(Icons.drive_file_move_outlined, color: Color(0xFF5D4037)),
                    SizedBox(width: 8),
                    Text('カテゴリを移動', style: TextStyle(color: Color(0xFF5D4037))),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('思い出を手放す', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 画像表示エリア
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Center(
                child: Hero(
                  tag: _currentMemory.id,
                  child: Image.network(
                    _currentMemory.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.white54, size: 64),
                        SizedBox(height: 12),
                        Text('画像の読み込みに失敗しました', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 情報表示 & 編集エリア
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF6F0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8D6E63),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _currentMemory.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '登録日: ${_currentMemory.createdAt.year}/${_currentMemory.createdAt.month.toString().padLeft(2, '0')}/${_currentMemory.createdAt.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Color(0xFF8D6E63), fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'メモ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isEditingMemo) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _memoController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'メモを入力...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            IconButton(
                              onPressed: _isSavingMemo ? null : _saveMemo,
                              icon: _isSavingMemo
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8D6E63)),
                                    )
                                  : const Icon(Icons.check_circle, color: Colors.green, size: 28),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _memoController.text = _currentMemory.memo ?? '';
                                  _isEditingMemo = false;
                                });
                              },
                              icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 28),
                            ),
                          ],
                        )
                      ],
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: () {
                        setState(() => _isEditingMemo = true);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _currentMemory.memo != null && _currentMemory.memo!.isNotEmpty
                                    ? _currentMemory.memo!
                                    : 'タップして思い出のメモをのこせます...',
                                style: TextStyle(
                                  color: _currentMemory.memo != null && _currentMemory.memo!.isNotEmpty
                                      ? const Color(0xFF5D4037)
                                      : const Color(0xFF8D6E63).withOpacity(0.5),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const Icon(Icons.edit_outlined, color: Color(0xFF8D6E63), size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
