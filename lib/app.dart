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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryGreen,
          primary: AppConstants.primaryGreen,
          secondary: AppConstants.secondaryGreen,
        ),
        fontFamily: 'Roboto',
      ),
      // Préparation de l'internationalisation FR & AR (RTL ready)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'), // Français par défaut
        Locale('ar', 'DZ'), // Arabe pour adaptation locale
      ],
      locale: const Locale('fr', 'FR'),
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginScreen();
          }
          // Redirection stricte par rôle
          if (user.role == UserRole.deliveryPerson) {
            return const DeliveryPersonScreen();
          }
          return const MainDashboardScreen();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Scaffold(
          body: Center(child: Text('Erreur d\'initialisation : $err')),
        ),
      ),
    );
  }
}
