import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';
import 'models/memory.dart';
import 'screens/home_screen.dart';
import 'screens/capture_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Supabase初期化 (anonKeyの先頭の不要な'Y'を削除して修復)
  await Supabase.initialize(
    url: 'https://ksiedfezpasatplkuwws.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtzaWVkZmV6cGFzYXRwbGt1d3dzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk3NDg2OTMsImV4cCI6MjA5NTMyNDY5M30.c_h0zTzsVpeaqe47mVHrVt75x2FQQMp92jHrxX8W5Y8',
  );

  runApp(
    DevicePreview(
      enabled: true,
      defaultDevice: Devices.ios.iPhone16ProMax,
      isToolbarVisible: false,
      builder: (context) => const RemoryApp(),
    ),
  );
}

class RemoryApp extends StatelessWidget {
  const RemoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      title: 'REMORY',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAF6F0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8D6E63),
          primary: const Color(0xFF8D6E63),
          secondary: const Color(0xFF5D4037),
          surface: const Color(0xFFFAF6F0),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFAF6F0),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF5D4037),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          iconTheme: IconThemeData(color: Color(0xFF5D4037)),
        ),
      ),
      // ログイン機能なし：直接メイン画面を表示
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 各思い出操作メソッドの定義
  Future<void> _deleteMemory(Memory memory) async {
    await SupabaseService.instance.deleteMemory(memory);
  }

  Future<void> _updateCategory(Memory memory, String newCategory) async {
    await SupabaseService.instance.updateCategory(memory, newCategory);
  }

  @override
  Widget build(BuildContext context) {
    final service = SupabaseService.instance;

    return Scaffold(
      body: StreamBuilder<List<Memory>>(
        stream: service.watchMemories(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('データの読み込み中にエラーが発生しました'));
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF8D6E63)),
            );
          }

          final memories = snapshot.data!;

          final List<Widget> pages = [
            HomeScreen(
              memories: memories,
              onDelete: _deleteMemory,
              onUpdateCategory: _updateCategory,
              onNavigateToCapture: () {
                setState(() => _selectedIndex = 1); // 撮影タブへナビゲート
              },
            ),
            CaptureScreen(
              onUploadSuccess: () {
                setState(() => _selectedIndex = 0); // 成功したらホームに戻す
              },
            ),
            ProfileScreen(memories: memories),
          ];

          return pages[_selectedIndex];
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: const Color(0xFF8D6E63),
          unselectedItemColor: const Color(0xFF8D6E63).withOpacity(0.5),
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'ホーム',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt_rounded),
              label: '撮影',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'マイページ',
            ),
          ],
        ),
      ),
    );
  }
}
