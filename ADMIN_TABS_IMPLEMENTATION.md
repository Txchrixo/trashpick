# Implémentation Admin - Tabs avec Recherche et Filtres

## Vue d'ensemble

Système admin unifié avec 4 tabs intégrés dans un seul écran, incluant recherche et filtres pour pickers et clients.

## Architecture

### Principe de réutilisation de code
- **Un seul controller**: `AdminHomeController` gère tout (analytics, pickers, clients)
- **Un seul écran**: `AdminHomeScreen` avec TabController
- **Widgets réutilisables**: Méthodes `_buildSearchAndFilters()`, `_buildPickerCard()`, `_buildClientCard()`
- **Navigation intelligente**: Cartes analytics naviguent vers les tabs avec filtres pré-appliqués

## Structure des Tabs

### Tab 1: Dashboard
- Cartes analytics cliquables
- Navigation vers tabs Pickers/Clients avec filtres

### Tab 2: Pickers
- Barre de recherche (nom, téléphone, adresse, quartier)
- Filtre dropdown par quartier
- FilterChip "Actifs uniquement"
- Bouton "Créer un picker"
- Liste des pickers avec menu actions

### Tab 3: Clients
- Barre de recherche (nom, téléphone, adresse, quartier)
- Filtre dropdown par quartier
- FilterChip "Avec demande active"
- Liste des clients avec badge demande active/inactive
- Clic → navigation vers détails client

### Tab 4: Carte
- AdminMapScreen (inchangé)

## AdminHomeController - Fonctionnalités

### Gestion des données
```dart
// Listes complètes
final RxList<AppUser> allPickers = <AppUser>[].obs;
final RxList<AppUser> allClients = <AppUser>[].obs;

// Stats en temps réel
final RxInt totalPickers = 0.obs;
final RxInt activePickers = 0.obs;
final RxInt totalClients = 0.obs;
final RxInt clientsWithActiveRequests = 0.obs;

// Tracking demandes actives
final RxMap<String, bool> clientHasActiveRequest = <String, bool>{}.obs;
```

### Recherche et filtres - Pickers
```dart
final TextEditingController pickerSearchController;
final RxString pickerSearchQuery = ''.obs;
final RxString pickerQuartierFilter = ''.obs;
final RxBool pickerActiveOnlyFilter = false.obs;

// Pickers filtrés (computed getter)
List<AppUser> get filteredPickers {
  // Filtre par status actif
  // Filtre par quartier
  // Recherche dans: nom, téléphone, adresse, quartier
}
```

### Recherche et filtres - Clients
```dart
final TextEditingController clientSearchController;
final RxString clientSearchQuery = ''.obs;
final RxString clientQuartierFilter = ''.obs;
final RxBool clientActiveOnlyFilter = false.obs;

// Clients filtrés (computed getter)
List<AppUser> get filteredClients {
  // Filtre clients avec demande active
  // Filtre par quartier
  // Recherche dans: nom, téléphone, adresse, quartier
}
```

### Quartiers disponibles
```dart
final RxList<String> availableQuartiers = <String>[].obs;

void _updateQuartiers() {
  // Extrait tous les quartiers uniques depuis pickers + clients
  // Trie alphabétiquement
}
```

### Navigation depuis analytics
```dart
void navigateToPickersTab({bool activeOnly = false}) {
  tabController.animateTo(1); // Index du tab Pickers
  if (activeOnly) {
    pickerActiveOnlyFilter.value = true;
  }
}

void navigateToClientsTab({bool activeOnly = false}) {
  tabController.animateTo(2); // Index du tab Clients
  if (activeOnly) {
    clientActiveOnlyFilter.value = true;
  }
}
```

## Widget de recherche et filtres

Méthode réutilisable pour pickers ET clients:

```dart
Widget _buildSearchAndFilters({
  required AdminHomeController controller,
  required bool isPicker, // true = pickers, false = clients
})
```

