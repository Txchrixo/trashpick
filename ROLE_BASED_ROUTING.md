# Système de Routing Basé sur les Rôles

## Problème Résolu

Lorsqu'un admin se connectait et rechargeait la page web, il était redirigé vers `/client-home` au lieu de `/admin-home`. Cela était dû à une route initiale hardcodée qui ne vérifiait pas le rôle de l'utilisateur.

## Solution Implémentée

### 1. AuthWrapper (`lib/core/auth_wrapper.dart`)

Widget de point d'entrée qui:
- Écoute l'état d'authentification Firebase
- Si non authentifié → redirige vers `/welcome`
- Si authentifié → charge les données utilisateur depuis Firestore
- Redirige automatiquement vers la bonne route selon le rôle:
  - `UserRole.admin` → `/admin-home`
  - `UserRole.picker` → `/picker-home`
  - `UserRole.client` → `/client-home`

### 2. RoleGuard (`lib/core/role_middleware.dart`)

Widget de protection qui entoure chaque écran protégé:
- Vérifie que l'utilisateur est authentifié
- Charge les données utilisateur en temps réel
- Vérifie que le rôle de l'utilisateur est dans la liste des rôles autorisés
- Si le rôle ne correspond pas → redirige vers la bonne page
- Empêche l'accès non autorisé même en cas de navigation manuelle

### 3. Routes Protégées (`lib/main.dart`)

Toutes les routes spécifiques aux rôles sont maintenant protégées:

```dart
// Admin - Accessible uniquement aux admins
GetPage(
  name: '/admin-home',
  page: () => const RoleGuard(
    allowedRoles: [UserRole.admin],
    child: AdminHomeScreen(),
  ),
  binding: AdminBinding(),
),

// Picker - Accessible uniquement aux pickers
GetPage(
  name: '/picker-home',
  page: () => const RoleGuard(
    allowedRoles: [UserRole.picker],
    child: PickerHomeScreen(),
  ),
  binding: PickerBinding(),
),

// Client - Accessible uniquement aux clients
GetPage(
  name: '/client-home',
  page: () => const RoleGuard(
    allowedRoles: [UserRole.client],
    child: ClientHomeScreen(),
  ),
  binding: ClientBinding(),
),
```

## Flux de Navigation

### Au démarrage de l'application:

1. L'app démarre sur la route `/` (AuthWrapper)
2. AuthWrapper vérifie l'état d'authentification:
   - **Non authentifié** → Redirige vers `/welcome`
   - **Authentifié** → Charge les données Firestore et redirige selon le rôle

### Lors d'un reload (F5) ou navigation directe:

1. L'utilisateur tente d'accéder à une route (ex: `/admin-home`)
2. Le RoleGuard vérifie:
   - Utilisateur authentifié ? ✓
   - Rôle = admin ? ✓
   - Accès accordé ✓
3. Si le rôle ne correspond pas:
   - RoleGuard détecte que l'utilisateur est un client
   - Redirige automatiquement vers `/client-home`

### Lors de la connexion:

1. L'utilisateur se connecte avec succès
2. AuthWrapper détecte le changement d'état d'authentification
3. Charge les données utilisateur
4. Redirige automatiquement vers la bonne page selon le rôle

## Sécurité

- ✅ Chaque route protégée est enveloppée dans un RoleGuard
- ✅ Vérification en temps réel du rôle via Firestore stream
- ✅ Redirection automatique si le rôle ne correspond pas
- ✅ Impossible d'accéder à une route sans le bon rôle
- ✅ Fonctionne même lors des reloads (F5) ou navigation directe

## Avantages

1. **Séparation des préoccupations**: Chaque rôle a son propre espace protégé
2. **Sécurité renforcée**: Impossible de contourner via l'URL
3. **Expérience utilisateur**: Redirection automatique et transparente
4. **Maintenance**: Facile d'ajouter de nouveaux rôles ou routes protégées
5. **Réactivité**: Utilise des streams pour détecter les changements de rôle en temps réel

## Notes

- Les prints de debug peuvent être supprimés en production
- Le système fonctionne sur mobile, web et desktop
- Tous les reloads préservent maintenant le contexte du rôle
