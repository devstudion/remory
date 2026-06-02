import 'package:flutter/material.dart';
import '../models/memory.dart';
import '../services/theme_classifier.dart';
import 'category_page.dart';
import 'detail_page.dart';
import 'slideshow_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<Memory> memories;
  final Function(Memory) onDelete;
  final Function(Memory, String) onUpdateCategory;
  final VoidCallback? onNavigateToCapture;

  const HomeScreen({
    super.key,
    required this.memories,
    required this.onDelete,
    required this.onUpdateCategory,
    this.onNavigateToCapture,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        title: const Text(
          'REMORY',
          style: TextStyle(letterSpacing: 2.0, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // リアルタイム購読しているためリフレッシュ自体は必須ではないですがUIに表示があるとプレミアム感が増します
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: const Color(0xFF8D6E63),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildTripleThemePanel(context),
              const SizedBox(height: 28),
              _sectionTitle('アルバムで整理'),
              const SizedBox(height: 12),
              _buildAlbumList(context),
              const SizedBox(height: 28),
              _sectionTitle('すべての思い出'),
              const SizedBox(height: 12),
              _buildGrid(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF5D4037),
      ),
    ),
  );

  // ──────────────────────────────────────────────
  // 3分割テーマパネル
  // ──────────────────────────────────────────────
  Widget _buildTripleThemePanel(BuildContext context) {
    if (memories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: onNavigateToCapture,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFFEADDCF),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_a_photo_outlined,
                  size: 48,
                  color: Color(0xFF8D6E63),
                ),
                SizedBox(height: 12),
                Text(
                  '最初の思い出をのこしましょう',
                  style: TextStyle(
                    color: Color(0xFF5D4037),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final themes = ThemeClassifier.buildThemes(memories);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: themes.map((theme) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _ThemePanelCard(
                theme: theme,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SlideshowScreen(
                      theme: theme,
                      onDelete: onDelete,
                      onUpdateCategory: onUpdateCategory,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAlbumList(BuildContext context) {
    final albums = [
      {'title': '手紙', 'icon': Icons.mail_outline_rounded},
      {'title': '年賀状', 'icon': Icons.celebration_outlined},
      {'title': '作品', 'icon': Icons.palette_outlined},
      {'title': 'その他', 'icon': Icons.more_horiz_rounded},
    ];
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: albums.length,
        itemBuilder: (context, i) => _albumCircle(
          context,
          albums[i]['title'] as String,
          albums[i]['icon'] as IconData,
        ),
      ),
    );
  }

  Widget _albumCircle(BuildContext context, String title, IconData icon) {
    final count = memories.where((m) => m.category == title).length;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryPage(
            categoryTitle: title,
            allMemories: memories,
            onDelete: onDelete,
            onUpdateCategory: onUpdateCategory,
          ),
        ),
      ),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(icon, color: const Color(0xFF8D6E63), size: 24),
                ),
                if (count > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF8D6E63),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    if (memories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 40,
                  color: const Color(0xFF8D6E63).withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  'のこした思い出がここに並びます',
                  style: TextStyle(color: Color(0xFF8D6E63), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        padding: EdgeInsets.zero,

        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 0.85,
        ),
        itemCount: memories.length,
        itemBuilder: (context, i) {
          final memory = memories[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MemoryDetailPage(
                  memory: memory,
                  onDelete: onDelete,
                  onUpdateCategory: onUpdateCategory,
                ),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEADDCF),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Hero(
                  tag: memory.id,
                  child: Image.network(
                    memory.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// テーマパネルカードウィジェット
// ─────────────────────────────────────────────────────────
class _ThemePanelCard extends StatefulWidget {
  final MemoryTheme theme;
  final VoidCallback onTap;

  const _ThemePanelCard({required this.theme, required this.onTap});

  @override
  State<_ThemePanelCard> createState() => _ThemePanelCardState();
}

class _ThemePanelCardState extends State<_ThemePanelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.93,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = _scaleController;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasThumbnail = widget.theme.thumbnail != null;

    return GestureDetector(
      onTapDown: (_) => _scaleController.reverse(),
      onTapUp: (_) {
        _scaleController.forward();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.forward(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFFEADDCF),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── サムネイル画像 ──
                if (hasThumbnail)
                  Image.network(
                    widget.theme.thumbnail!.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => _placeholder(),
                  )
                else
                  _placeholder(),

                // ── 全体に薄いオーバーレイ ──
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x88000000),
                        Color(0x22000000),
                        Color(0x66000000),
                      ],
                      stops: [0.0, 0.4, 1.0],
                    ),
                  ),
                ),

                // ── 左上：テーマアイコン（控えめ表示） ──
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.theme.icon,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),

                // ── 下部：テーマ名 ──
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
                    child: Text(
                      widget.theme.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                  ),
                ),

                // ── 右下：枚数バッジ ──
                if (widget.theme.memories.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.theme.memories.length}枚',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFEADDCF),
      child: Center(
        child: Text(widget.theme.icon, style: const TextStyle(fontSize: 36)),
      ),
    );
  }
}
