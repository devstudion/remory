import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/memory.dart';


class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // --- 認証機能 ---

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // --- ストレージ機能 ---

  Future<String> uploadImage(XFile image) async {
    final bytes = await image.readAsBytes();
    final String fileExt = image.path.split('.').last.toLowerCase();
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    // memories バケットにアップロード
    await _client.storage.from('memories').uploadBinary(
      fileName,
      bytes,
      fileOptions: const FileOptions(
        cacheControl: '3600',
        upsert: true,
      ),
    );

    // 公開URLを取得
    return _client.storage.from('memories').getPublicUrl(fileName);
  }

  // --- データベース機能 (CRUD) ---

  Stream<List<Memory>> watchMemories() {
    // リアルタイム購読
    return _client
        .from('memories_table')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((event) {
          return event.map((map) => Memory.fromMap(map)).toList();
        });
  }

  Future<void> addMemory({
    required String imageUrl,
    required String category,
    required String? memo,
  }) async {
    await _client.from('memories_table').insert({
      'image_url': imageUrl,
      'category': category,
      'memo': memo,
    });
  }

  Future<void> deleteMemory(Memory memory) async {
    // 1. データベースから削除
    await _client.from('memories_table').delete().eq('id', memory.id);

    // 2. ストレージから削除
    try {
      final uri = Uri.parse(memory.imageUrl);
      final segments = uri.pathSegments;
      // URL形式: .../storage/v1/object/public/memories/fileName.jpg
      final memoriesIndex = segments.indexOf('memories');
      if (memoriesIndex != -1 && memoriesIndex + 1 < segments.length) {
        final storagePath = Uri.decodeComponent(segments.sublist(memoriesIndex + 1).join('/'));
        await _client.storage.from('memories').remove([storagePath]);
      }
    } catch (e) {
      debugPrint('Storage削除エラー: $e');
    }
  }

  Future<void> updateCategory(Memory memory, String newCategory) async {
    await _client
        .from('memories_table')
        .update({'category': newCategory})
        .eq('id', memory.id);
  }

  Future<void> updateMemo(Memory memory, String? newMemo) async {
    await _client
        .from('memories_table')
        .update({'memo': newMemo})
        .eq('id', memory.id);
  }
}
