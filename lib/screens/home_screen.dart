import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../models/memory.dart';
import 'category_page.dart';
import 'detail_page.dart';

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
          style: TextStyle(
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
          ),
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
              _buildCarousel(context),
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

  Widget _buildCarousel(BuildContext context) {
    if (memories.isEmpty) {
      return CarouselSlider(
        options: CarouselOptions(
          height: 190,
          enableInfiniteScroll: false,
          enlargeCenterPage: true,
        ),
        items: [
          GestureDetector(
            onTap: onNavigateToCapture,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 4),
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
        ],
      );
    }

    final carouselItems = memories.take(5).toList();

    return CarouselSlider(
      options: CarouselOptions(
        height: 190,
        autoPlay: carouselItems.length > 1,
        autoPlayInterval: const Duration(seconds: 4),
        enlargeCenterPage: true,
        viewportFraction: 0.85,
      ),
      items: carouselItems.map((m) {
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemoryDetailPage(
                memory: m,
                onDelete: onDelete,
                onUpdateCategory: onUpdateCategory,
              ),
            ),
          ),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFFEADDCF),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Hero(
                tag: 'carousel-${m.id}',
                child: Image.network(
                  m.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 40),
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
                  style: TextStyle(
                    color: Color(0xFF8D6E63),
                    fontSize: 12,
                  ),
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
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
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
