# TrashPicker

Application mobile de gestion de collecte de déchets développée avec Flutter.

## Configuration Google Maps API

Pour utiliser Google Maps dans cette application, vous devez obtenir une clé API Google Maps et la configurer dans les fichiers suivants :

### 1. Obtenir une clé API Google Maps

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créez un nouveau projet ou sélectionnez un projet existant
3. Activez les APIs suivantes :
   - Maps SDK for Android
   - Maps SDK for iOS
   - Maps JavaScript API (pour Web)
4. Créez une clé API dans "APIs & Services" > "Credentials"

### 2. Configurer la clé API

Remplacez `YOUR_GOOGLE_MAPS_API_KEY` dans les fichiers suivants par votre vraie clé API :

#### Android
- Fichier : `android/app/src/main/AndroidManifest.xml`
- Ligne 18 : `android:value="YOUR_GOOGLE_MAPS_API_KEY"`

#### iOS
- Fichier : `ios/Runner/AppDelegate.swift`
- Ligne 12 : `GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")`

#### Web
- Fichier : `web/index.html`
- Ligne 36 : `<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY"></script>`

### 3. Configuration Firebase

L'application utilise Firebase pour l'authentification et le stockage. Assurez-vous de :

1. Créer un projet Firebase sur [Firebase Console](https://console.firebase.google.com/)
2. Ajouter les applications Android, iOS et Web à votre projet Firebase
3. Télécharger les fichiers de configuration :
   - `google-services.json` pour Android (placez-le dans `android/app/`)
   - `GoogleService-Info.plist` pour iOS (placez-le dans `ios/Runner/`)
   - Configuration Web (déjà dans `lib/firebase_options.dart`)

## Installation

1. Clonez le repository
2. Installez les dépendances :
```bash
flutter pub get
```

3. Configurez les clés API comme décrit ci-dessus

4. Lancez l'application :
```bash
flutter run
```

## Fonctionnalités

### Client
- Création de demandes de récupération de déchets
- Ajout de photos et notes pour les demandes
- Suivi en temps réel du statut de la demande
- Visualisation sur carte de la position

### Picker (Collecteur)
- Liste des demandes de récupération en attente
- Vue carte avec tous les points de collecte
- Acceptation et gestion des demandes
- Navigation vers les points de collecte

## Technologies utilisées

- Flutter
- Firebase (Auth, Firestore, Storage)
- Google Maps
- GetX (State Management)
- Geolocator
- Image Picker
