import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'controllers/game_controller.dart';
import 'screens/home_screen.dart';
import 'services/ads_service.dart';
import 'services/haptics_service.dart';
import 'services/storage_service.dart';

class IdleSnackEmpireApp extends StatelessWidget {
  const IdleSnackEmpireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<AdsService>(create: (_) => StubAdsService()),
        Provider<HapticsService>(create: (_) => const HapticsService()),
        ChangeNotifierProvider<GameController>(
          create: (context) => GameController(
            storageService: context.read<StorageService>(),
            adsService: context.read<AdsService>(),
            hapticsService: context.read<HapticsService>(),
          ),
        ),
      ],
      child: const _AppBootstrap(),
    );
  }
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = context.read<GameController>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Idle Snack Empire',
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.transparent,
            textTheme: GoogleFonts.exo2TextTheme().apply(
              bodyColor: const Color(0xFFF8FAFC),
              displayColor: const Color(0xFFF8FAFC),
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFF59E0B),
              brightness: Brightness.dark,
            ),
          ),
          home: snapshot.connectionState == ConnectionState.done
              ? const HomeScreen()
              : const _LoadingScreen(),
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
