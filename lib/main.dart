import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kliv_app/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'lib/services/notification_service.dart';
import 'theme/app_theme.dart'; // Import du thème unifié

// Providers
import 'providers/auth_provider.dart';

// Screens
import 'screens/auth/login_pin_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/cotisations/cotisations_screen.dart';

Future<void> main() async {
  runApp(const KlivjnaApp());
  await NotificationService().initialize();
  await Firebase.initializeApp();
}

class KlivjnaApp extends StatelessWidget {
  const KlivjnaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'JNA ADMINISTRATION',

        // ✅ Thème unifié harmonisé
        theme: AppTheme.lightTheme,

        // ✅ Localisations pour DatePicker, formats, etc.
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr'), // 🇫🇷 pour formats de date et textes
          Locale('en'), // 🇬🇧 fallback
        ],

        // ✅ Écran d’entrée selon l’état de connexion
        home: const AuthWrapper(),

        // ✅ Routes institutionnelles
        routes: {
          '/login': (_) => const LoginPinScreen(),
          '/dashboard': (_) => const DashboardScreen(),
          '/cotisations': (_) => const CotisationsScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // ✅ Redirection selon l’état de connexion
    return auth.isLoggedIn ? const DashboardScreen() : const LoginPinScreen();
  }
}
