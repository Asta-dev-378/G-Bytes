import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'providers/user_provider.dart';
import 'providers/game_provider.dart';
import 'providers/timer_provider.dart';
import 'providers/interval_timer_provider.dart';
import 'providers/nav_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/player_progress_provider.dart';
import 'services/storage_service.dart';

import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  // Global error handler â€” prevents silent black screens
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error: $error\n$stack');
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Initialise storage before any provider touches SharedPreferences
  final storage = StorageService();
  await storage.init();

  // Disable Google Fonts network fetching â€” use bundled Poppins TTFs instead
  GoogleFonts.config.allowRuntimeFetching = false;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:                   Colors.transparent,
      statusBarIconBrightness:          Brightness.light,
      systemNavigationBarColor:         Color(0xFF0F0F0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..init()),
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider(
          create: (ctx) => PlayerProgressProvider(
            storage: ctx.read<StorageService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => GameProvider(
            progress: ctx.read<PlayerProgressProvider>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => IntervalTimerProvider()),
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const GBytesApp(),
    ),
  );
}

class GBytesApp extends StatefulWidget {
  const GBytesApp({super.key});

  @override
  State<GBytesApp> createState() => _GBytesAppState();
}

class _GBytesAppState extends State<GBytesApp> {
  // â”€â”€ Create the router ONCE so it is never recreated on settings changes â”€â”€
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(path: '/home', builder: (context, state) => const MainShell()),
      ],
      redirect: (context, state) {
        // Only protect /home â€” splash handles its own self-navigation
        final isHome = state.matchedLocation == '/home';
        if (isHome) {
          final user = context.read<UserProvider>();
          if (user.isInitialized && !user.isLoggedIn) return '/login';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Consumer<SettingsProvider> rebuilds ONLY MaterialApp theme â€” not the router
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final seedColor = settings.appSeedColor;
        return MaterialApp.router(
          title: 'G-Bytes',
          debugShowCheckedModeBanner: false,
          theme:      _buildGymTheme(seedColor),
          darkTheme:  _buildGymTheme(seedColor),
          themeMode:  ThemeMode.dark,
          routerConfig: _router,
        );
      },
    );
  }

  // Thunder Theme: pitch-black scaffold, dynamic seed-driven accent.
  // Switching themes in Settings propagates to every widget automatically.
  ThemeData _buildGymTheme(Color seed) {
    const thunderBlack   = Color(0xFF0A0A0A);
    const thunderSurface = Color(0xFF141414);
    const thunderBorder  = Color(0xFF242424);
    const gymWhite = Color(0xFFF5F5F5);
    const gymMuted = Color(0xFF8E8E93);

    final primary   = seed;
    final hsl = HSLColor.fromColor(seed);
    final secondary = hsl
        .withLightness((hsl.lightness + 0.18).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation - 0.10).clamp(0.0, 1.0))
        .toColor();

    return ThemeData(
      useMaterial3:        true,
      brightness:          Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor:  seed,
        primary:    primary,
        onPrimary:  Colors.white,
        secondary:  secondary,
        onSecondary: Colors.black,
        surface:    thunderSurface,
        onSurface:  gymWhite,
        surfaceContainerHighest: thunderBorder,
        outline:    thunderBorder,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: thunderBlack,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ).apply(bodyColor: gymWhite, displayColor: gymWhite),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          minimumSize: const Size(double.infinity, 56),
          elevation: 0, shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: thunderSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: thunderBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: thunderBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: const TextStyle(color: gymMuted, fontSize: 14),
        labelStyle: const TextStyle(color: gymMuted),
      ),
      cardTheme: CardThemeData(
        elevation: 0, color: thunderSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: thunderBorder, width: 1)),
        shadowColor: Colors.black45,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: thunderSurface,
        labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: gymWhite),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: thunderBorder, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(color: thunderBorder, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        tileColor: thunderSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : gymMuted),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primary : thunderBorder),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary, linearTrackColor: thunderBorder, circularTrackColor: thunderBorder, linearMinHeight: 8,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary, inactiveTrackColor: thunderBorder,
        thumbColor: primary, overlayColor: primary.withAlpha(30),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: thunderBlack, selectedItemColor: primary,
        unselectedItemColor: gymMuted, type: BottomNavigationBarType.fixed, elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: thunderBlack,
        indicatorColor: primary.withAlpha(35),
        iconTheme: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? IconThemeData(color: primary) : const IconThemeData(color: gymMuted)),
        labelTextStyle: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
            ? GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: primary)
            : GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: gymMuted)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: thunderBlack, elevation: 0, scrolledUnderElevation: 0, centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 20, color: gymWhite),
        iconTheme: const IconThemeData(color: gymWhite),
        actionsIconTheme: const IconThemeData(color: gymWhite),
        systemOverlayStyle: const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark, statusBarIconBrightness: Brightness.light),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary, foregroundColor: Colors.white, elevation: 4, shape: const CircleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: thunderSurface,
        contentTextStyle: GoogleFonts.poppins(color: gymWhite, fontSize: 13, fontWeight: FontWeight.w500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: thunderSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18, color: gymWhite),
        contentTextStyle: GoogleFonts.poppins(fontSize: 14, color: gymMuted),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: thunderSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
    );
  }
}
