import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_profile_model.dart';

class AuthRepository {
  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  // Profil simulé par défaut en mode local/hors ligne si Firebase n'est pas initialisé
  UserProfileModel? _currentLocalUser;
  final _authStateController = StreamController<UserProfileModel?>.broadcast();

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore {
    // Profil par défaut pour démonstration immédiate : Administrateur de la ferme
    _currentLocalUser = UserProfileModel(
      uid: 'admin_local_01',
      displayName: 'Directeur d\'Exploitation',
      email: 'admin@ferme-myco.dz',
      phone: '+213550123456',
      role: UserRole.admin,
      isActive: true,
      createdAt: DateTime.now(),
    );
    _authStateController.add(_currentLocalUser);
  }

  Stream<UserProfileModel?> get authStateChanges {
    if (_firebaseAuth != null && _firestore != null) {
      return _firebaseAuth.authStateChanges().asyncMap((user) async {
        if (user == null) return null;
        return await getUserProfile(user.uid);
      });
    }
    return _authStateController.stream;
  }

  UserProfileModel? get currentUser => _currentLocalUser;

  Future<UserProfileModel?> getUserProfile(String uid) async {
    if (_firestore != null) {
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          return UserProfileModel.fromMap(doc.data()!, doc.id);
        }
      } catch (e) {
        // En cas de coupure réseau temporaire, Firestore gère le cache automatiquement
      }
    }
    return _currentLocalUser;
  }

  Future<UserProfileModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (_firebaseAuth != null && _firestore != null) {
      try {
        final credential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final profile = await getUserProfile(credential.user!.uid);
        if (profile == null) {
          throw Exception('Profil introuvable pour ce compte.');
        }
        return profile;
      } on FirebaseAuthException catch (e) {
        throw Exception(_translateAuthError(e.code));
      }
    } else {
      // Authentification locale de test pour démarrage immédiat
      if (email.contains('livreur')) {
        _currentLocalUser = UserProfileModel(
          uid: 'livreur_demo_01',
          displayName: 'Yacine Livreur',
          email: email,
          phone: '+213661234567',
          role: UserRole.deliveryPerson,
          isActive: true,
          createdAt: DateTime.now(),
        );
      } else if (email.contains('prod')) {
        _currentLocalUser = UserProfileModel(
          uid: 'prod_demo_01',
          displayName: 'Karim Responsable Culture',
          email: email,
          phone: '+213770987654',
          role: UserRole.productionManager,
          isActive: true,
          createdAt: DateTime.now(),
        );
      } else {
        _currentLocalUser = UserProfileModel(
          uid: 'admin_demo_01',
          displayName: 'Amine Administrateur',
          email: email,
          phone: '+213550123456',
          role: UserRole.admin,
          isActive: true,
          createdAt: DateTime.now(),
        );
      }
      _authStateController.add(_currentLocalUser);
      return _currentLocalUser!;
    }
  }

  /// Bascule rapide de rôle pour tester instantanément l'ergonomie
  void switchDemoRole(UserRole newRole) {
    _currentLocalUser = UserProfileModel(
      uid: 'user_${newRole.id}',
      displayName: 'Utilisateur ${newRole.label}',
      email: '${newRole.id}@ferme-myco.dz',
      phone: '+213550000000',
      role: newRole,
      isActive: true,
      createdAt: DateTime.now(),
    );
    _authStateController.add(_currentLocalUser);
  }

  Future<void> signOut() async {
    if (_firebaseAuth != null) {
      await _firebaseAuth.signOut();
    }
    _currentLocalUser = null;
    _authStateController.add(null);
  }

  String _translateAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Mot de passe incorrect.';
      case 'invalid-email':
        return 'Format d\'adresse email invalide.';
      case 'user-disabled':
        return 'Ce compte utilisateur a été désactivé par l\'administrateur.';
      default:
        return 'Erreur de connexion. Vérifiez vos identifiants.';
    }
  }
}
