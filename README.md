# 🍄 MycoApp - Gestion Complète d'Exploitation Mycologique (Pleurotes)

Application mobile Flutter (Android & iOS) conçue pour la gestion intégrale d'une ferme de production de pleurotes (*Pleurotus ostreatus*), connectée à un backend Cloud Firebase.

---

## 🚀 1. Connexion au Dépôt GitHub

Le dépôt Git local a été initialisé avec les branches conventionnelles (`main` et `develop`). Pour connecter ce code à votre compte GitHub :

1. Créez un nouveau dépôt vide sur votre compte GitHub (ex: `https://github.com/<votre-nom>/mycoapp.git`).
2. Ouvrez un terminal dans ce dossier `MycoApp` et exécutez :

```bash
# Relier votre dépôt distant
git remote add origin https://github.com/<votre-nom>/mycoapp.git

# Envoyer la branche principale
git push -u origin main

# Pousser la branche de développement
git checkout -b develop
git push -u origin develop
```

À chaque push ou Pull Request, le workflow **GitHub Actions** (`.github/workflows/flutter_ci.yml`) analysera le code et exécutera automatiquement l'ensemble des tests unitaires.

---

## 🔒 2. Configuration Firebase

Le projet est préconfiguré pour Firebase :
- **Règles de sécurité Firestore** : `firestore.rules` (étanchéité stricte garantissant qu'aucun livreur ne peut accéder aux marges ou aux chiffres d'affaires).
- **Index composites Firestore** : `firestore.indexes.json`
- **Règles de stockage Storage** : `storage.rules` (QR codes et photos de lots).

### Pour connecter votre console Firebase :
1. Créez un projet sur la console [Firebase](https://console.firebase.google.com).
2. Ajoutez une application Android (Package : `com.mycoapp.farm`) et téléchargez `google-services.json` dans `android/app/`.
3. Ajoutez une application iOS (Bundle ID : `com.mycoapp.farm`) et téléchargez `GoogleService-Info.plist` dans `ios/Runner/`.
4. Déployez les règles Firestore et Storage :
```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

---

## 📱 3. Rôles et Ergonomie Terrain

| Rôle | Périmètre d'Accès | Spécificités UX/UI |
| :--- | :--- | :--- |
| **Administrateur** | Accès complet, gestion des utilisateurs, audit logs, configuration. | Dashboard complet, export PDF/CSV. |
| **Responsable Production** | Production (lots, sacs, récoltes), Ventes, Stocks, Clients, Livraisons. | Graphiques fl_chart, scanner QR, gestion des lots. |
| **Livreur** | Uniquement ses courses du jour assignées. | **Appel client en 1 tap (`tel:`)**, GPS, validation en 1 clic. **Zéro vue sur les marges/prix**. |

---

## 📊 4. Devise et Spécificités Mycologiques

- **Devise** : **Dinar Algérien (DA)** appliquée sur toutes les ventes, frais livreurs et valorisations de stocks.
- **Formule de Marge Nette** :
  $$\text{Marge} = (\text{Quantité} \times \text{Prix Client}) - \text{Tarif Livreur} - \text{Coûts Alloués}$$
- **Suivi des Lots & Sacs** :
  - Pasteurisation en fût de 200L d'eau chaude sur paille hachée.
  - Calcul automatique du taux de blanc (3% à 5% conseillé).
  - Équivalence de sacs avec QR codes uniques imprimables en planches A4 (PDF).
  - Détection et signalement des contaminations (*Trichoderma*, etc.) avec calcul automatique du taux d'avarie.

---

## 🧪 5. Exécution des Tests

```bash
# Exécuter l'ensemble des tests unitaires agronomiques et de sécurité
flutter test
```
