import 'package:flutter/material.dart';

class AppConstants {
  // Devise par défaut
  static const String currency = 'DA';
  static const String appName = 'MycoApp';
  static const String farmSubtitle = 'Ferme de Pleurotes';

  // Paramètres mycologiques par défaut
  static const double targetSpawnRatioMin = 3.0; // 3% de blanc de grain minimum
  static const double targetSpawnRatioMax = 5.0; // 5% conseillé
  static const int averageIncubationDays = 18; // 14 à 21 jours typique pour Pleurotus ostreatus
  static const double standardBagWeightKg = 5.0; // sac standard 5 kg

  // Couleurs de l'application
  static const Color primaryGreen = Color(0xFF1B5E20); // Vert forêt profond
  static const Color secondaryGreen = Color(0xFF4CAF50); // Vert feuille
  static const Color accentGold = Color(0xFFFFB300); // Jaune paille doré
  static const Color alertRed = Color(0xFFD32F2F); // Rouge contamination / stock bas
  static const Color darkBackground = Color(0xFF121212);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F7FA);
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
        return 'production_manager';
      case UserRole.deliveryPerson:
        return 'delivery_person';
    }
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.productionManager:
        return 'Responsable de Production';
      case UserRole.deliveryPerson:
        return 'Livreur';
    }
  }

  static UserRole fromString(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'production_manager':
        return UserRole.productionManager;
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
        return 'En préparation (Pasteurisation)';
      case BatchStatus.incubating:
        return 'Incubation en cours';
      case BatchStatus.fruiting:
        return 'Fructification active';
      case BatchStatus.completed:
        return 'Cycle terminé';
      case BatchStatus.cancelled:
        return 'Annulé / Rebuté';
    }
  }
}

enum BagStatus {
  incubating,
  fruiting,
  harvested,
  contaminated,
  discarded;

  String get label {
    switch (this) {
      case BagStatus.incubating:
        return 'Incubation';
      case BagStatus.fruiting:
        return 'Fructification';
      case BagStatus.harvested:
        return 'Récolté (Vagues terminées)';
      case BagStatus.contaminated:
        return 'Contaminé';
      case BagStatus.discarded:
        return 'Écarté / Jeté';
    }
  }

  Color get color {
    switch (this) {
      case BagStatus.incubating:
        return Colors.blueGrey;
      case BagStatus.fruiting:
        return Colors.green;
      case BagStatus.harvested:
        return Colors.teal;
      case BagStatus.contaminated:
        return Colors.red;
      case BagStatus.discarded:
        return Colors.grey;
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
        return 'Tache bactérienne (Bacillus / Flétrissement)';
      case ContaminationType.other:
        return 'Autre altération / Parasite';
    }
  }
}

enum DeliveryStatus {
  pending,
  inTransit,
  delivered,
  cancelled;

  String get label {
    switch (this) {
      case DeliveryStatus.pending:
        return 'En attente';
      case DeliveryStatus.inTransit:
        return 'En cours de livraison';
      case DeliveryStatus.delivered:
        return 'Livré avec succès';
      case DeliveryStatus.cancelled:
        return 'Annulée';
    }
  }

  Color get color {
    switch (this) {
      case DeliveryStatus.pending:
        return Colors.orange;
      case DeliveryStatus.inTransit:
        return Colors.blue;
      case DeliveryStatus.delivered:
        return Colors.green;
      case DeliveryStatus.cancelled:
        return Colors.red;
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
        return 'En attente de paiement';
      case PaymentStatus.partial:
        return 'Paiement partiel';
    }
  }
}
