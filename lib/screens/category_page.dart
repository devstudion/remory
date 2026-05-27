import 'package:flutter/material.dart';
import '../models/memory.dart';
import 'detail_page.dart';

class CategoryPage extends StatelessWidget {
  final String categoryTitle;
  final List<Memory> allMemories;
  final Function(Memory) onDelete;
  final Function(Memory, String) onUpdateCategory;

  const CategoryPage({
    super.key,
    required this.categoryTitle,
    required this.allMemories,
    required this.onDelete,
    required this.onUpdateCategory,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = allMemories.where((m) => m.category == categoryTitle).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        title: Text(categoryTitle),
      ),
      body: filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: const Color(0xFF8D6E63).withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '「$categoryTitle」の思い出はまだありません',
                    style: const TextStyle(
                      color: Color(0xFF8D6E63),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final memory = filtered[i];
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: const Color(0xFFEADDCF),
                      child: Hero(
                        tag: memory.id,
                        child: Image.network(
                          memory.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF8D6E63),
                          ),
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
