import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation officielle de Firebase avec persistance offline
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Activation de la persistance offline illimitée pour les zones agricoles à faible connectivité
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint('Firebase initialisé avec succès sur le projet : ${DefaultFirebaseOptions.currentPlatform.projectId}');
  } catch (e) {
    debugPrint('Mode de secours local : $e');
  }

  runApp(
    const ProviderScope(
      child: MycoApp(),
    ),
  );
}
