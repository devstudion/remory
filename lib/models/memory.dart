class Memory {
  final String id;
  final String imageUrl;
  final String category;
  final String? memo;
  final String? userId;
  final DateTime createdAt;

  Memory({
    required this.id,
    required this.imageUrl,
    required this.category,
    this.memo,
    this.userId,
    required this.createdAt,
  });

  factory Memory.fromMap(Map<String, dynamic> map) {
    return Memory(
      id: map['id']?.toString() ?? '',
      imageUrl: map['image_url'] ?? '',
      category: map['category'] ?? '',
      memo: map['memo'] as String?,
      userId: map['user_id'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'image_url': imageUrl,
      'category': category,
      'memo': memo,
    };
    if (userId != null) {
      map['user_id'] = userId;
    }
    return map;
  }
}
