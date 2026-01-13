# Guide des Fonctionnalités Admin - TrashPicker

## Vue d'ensemble

Ce guide décrit toutes les fonctionnalités admin ajoutées à l'application TrashPicker, incluant la gestion des pickers, les analytiques et les cartes globales.

---

## PARTIE 1 - AUTHENTIFICATION ET ROUTING PAR RÔLE

### Méthode Centrale de Post-Login

**Fichier**: `lib/features/auth/controllers/login_controller.dart`

```dart
void _handlePostLoginRouting(AppUser user) {
  switch (user.role) {
    case UserRole.admin:
      Get.offAllNamed('/admin-home');
      break;
    case UserRole.picker:
      Get.offAllNamed('/picker-home');
      break;
    case UserRole.client:
      Get.offAllNamed('/client-home');
      break;
  }
}
```

**Flux de connexion**:
1. Utilisateur entre téléphone + mot de passe
2. `signInWithPhonePassword()` - authentification Firebase
3. Récupération du document Firestore `users/{uid}`
4. Lecture du champ `role`
5. Redirection automatique vers le dashboard approprié

### Routes Configurées

**Fichier**: `lib/main.dart`

```dart
GetPage(
  name: '/admin-home',
  page: () => const AdminHomeScreen(),
  binding: AdminBinding(),
),
GetPage(
  name: '/picker-home',
  page: () => const PickerHomeScreen(),
  binding: PickerBinding(),
),
GetPage(
  name: '/client-home',
  page: () => const ClientHomeScreen(),
  binding: ClientBinding(),
),
```

### Création du Compte Admin

Pour créer votre compte admin, dans Firestore Console:
1. Aller dans `users/{votre_uid}`
2. Modifier le champ `role`: `"admin"` (au lieu de `"client"` ou `"picker"`)
3. Se connecter via l'app → redirection automatique vers `/admin-home`

---

## PARTIE 2 - DASHBOARD ADMIN

### Structure

**Fichier**: `lib/features/admin/admin_home_screen.dart`

Le dashboard admin utilise un `TabBarView` avec 3 onglets:
1. **Tableau de bord** - Statistiques en temps réel
2. **Pickers** - Gestion des pickers
3. **Carte** - Vue globale avec tous les markers

### Onglet 1: Tableau de Bord (Statistiques)

**Controller**: `lib/features/admin/controllers/admin_home_controller.dart`

**Métriques affichées**:
- **Pickers Total**: Nombre total de pickers dans la base
- **Pickers Actifs**: Nombre de pickers avec `status == active`
- **Clients actifs**: Nombre de clients uniques ayant une demande active
- **Demandes actives**: Nombre total de demandes `pending` ou `inTransit`

**Requêtes Firestore**:
```dart
// Écouter tous les pickers
_firestoreService.listenToPickers().listen((pickersList) {
  pickers.value = pickersList;
  totalPickers.value = pickersList.length;
  activePickers.value = pickersList.where((p) => p.status == UserStatus.active).length;
});

// Écouter les demandes actives
_firestoreService.listenToActiveTrashReports().listen((reports) {
  totalActiveRequests.value = reports.length;
  final uniqueClients = reports.map((r) => r.clientId).toSet();
  clientsWithActiveRequests.value = uniqueClients.length;
});
```

### Onglet 2: Gestion des Pickers

**Fonctionnalités**:
- Liste tous les pickers (nom, téléphone, zone, statut)
- Bouton **"Créer"** → Nouveau picker
- Menu contextuel (3 points) pour chaque picker:
  - **Modifier** → Éditer les infos
  - **Activer/Désactiver** → Toggle `status`
  - **Supprimer** → Suppression avec confirmation

#### Créer un Picker

**Écran**: `lib/features/admin/admin_picker_form_screen.dart`
**Controller**: `lib/features/admin/controllers/admin_picker_form_controller.dart`

**Champs du formulaire**:
- Nom complet (obligatoire)
- Téléphone 9 chiffres (obligatoire, +237 auto-ajouté)
- Mot de passe (obligatoire, min 6 caractères)
- Zone/Quartier (optionnel)
- Adresse (optionnel)

**Processus de création**:
```dart
1. Génération fake email: `237{phone}@trashpicker.app`
2. Firebase Auth: createUserWithEmailAndPassword(email, password)
3. Firestore: Création doc users/{uid} avec:
   - role: "picker"
   - status: "active"
   - phone, name, quartier, address
4. Redirection + notification succès
```

**Code clé**:
```dart
final userCredential = await _authService.createUserWithEmailPassword(
  fullPhone,
  password,
);

final newPicker = AppUser(
  id: userCredential.user!.uid,
  phone: fullPhone,
  name: name,
  role: UserRole.picker,
  quartier: quartier.isEmpty ? null : quartier,
  address: address.isEmpty ? null : address,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  status: UserStatus.active,
);

await _firestoreService.createUser(newPicker);
```