### Composants
1. **TextField de recherche**
   - Placeholder: "Rechercher par nom, téléphone, adresse..."
   - Icône search à gauche
   - Bouton clear (X) à droite si texte présent
   - Controller: `pickerSearchController` ou `clientSearchController`

2. **Dropdown Quartier**
   - Option par défaut: "Tous les quartiers"
   - Liste dynamique depuis `availableQuartiers`
   - Mise à jour via `setPickerQuartierFilter()` / `setClientQuartierFilter()`

3. **FilterChip "Actifs" / "Avec demande"**
   - Pickers: "Actifs" (status = active)
   - Clients: "Avec demande" (demande active)
   - Toggle via `togglePickerActiveFilter()` / `toggleClientActiveFilter()`

4. **Bouton "Effacer les filtres"**
   - Visible uniquement si filtres actifs
   - Icône `clear_all`
   - Appelle `clearPickerFilters()` / `clearClientFilters()`

5. **Bouton "Créer un picker"** (pickers uniquement)
   - Pleine largeur
   - Navigation vers `AdminPickerFormScreen`

## Flux de navigation Analytics → Tabs

### Carte "Pickers Total"
```dart
onTap: () => controller.navigateToPickersTab()
// → Navigue vers tab Pickers
// → Affiche tous les pickers
```

### Carte "Pickers Actifs"
```dart
onTap: () => controller.navigateToPickersTab(activeOnly: true)
// → Navigue vers tab Pickers
// → Active filtre "Actifs uniquement"
// → Affiche uniquement pickers status = active
```

### Carte "Clients Total"
```dart
onTap: () => controller.navigateToClientsTab()
// → Navigue vers tab Clients
// → Affiche tous les clients
```

### Carte "Clients Actifs"
```dart
onTap: () => controller.navigateToClientsTab(activeOnly: true)
// → Navigue vers tab Clients
// → Active filtre "Avec demande active"
// → Affiche uniquement clients avec demande pending/inTransit
```

## Logique de recherche

### Recherche multi-critères
La recherche s'effectue sur:
- **Nom** (case insensitive)
- **Téléphone**
- **Adresse** (si présente)
- **Quartier** (si présent)

### Combinaison des filtres
Les filtres s'appliquent dans cet ordre:
1. Filtre actifs/avec demande (si activé)
2. Filtre quartier (si sélectionné)
3. Recherche textuelle (si texte présent)

Tous les filtres sont cumulatifs (ET logique).

## Détails client

Route séparée pour les détails:
```dart
GetPage(
  name: '/admin-client-details',
  page: () => AdminClientDetailsScreen(),
)
```

Navigation depuis la liste:
```dart
onTap: () => controller.viewClientDetails(client)
// → Get.toNamed('/admin-client-details', arguments: client)
```

## Fichiers nettoyés

Fichiers supprimés (code consolidé):
- ❌ `admin_clients_screen.dart` (intégré dans tabs)
- ❌ `admin_pickers_screen.dart` (intégré dans tabs)
- ❌ `admin_clients_controller.dart` (fusionné dans AdminHomeController)

Routes supprimées:
- ❌ `/admin-clients`
- ❌ `/admin-pickers`

## Avantages de cette architecture

### ✅ Maintenabilité
- Un seul controller à maintenir
- Logique de filtre réutilisable
- Widgets communs entre pickers et clients

### ✅ Performance
- Chargement unique des données
- Filtrage côté client (instantané)
- Pas de requêtes Firestore supplémentaires

### ✅ UX
- Navigation fluide entre tabs
- Filtres persistants dans chaque tab
- Recherche en temps réel
- Navigation contextuelle depuis analytics

### ✅ Évolutivité
- Facile d'ajouter de nouveaux filtres
- Simple d'ajouter un nouveau tab
- Architecture extensible

## Code minimal

Tout est centralisé:
- **1 controller** au lieu de 3
- **1 écran** avec tabs au lieu de 3 écrans séparés
- **Navigation interne** (tabs) au lieu de routes externes
- **Méthodes réutilisables** pour widgets communs

Total: ~600 lignes au lieu de ~1200+ lignes si séparé.
