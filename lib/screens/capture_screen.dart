import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // 🔥 Web判定に必須のインポート
import '../services/supabase_service.dart';

class CaptureScreen extends StatefulWidget {
  final VoidCallback? onUploadSuccess;
  const CaptureScreen({super.key, this.onUploadSuccess});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  XFile? _selectedImage;
  String _selectedCategory = '手紙';
  final _memoController = TextEditingController();
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _categories = [
    {'title': '手紙', 'icon': Icons.mail_outline_rounded},
    {'title': '年賀状', 'icon': Icons.celebration_outlined},
    {'title': '作品', 'icon': Icons.palette_outlined},
    {'title': 'その他', 'icon': Icons.more_horiz_rounded},
  ];

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85, // 画像圧縮で帯域幅とストレージを最適化
        maxWidth: 1920,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('写真の読み込みに失敗しました: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _saveMemory() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('写真を選んでください'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final service = SupabaseService.instance;
      // 1. 画像をアップロード
      final imageUrl = await service.uploadImage(_selectedImage!);
      // 2. データベースに保存
      await service.addMemory(
        imageUrl: imageUrl,
        category: _selectedCategory,
        memo: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('思い出をデジタル保存しました！これで安心して手放せますね。'),
            backgroundColor: Color(0xFF8D6E63),
          ),
        );
        // リセット
        setState(() {
          _selectedImage = null;
          _memoController.clear();
          _selectedCategory = '手紙';
        });
        if (widget.onUploadSuccess != null) {
          widget.onUploadSuccess!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 【安全対策】Webかスマホかで画像の読み込み方を綺麗に分ける処理
    ImageProvider? previewImage;
    if (_selectedImage != null) {
      if (kIsWeb) {
        previewImage = NetworkImage(_selectedImage!.path);
      } else {
        previewImage = FileImage(File(_selectedImage!.path));
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(title: const Text('思い出をのこす')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 写真選択プレビュー領域
            GestureDetector(
              onTap: _isUploading
                  ? null
                  : () {
                      _showSourceSelector();
                    },
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: const Color(0xFFEADDCF),
                  borderRadius: BorderRadius.circular(20),
                  // 🔥 エラーの原因だった三項演算子を排除し、上で作った previewImage を指定
                  image: previewImage != null
                      ? DecorationImage(image: previewImage, fit: BoxFit.cover)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 64,
                            color: const Color(0xFF8D6E63).withOpacity(0.8),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'タップして写真を撮る / 選択する',
                            style: TextStyle(
                              color: Color(0xFF5D4037),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 28),

            // カテゴリ選択タイトル
            const Text(
              'カテゴリ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 12),

            // カテゴリグリッド
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _categories.map((c) {
                final isSelected = _selectedCategory == c['title'];
                return Expanded(
                  child: GestureDetector(
                    onTap: _isUploading
                        ? null
                        : () {
                            setState(() => _selectedCategory = c['title']);
                          },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8D6E63)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.brown.withOpacity(
                              isSelected ? 0.1 : 0.03,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            c['icon'],
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF8D6E63),
                            size: 24,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c['title'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF5D4037),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // メモ入力
            const Text(
              'メモ (オプション)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _memoController,
              maxLines: 3,
              enabled: !_isUploading,
              decoration: InputDecoration(
                hintText: '例: 2026年のお正月に貰った手紙。心温まるメッセージ。',
                hintStyle: TextStyle(
                  color: const Color(0xFF8D6E63).withOpacity(0.5),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 36),

            // 保存ボタン
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _saveMemory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8D6E63),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '思い出をのこす',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSourceSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFAF6F0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '写真を撮る / 選択する',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sourceButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'カメラで撮影',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _sourceButton(
                  icon: Icons.photo_library_outlined,
                  label: 'ギャラリーから選択',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF8D6E63), size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),
        ],
      ),
    );
  }
}
