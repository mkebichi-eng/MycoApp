import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation sécurisée de Firebase avec persistance offline
  try {
    await Firebase.initializeApp();
    // Activation de la persistance offline de Firestore pour les zones à faible couverture réseau
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    // Mode de repli (développement local ou premier démarrage avant injection des clés de production)
    debugPrint('Firebase initialisé en mode local de démonstration : $e');
  }

  runApp(
    const ProviderScope(
      child: MycoApp(),
    ),
  );
}
