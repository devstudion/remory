import '../models/memory.dart';

/// 3つの思い出テーマへの分類ロジック
class ThemeClassifier {
  ThemeClassifier._();

  // ─────────────────────────────────────────────
  // 1. お掃除セッション
  //    アップロード日（createdAt の年月日）を「1セッション」として扱い、
  //    新しい日付のセッションから順に並べる
  // ─────────────────────────────────────────────
  static List<Memory> getCleaningSessionMemories(List<Memory> all) {
    if (all.isEmpty) return [];

    // 日付（年月日）でグループ化
    final Map<String, List<Memory>> byDate = {};
    for (final m in all) {
      final key =
          '${m.createdAt.year}-${m.createdAt.month.toString().padLeft(2, '0')}-${m.createdAt.day.toString().padLeft(2, '0')}';
      byDate.putIfAbsent(key, () => []).add(m);
    }

    // キー（日付文字列）を降順にソートして結合
    final sortedKeys = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
    final result = <Memory>[];
    for (final key in sortedKeys) {
      final sessionMemories = byDate[key]!
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      result.addAll(sessionMemories);
    }
    return result;
  }

  /// お掃除セッションのサムネイル（最新セッション先頭画像）
  static Memory? getCleaningSessionThumbnail(List<Memory> all) {
    final list = getCleaningSessionMemories(all);
    return list.isNotEmpty ? list.first : null;
  }

  // ─────────────────────────────────────────────
  // 2. 季節のキュレーター
  //    現在の月に対応する季節キーワードと category / memo を照合し
  //    一致した写真を優先、残りをランダム補完
  // ─────────────────────────────────────────────

  /// 月 → 季節キーワードマッピング
  static const Map<int, List<String>> _seasonKeywords = {
    // 春 3〜5月
    3: ['卒業', '入学', '桜', '花見', '春', '作品'],
    4: ['入学', '花見', '桜', '春', '作品'],
    5: ['こどもの日', '春', '作品', '母の日'],
    // 夏 6〜8月
    6: ['梅雨', '夏', '海', '祭り'],
    7: ['夏', '花火', '海', '夏休み', '祭り'],
    8: ['夏', '花火', '海', '夏休み', '祭り'],
    // 秋 9〜11月
    9: ['運動会', '秋', '芸術', '作品', '文化祭'],
    10: ['紅葉', '秋', '運動会', '文化祭', '作品'],
    11: ['七五三', '紅葉', '秋', '文化祭'],
    // 冬 12〜2月
    12: ['クリスマス', '年賀状', '大掃除', '冬'],
    1: ['年賀状', '正月', '冬', '手紙'],
    2: ['バレンタイン', '節分', '冬', '手紙'],
  };

  static bool _matchesSeason(Memory m, int month) {
    final keywords = _seasonKeywords[month] ?? [];
    final combined = '${m.category} ${m.memo ?? ''}'.toLowerCase();
    return keywords.any((kw) => combined.contains(kw.toLowerCase()));
  }

  static List<Memory> getSeasonalMemories(List<Memory> all) {
    if (all.isEmpty) return [];
    final month = DateTime.now().month;

    final matched = all.where((m) => _matchesSeason(m, month)).toList();
    final unmatched = all.where((m) => !_matchesSeason(m, month)).toList()
      ..shuffle();

    return [...matched, ...unmatched];
  }

  /// 季節のキュレーターのサムネイル
  static Memory? getSeasonalThumbnail(List<Memory> all) {
    final list = getSeasonalMemories(all);
    return list.isNotEmpty ? list.first : null;
  }

  // ─────────────────────────────────────────────
  // 3. 成長・変化のグラデーション
  //    「作品」カテゴリを優先し、古い順→新しい順で並べる
  //    作品がなければ全カテゴリを時系列で
  // ─────────────────────────────────────────────
  static List<Memory> getGrowthMemories(List<Memory> all) {
    if (all.isEmpty) return [];

    final artworks = all
        .where((m) => m.category == '作品')
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (artworks.isNotEmpty) return artworks;

    // 作品がない場合：全体を古い順にソート
    return all.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// 成長テーマのサムネイル（最古の1枚）
  static Memory? getGrowthThumbnail(List<Memory> all) {
    final list = getGrowthMemories(all);
    return list.isNotEmpty ? list.first : null;
  }

  // ─────────────────────────────────────────────
  // テーマ定義リスト（UIで使い回す）
  // ─────────────────────────────────────────────
  static List<MemoryTheme> buildThemes(List<Memory> all) {
    return [
      MemoryTheme(
        id: 'cleaning',
        label: 'お掃除セッション',
        icon: '🧹',
        memories: getCleaningSessionMemories(all),
        thumbnail: getCleaningSessionThumbnail(all),
        description: '片付けの日ごとの思い出',
      ),
      MemoryTheme(
        id: 'seasonal',
        label: '季節のキュレーター',
        icon: '🌸',
        memories: getSeasonalMemories(all),
        thumbnail: getSeasonalThumbnail(all),
        description: '今の季節に合った思い出',
      ),
      MemoryTheme(
        id: 'growth',
        label: '成長・変化のグラデーション',
        icon: '📈',
        memories: getGrowthMemories(all),
        thumbnail: getGrowthThumbnail(all),
        description: '時間の流れを感じる並び',
      ),
    ];
  }
}

/// テーマデータモデル
class MemoryTheme {
  final String id;
  final String label;
  final String icon;
  final List<Memory> memories;
  final Memory? thumbnail;
  final String description;

  const MemoryTheme({
    required this.id,
    required this.label,
    required this.icon,
    required this.memories,
    required this.thumbnail,
    required this.description,
  });
}
