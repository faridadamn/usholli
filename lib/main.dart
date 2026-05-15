import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/prayer_provider.dart';
import 'services/quran_provider.dart';
import 'services/hadis_provider.dart';
import 'services/bookmark_service.dart';
import 'services/notification_service.dart';
import 'screens/prayer/prayer_screen.dart';
import 'screens/explore/explore_screen.dart';
import 'screens/artikel/artikel_screen.dart';
import 'services/artikel_provider.dart';
import 'services/donasi_provider.dart';
import 'services/auth_provider.dart';
import 'services/komunitas_provider.dart';
import 'screens/donasi/donasi_screen.dart';
import 'screens/komunitas/komunitas.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar transparan
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  // Init notifikasi & penyimpanan lokal
  await NotificationService().init();
  await BookmarkService.init();
  await HadisProvider.initHive();

  // Pre-load auth session
  final authProvider = AuthProvider();
  await authProvider.init();

  runApp(UsholliApp(authProvider: authProvider));
}

class UsholliApp extends StatelessWidget {
  final AuthProvider authProvider;
  const UsholliApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PrayerProvider()),
        ChangeNotifierProvider(create: (_) => QuranProvider()),
        ChangeNotifierProvider(create: (_) => HadisProvider()),
        ChangeNotifierProvider(create: (_) => ArtikelProvider()),
        ChangeNotifierProvider(create: (_) => DonasiProvider()),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => KomunitasProvider()),
      ],
      child: MaterialApp(
        title: 'Usholli',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionDuration: const Duration(milliseconds: 450),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 156,
              height: 156,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/splash_icon.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.mosque,
                  color: AppTheme.primary,
                  size: 92,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Usholli',
              style: TextStyle(
                color: AppTheme.primaryDark,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jadwal salat dan aktivitas masjid',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const PrayerScreen(),
      const ExploreScreen(),
      const DonasiScreen(),
      const ArtikelScreen(),
      const KomunitasScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        height: 72,
        indicatorColor: AppTheme.accent.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppTheme.accent : Colors.white,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.white),
            selectedIcon: Icon(Icons.home, color: AppTheme.accent),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined, color: Colors.white),
            selectedIcon: Icon(Icons.explore, color: AppTheme.accent),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border, color: Colors.white),
            selectedIcon: Icon(Icons.favorite, color: AppTheme.accent),
            label: 'Donasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded, color: Colors.white),
            selectedIcon:
                Icon(Icons.notifications_rounded, color: AppTheme.accent),
            label: 'Notifikasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: Colors.white),
            selectedIcon: Icon(Icons.person_rounded, color: AppTheme.accent),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
