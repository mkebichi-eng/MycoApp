import 'package:flutter/material.dart';

class AppConstants {
  // Devise par défaut
  static const String currency = 'DA';
  static const String appName = 'MycoApp';
  static const String farmSubtitle = 'Gestion d\'exploitation mycologique';

  // Charte graphique MycoTrack (Dark Forest & Mycelium Accent)
  static const Color backgroundDark = Color(0xFF0F1A0F); // Fond principal noir teinté vert
  static const Color cardDark = Color(0xFF1A2A1A); // Fond des cartes
  static const Color borderDark = Color(0xFF2D4A2D); // Bordures fines
  static const Color accentGreen = Color(0xFF7BC67E); // Vert mycélium éclatant
  static const Color primaryGreen = Color(0xFF4A9E4E); // Vert action
  static const Color alertRed = Color(0xFFE07A7A); // Rouge contamination / stock bas
  static const Color alertYellow = Color(0xFFE0B87A); // Jaune ambre en attente
  static const Color textMuted = Color(0xFF888888);
  static const Color textSub = Color(0xFF666666);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Paramètres mycologiques
  static const double targetSpawnRatioMin = 3.0; // 3%
  static const double targetSpawnRatioMax = 5.0; // 5%
  static const int averageIncubationDays = 18;
  static const double standardBagWeightKg = 5.0;
}

enum UserRole {
  admin,
  productionManager,
  deliveryPerson;

  String get id {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.productionManager:
        return 'operator'; // Alignement avec MycoTrack 'operator'
      case UserRole.deliveryPerson:
        return 'viewer'; // Alignement avec MycoTrack 'viewer' (livreur)
    }
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.productionManager:
        return 'Opérateur / Responsable';
      case UserRole.deliveryPerson:
        return 'Livreur';
    }
  }

  static UserRole fromString(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'operator':
      case 'production_manager':
        return UserRole.productionManager;
      case 'viewer':
      case 'delivery_person':
      default:
        return UserRole.deliveryPerson;
    }
  }
}

enum BatchStatus {
  preparation,
  incubating,
  fruiting,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case BatchStatus.preparation:
        return '🧪 Ensemencement';
      case BatchStatus.incubating:
        return '🌡️ Incubation';
      case BatchStatus.fruiting:
        return '🍄 Fructification';
      case BatchStatus.completed:
        return '✅ Terminé';
      case BatchStatus.cancelled:
        return '☣️ Annulé';
    }
  }
}

enum BagStatus {
  inoculation,
  incubation,
  fruiting,
  done,
  contaminated;

  String get label {
    switch (this) {
      case BagStatus.inoculation:
        return 'Ensemencement';
      case BagStatus.incubation:
        return 'Incubation';
      case BagStatus.fruiting:
        return 'Fructification';
      case BagStatus.done:
        return 'Terminé';
      case BagStatus.contaminated:
        return 'Contaminé';
    }
  }

  String get emoji {
    switch (this) {
      case BagStatus.inoculation:
        return '🧪';
      case BagStatus.incubation:
        return '🌡️';
      case BagStatus.fruiting:
        return '🍄';
      case BagStatus.done:
        return '✅';
      case BagStatus.contaminated:
        return '☣️';
    }
  }

  Color get color {
    switch (this) {
      case BagStatus.inoculation:
        return const Color(0xFF7AB8E0); // Bleu clair
      case BagStatus.incubation:
        return const Color(0xFFE0C87A); // Jaune ambré
      case BagStatus.fruiting:
        return const Color(0xFF7BC67E); // Vert mycélium
      case BagStatus.done:
        return const Color(0xFF888888); // Gris
      case BagStatus.contaminated:
        return const Color(0xFFE07A7A); // Rouge
    }
  }
}

enum ContaminationType {
  trichoderma,
  neurospora,
  bacteria,
  other;

  String get label {
    switch (this) {
      case ContaminationType.trichoderma:
        return 'Moisissure verte (Trichoderma)';
      case ContaminationType.neurospora:
        return 'Moisissure orange (Neurospora)';
      case ContaminationType.bacteria:
        return 'Tache bactérienne (Bacillus)';
      case ContaminationType.other:
        return 'Autre altération';
    }
  }
}

enum DeliveryStatus {
  pending,
  confirmed,
  denied;

  String get label {
    switch (this) {
      case DeliveryStatus.pending:
        return '⏳ En attente de confirmation';
      case DeliveryStatus.confirmed:
        return '✅ Confirmée / Livrée';
      case DeliveryStatus.denied:
        return '❌ Refusée';
    }
  }

  Color get color {
    switch (this) {
      case DeliveryStatus.pending:
        return const Color(0xFFE0B87A);
      case DeliveryStatus.confirmed:
        return const Color(0xFF7BC67E);
      case DeliveryStatus.denied:
        return const Color(0xFFE07A7A);
    }
  }

  Color get bg {
    switch (this) {
      case DeliveryStatus.pending:
        return const Color(0xFF3A2E1A);
      case DeliveryStatus.confirmed:
        return const Color(0xFF1F3A1F);
      case DeliveryStatus.denied:
        return const Color(0xFF3A1A1A);
    }
  }
}

enum PaymentStatus {
  paid,
  pending,
  partial;

  String get label {
    switch (this) {
      case PaymentStatus.paid:
        return 'Payé';
      case PaymentStatus.pending:
        return 'En attente';
      case PaymentStatus.partial:
        return 'Partiel';
    }
  }
}
