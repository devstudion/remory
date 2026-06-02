import 'dart:async';
import 'package:flutter/material.dart';
import '../models/memory.dart';
import '../services/theme_classifier.dart';
import 'detail_page.dart';

class SlideshowScreen extends StatefulWidget {
  final MemoryTheme theme;
  final Function(Memory) onDelete;
  final Function(Memory, String) onUpdateCategory;

  const SlideshowScreen({
    super.key,
    required this.theme,
    required this.onDelete,
    required this.onUpdateCategory,
  });

  @override
  State<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<SlideshowScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isPlaying = true;
  Timer? _autoPlayTimer;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    if (widget.theme.memories.length > 1) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _progressController.forward(from: 0);
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_isPlaying) return;
      _goToNext();
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _progressController.stop();
  }

  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _startAutoPlay();
    } else {
      _stopAutoPlay();
    }
  }

  void _goToNext() {
    if (widget.theme.memories.isEmpty) return;
    final next = (_currentIndex + 1) % widget.theme.memories.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _goToPrev() {
    if (widget.theme.memories.isEmpty) return;
    final prev = (_currentIndex - 1 + widget.theme.memories.length) %
        widget.theme.memories.length;
    _pageController.animateToPage(
      prev,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}年${dt.month}月${dt.day}日';
  }

  // セッションラベル（お掃除テーマ用）
  String _sessionLabel(Memory m) {
    return '${m.createdAt.year}年${m.createdAt.month}月${m.createdAt.day}日のセッション';
  }

  Widget _buildInfoLabel(Memory m) {
    if (widget.theme.id == 'cleaning') {
      return Text(
        _sessionLabel(m),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      );
    }
    return Text(
      _formatDate(m.createdAt),
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memories = widget.theme.memories;

    if (memories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.theme.icon,
                style: const TextStyle(fontSize: 56),
              ),
              const SizedBox(height: 20),
              Text(
                '${widget.theme.label}\nにまだ思い出がありません',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // ── メイン画像スワイプエリア ──
            GestureDetector(
              onTap: _togglePlayPause,
              child: PageView.builder(
                controller: _pageController,
                itemCount: memories.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  if (_isPlaying) {
                    _progressController.forward(from: 0);
                  }
                },
                itemBuilder: (context, index) {
                  final m = memories[index];
                  return GestureDetector(
                    // ダブルタップで詳細ページへ
                    onDoubleTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MemoryDetailPage(
                          memory: m,
                          onDelete: widget.onDelete,
                          onUpdateCategory: widget.onUpdateCategory,
                        ),
                      ),
                    ),
                    child: Hero(
                      tag: 'slideshow-${m.id}',
                      child: Image.network(
                        m.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white30,
                            size: 60,
                          ),
                        ),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                              color: const Color(0xFF8D6E63),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── 上部グラデーション ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 160,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── 下部グラデーション ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── 上部：戻るボタン ＋ テーマタイトル ──
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.theme.icon} ${widget.theme.label}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            widget.theme.description,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 詳細ボタン
                    IconButton(
                      onPressed: () {
                        if (memories.isEmpty) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MemoryDetailPage(
                              memory: memories[_currentIndex],
                              onDelete: widget.onDelete,
                              onUpdateCategory: widget.onUpdateCategory,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.open_in_new_rounded,
                          color: Colors.white70, size: 20),
                    ),
                  ],
                ),
              ),
            ),

            // ── プログレスバー（複数枚のとき） ──
            if (memories.length > 1)
              Positioned(
                top: MediaQuery.of(context).padding.top + 70,
                left: 16,
                right: 16,
                child: Row(
                  children: List.generate(
                    memories.length.clamp(0, 12), // 最大12本表示
                    (i) => Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: i < _currentIndex
                              ? Colors.white
                              : i == _currentIndex
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(1),
                        ),
                        child: i == _currentIndex
                            ? AnimatedBuilder(
                                animation: _progressController,
                                builder: (context, child) {
                                  return FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _progressController.value,
                                    child: Container(
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),

            // ── 下部：情報エリア ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: memories.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // カテゴリバッジ
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8D6E63)
                                              .withOpacity(0.85),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          memories[_currentIndex].category,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      _buildInfoLabel(
                                          memories[_currentIndex]),
                                      if (memories[_currentIndex].memo !=
                                              null &&
                                          memories[_currentIndex]
                                              .memo!
                                              .isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            memories[_currentIndex].memo!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white60,
                                              fontSize: 12,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // 枚数インジケーター
                                Column(
                                  children: [
                                    Text(
                                      '${_currentIndex + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      height: 1,
                                      width: 20,
                                      color: Colors.white38,
                                    ),
                                    Text(
                                      '${memories.length}',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // 再生コントロール
                            if (memories.length > 1)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _controlButton(
                                    icon: Icons.skip_previous_rounded,
                                    onTap: () {
                                      _goToPrev();
                                      if (_isPlaying) _startAutoPlay();
                                    },
                                  ),
                                  const SizedBox(width: 20),
                                  _controlButton(
                                    icon: _isPlaying
                                        ? Icons.pause_circle_filled_rounded
                                        : Icons.play_circle_filled_rounded,
                                    size: 48,
                                    onTap: _togglePlayPause,
                                  ),
                                  const SizedBox(width: 20),
                                  _controlButton(
                                    icon: Icons.skip_next_rounded,
                                    onTap: () {
                                      _goToNext();
                                      if (_isPlaying) _startAutoPlay();
                                    },
                                  ),
                                ],
                              ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),

            // ── 一時停止オーバーレイアイコン ──
            if (!_isPlaying)
              Center(
                child: AnimatedOpacity(
                  opacity: !_isPlaying ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pause_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 32,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}
