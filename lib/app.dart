import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/dashboard/main_dashboard_screen.dart';
import 'presentation/deliveries/delivery_person_screen.dart';
import 'presentation/providers/app_providers.dart';

class MycoApp extends ConsumerWidget {
  const MycoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppConstants.backgroundDark,
        cardColor: AppConstants.cardDark,
        colorScheme: const ColorScheme.dark(
          primary: AppConstants.accentGreen,
          secondary: AppConstants.primaryGreen,
          surface: AppConstants.cardDark,
          background: AppConstants.backgroundDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.backgroundDark,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppConstants.cardDark,
          selectedItemColor: AppConstants.accentGreen,
          unselectedItemColor: Color(0xFF666666),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('ar', 'DZ'),
      ],
      locale: const Locale('fr', 'FR'),
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginScreen();
          }
          if (user.role == UserRole.deliveryPerson) {
            return const DeliveryPersonScreen();
          }
          return const MainDashboardScreen();
        },
        loading: () => const Scaffold(
          backgroundColor: AppConstants.backgroundDark,
          body: Center(
            child: CircularProgressIndicator(color: AppConstants.accentGreen),
          ),
        ),
        error: (err, stack) => Scaffold(
          backgroundColor: AppConstants.backgroundDark,
          body: Center(
            child: Text('Erreur : $err', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }
}