#### Éditer un Picker

- Même formulaire que création
- Téléphone non modifiable (disabled)
- Mot de passe optionnel (uniquement si changement)
- Mise à jour Firestore des champs modifiés

#### Activer/Désactiver un Picker

```dart
Future<void> togglePickerStatus(AppUser picker) async {
  final newStatus = picker.status == UserStatus.active
      ? UserStatus.inactive
      : UserStatus.active;

  await _firestoreService.updateUser(picker.id, {
    'status': newStatus.name,
  });
}
```

#### Supprimer un Picker

```dart
Future<void> deletePicker(String pickerId) async {
  await _firestoreService.deleteUser(pickerId);
  Get.snackbar('Succès', 'Picker supprimé');
}
```

**Note**: Supprime le document Firestore. Firebase Auth user reste (nécessite Admin SDK côté serveur pour supprimer complètement).

### Onglet 3: Carte Globale

**Écran**: `lib/features/admin/admin_map_screen.dart`
**Controller**: `lib/features/admin/controllers/admin_map_controller.dart`

**Markers affichés**:
1. **Pickers actifs** (Bleu)
   - Récupère tous les pickers avec `status == active`
   - Affiche marker uniquement si `latitude` et `longitude` sont définis

2. **Demandes actives** (Rouge/Orange)
   - Rouge: `status == pending`
   - Orange: `status == inTransit`
   - Affiche position de chaque demande

**Légende**:
- Info card en haut avec:
  - Nombre de pickers actifs
  - Nombre de demandes actives

**Code clé**:
```dart
// Markers pickers (bleu)
for (final picker in activePickers) {
  if (picker.latitude != null && picker.longitude != null) {
    markers.add(
      Marker(
        markerId: MarkerId('picker_${picker.id}'),
        position: LatLng(picker.latitude!, picker.longitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: 'Picker: ${picker.name}',
          snippet: picker.quartier ?? '',
        ),
      ),
    );
  }
}

// Markers demandes (rouge/orange)
for (final request in activeRequests) {
  markers.add(
    Marker(
      markerId: MarkerId('request_${request.id}'),
      position: LatLng(request.latitude, request.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        request.status == TrashStatus.pending
            ? BitmapDescriptor.hueRed
            : BitmapDescriptor.hueOrange,
      ),
      infoWindow: InfoWindow(
        title: request.status == TrashStatus.pending
            ? 'Demande en attente'
            : 'En cours de récupération',
        snippet: request.quartier ?? '',
      ),
    ),
  );
}
```

---

## PARTIE 3 - CARTES AVEC MARKERS

### CLIENT - Carte avec Position

**Controller**: `lib/features/client/controllers/client_home_controller.dart`

**Marker affiché**:
- Position du client (Vert)
- Récupérée via `LocationService` ou depuis `user.latitude/longitude`

**Code**:
```dart
Set<Marker> getMarkers() {
  final markers = <Marker>{};

  if (userLocation != null) {
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: userLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: currentUser.value?.name ?? 'Ma position',
          snippet: currentUser.value?.address ?? '',
        ),
      ),
    );
  }

  return markers;
}
```

### PICKER - Carte avec Position + Demandes

**Controller**: `lib/features/picker/controllers/picker_home_controller.dart`

**Markers affichés**:
1. **Position du picker** (Bleu)
2. **Demandes en attente** (Orange)
   - Récupère via `listenToAllPendingTrash()` ou `listenToPendingTrashInZone()`
   - Un marker par demande
   - Tap sur marker → Détails de la demande

**Code**:
```dart
Set<Marker> getMarkers(Function(TrashReport) onTap) {
  final markers = <Marker>{};

  // Marker picker (bleu)
  if (pickerLocation != null) {
    markers.add(
      Marker(
        markerId: const MarkerId('picker_location'),
        position: pickerLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: currentUser.value?.name ?? 'Ma position',
          snippet: 'Picker',
        ),
      ),
    );
  }

  // Markers demandes (orange)
  for (final report in pendingTrashReports) {
    markers.add(
      Marker(
        markerId: MarkerId(report.id),
        position: LatLng(report.latitude, report.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: 'Trash #${report.id.substring(0, 6)}',
          snippet: report.quartier ?? 'Tap pour détails',
        ),
        onTap: () => onTap(report),
      ),
    );
  }

  return markers;
}
```

**Tri par distance**:
- Les demandes sont triées par proximité via `_calculateDistances()`
- Utilise `LocationService.getDistanceBetween()`
- Affichage dans ListView avec distance formatée (m ou km)

### ADMIN - Carte Globale

Voir section "Onglet 3: Carte Globale" ci-dessus.

---

## MÉTHODES FIRESTORE AJOUTÉES

**Fichier**: `lib/services/firestore_service.dart`

