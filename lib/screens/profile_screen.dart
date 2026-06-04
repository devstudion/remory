import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/memory.dart';

class ProfileScreen extends StatefulWidget {
  final List<Memory> memories;
  const ProfileScreen({super.key, required this.memories});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 現在のログインユーザーを取得
  User? get _currentUser => Supabase.instance.client.auth.currentUser;

  // メアドが登録されているか（ゲストか本会員か）判定
  bool get _isLoggedIn => _currentUser?.email != null;

  @override
  Widget build(BuildContext context) {
    // 統計データの計算
    final totalCount = widget.memories.length;
    final letterCount = widget.memories.where((m) => m.category == '手紙').length;
    final greetingCount = widget.memories
        .where((m) => m.category == '年賀状')
        .length;
    final workCount = widget.memories.where((m) => m.category == '作品').length;
    final otherCount = widget.memories.where((m) => m.category == 'その他').length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(title: const Text('マイページ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 👤 1. プロフィールカード
            _buildProfileCard(),
            const SizedBox(height: 32),

            // 📊 2. 統計セクション
            const Text(
              'のこした思い出の統計',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 16),
            _buildTotalCard(totalCount),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _categoryStatCard(
                  '手紙',
                  letterCount,
                  Icons.mail_outline_rounded,
                ),
                _categoryStatCard(
                  '年賀状',
                  greetingCount,
                  Icons.celebration_outlined,
                ),
                _categoryStatCard('作品', workCount, Icons.palette_outlined),
                _categoryStatCard('その他', otherCount, Icons.more_horiz_rounded),
              ],
            ),
            const SizedBox(height: 32),

            // ⚙️ 3. アカウント設定セクション
            const Text(
              'アカウント設定',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 12),
            if (!_isLoggedIn) ...[
              _settingsTile(
                Icons.cloud_upload_outlined,
                'データの引き継ぎ（会員登録）',
                () => _showAuthDialog(isSignUp: true),
              ),
              _settingsTile(
                Icons.login_rounded,
                '既存アカウントでログイン',
                () => _showAuthDialog(isSignUp: false),
              ),
            ] else ...[
              _settingsTile(Icons.logout_rounded, 'ログアウト', () async {
                await Supabase.instance.client.auth.signOut();
                setState(() {}); // 画面更新
              }),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- UIパーツ作成用メソッド ---

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFFEADDCF),
            child: Icon(
              Icons.person_rounded,
              size: 40,
              color: const Color(0xFF8D6E63).withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isLoggedIn ? 'REMORY ユーザー' : 'ゲストユーザー',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isLoggedIn ? (_currentUser?.email ?? '') : 'アカウント未連携',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8D6E63)),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(int totalCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8D6E63), Color(0xFF6D4C41)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'これまでにのこした思い出',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$totalCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '枚',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryStatCard(String title, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: const Color(0xFF8D6E63), size: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8D6E63),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(width: 2),
              const Text(
                '枚',
                style: TextStyle(fontSize: 10, color: Color(0xFF8D6E63)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title, VoidCallback onTap) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF8D6E63), size: 22),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, color: Color(0xFF5D4037)),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFEADDCF)),
        onTap: onTap,
      ),
    );
  }

  // --- 認証ダイアログ ---

  // --- 認証ダイアログ ---

  void _showAuthDialog({required bool isSignUp}) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String? errorMessage; // 🔥 エラー文を保持する変数を追加

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // 🔥 ダイアログの中だけを更新するために追加
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isSignUp ? 'データの引き継ぎ' : 'ログイン'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🔥 エラーがある場合のみ、入力欄の上に赤文字で表示
                if (errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'メールアドレス'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'パスワード(6文字以上)'),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8D6E63),
                ),
                onPressed: () async {
                  final email = emailController.text.trim();
                  final password = passwordController.text.trim();

                  // バリデーションエラーはダイアログ内に表示
                  if (!RegExp(
                    r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                  ).hasMatch(email)) {
                    setDialogState(() => errorMessage = '正しいメール形式で入力してください');
                    return;
                  }
                  if (password.length < 6) {
                    setDialogState(() => errorMessage = 'パスワードは6文字以上必要です');
                    return;
                  }

                  setDialogState(() => errorMessage = null); // 実行前にエラーを消す

                  try {
                    if (isSignUp) {
                      await Supabase.instance.client.auth.updateUser(
                        UserAttributes(email: email, password: password),
                      );
                    } else {
                      await Supabase.instance.client.auth.signInWithPassword(
                        email: email,
                        password: password,
                      );
                    }
                    if (mounted) {
                      Navigator.pop(context);
                      setState(() {}); // 親画面の更新
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ログインに成功しました！')),
                      );
                    }
                  } catch (e) {
                    // 🔥 エラー内容を日本語に翻訳してダイアログ内に表示
                    setDialogState(() {
                      final errorStr = e.toString();
                      if (errorStr.contains('Invalid login credentials')) {
                        errorMessage = 'メールアドレスかパスワードが間違っています。';
                      } else if (errorStr.contains('already registered')) {
                        errorMessage = 'このメールアドレスは既に登録されています。';
                      } else {
                        errorMessage = '通信エラーが発生しました。もう一度お試しください。';
                      }
                    });
                  }
                },
                child: Text(
                  isSignUp ? '登録' : 'ログイン',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