### Gestion des Users

```dart
// Supprimer un user
Future<void> deleteUser(String userId)

// Écouter tous les pickers
Stream<List<AppUser>> listenToPickers() {
  return _firestore
      .collection(usersCollection)
      .where('role', isEqualTo: UserRole.picker.name)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList());
}
```

### Gestion des Trash Reports

```dart
// Écouter demandes actives (pending + inTransit)
Stream<List<TrashReport>> listenToActiveTrashReports() {
  return _firestore
      .collection(trashReportsCollection)
      .where('status', whereIn: [
        TrashStatus.pending.name,
        TrashStatus.inTransit.name,
      ])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => TrashReport.fromMap(doc.data())).toList());
}
```

---

## MÉTHODES AUTH AJOUTÉES

**Fichier**: `lib/services/auth_service.dart`

```dart
// Créer un compte avec email/password (pour admin/picker)
Future<UserCredential> createUserWithEmailPassword(String phone, String password) {
  final email = _phoneToEmail(phone);
  return _auth.createUserWithEmailAndPassword(email: email, password: password);
}
```

---

## RÉSUMÉ DES FICHIERS CRÉÉS

### Admin
- `lib/features/admin/admin_home_screen.dart`
- `lib/features/admin/admin_picker_form_screen.dart`
- `lib/features/admin/admin_map_screen.dart`
- `lib/features/admin/controllers/admin_home_controller.dart`
- `lib/features/admin/controllers/admin_picker_form_controller.dart`
- `lib/features/admin/controllers/admin_map_controller.dart`
- `lib/bindings/admin_binding.dart`

### Modifications
- `lib/main.dart` - Routes admin
- `lib/services/auth_service.dart` - Méthode createUserWithEmailPassword
- `lib/services/firestore_service.dart` - Méthodes pickers + demandes actives
- `lib/features/auth/controllers/login_controller.dart` - Routing par rôle

---

## BONNES PRATIQUES GETX RESPECTÉES

✅ **Pas de nested Obx**: Chaque widget réactif a son propre Obx
✅ **Pas d'Obx sur GoogleMap**: userLocation n'est pas Rx
✅ **Bindings pour injection**: AdminBinding, ClientBinding, PickerBinding
✅ **Controllers séparés**: Un controller par écran/fonctionnalité
✅ **Dispose automatique**: onClose() pour les TextEditingController
✅ **Pas d'UI dans les controllers**: Dialogs et widgets dans les screens

---

## TESTING

### Créer un Admin
1. Se connecter avec un compte client existant
2. Firestore Console → `users/{uid}` → Modifier `role: "admin"`
3. Se déconnecter et se reconnecter
4. Redirection automatique vers `/admin-home`

### Créer un Picker (via Admin)
1. Se connecter en tant qu'admin
2. Onglet "Pickers" → Bouton "Créer"
3. Remplir le formulaire:
   - Nom: "Jean Picker"
   - Téléphone: 612345678 (9 chiffres, +237 auto)
   - Mot de passe: minimum 6 caractères
   - Zone: "Bonamoussadi" (optionnel)
4. Cliquer "Créer le picker"
5. Vérifier dans Firestore: `users/{uid}` avec `role: "picker"`

### Tester le Picker
1. Se déconnecter
2. Login avec le numéro du picker + mot de passe
3. Redirection vers `/picker-home`
4. Voir la carte avec:
   - Marker bleu (position picker)
   - Markers orange (demandes clients actives)

### Tester la Carte Admin
1. Créer quelques pickers
2. Créer quelques demandes clients (toggle ON sur client dashboard)
3. Admin → Onglet "Carte"
4. Voir tous les markers:
   - Bleu = Pickers actifs
   - Rouge = Demandes en attente
   - Orange = Demandes en cours

---

## NOTES IMPORTANTES

1. **Localisation Firestore**: Les coordonnées (`latitude`, `longitude`) doivent être mises à jour dans Firestore pour que les markers s'affichent sur les cartes

2. **Mot de passe admin pour pickers**: Le changement de mot de passe via l'admin nécessite Admin SDK côté serveur ou que le picker se connecte et change son mot de passe lui-même

3. **Suppression complète**: `deleteUser()` supprime le doc Firestore mais pas l'utilisateur Firebase Auth (nécessite Admin SDK)

4. **Performance**: Les streams Firestore sont en temps réel. Pour de grandes quantités de données, considérer la pagination ou des snapshots limités

5. **Permissions Firestore**: Mettre à jour les Firestore Rules pour autoriser les admins à créer/modifier/supprimer des pickers:
   ```javascript
   match /users/{userId} {
     allow read: if request.auth != null;
     allow write: if request.auth != null &&
                     (request.auth.uid == userId ||
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
   }
   ```

---

**Toutes les fonctionnalités demandées ont été implémentées avec succès ✅**
