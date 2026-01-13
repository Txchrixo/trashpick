import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class RoleMiddleware extends GetMiddleware {
  final List<UserRole> allowedRoles;

  RoleMiddleware({required this.allowedRoles});

  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();
    final userId = authService.userId;

    // Pas authentifié -> rediriger vers welcome
    if (userId == null) {
      return const RouteSettings(name: '/welcome');
    }

    // Pour vérifier le rôle, on doit faire une requête async
    // On va utiliser FutureBuilder dans le middleware n'est pas idéal
    // On va plutôt bloquer l'accès au niveau de l'écran
    return null;
  }
}

/// Widget de protection de route par rôle
class RoleGuard extends StatelessWidget {
  final List<UserRole> allowedRoles;
  final Widget child;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final firestoreService = FirestoreService();
    final userId = authService.userId;

    // Pas authentifié
    if (userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/welcome');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return StreamBuilder<AppUser?>(
      stream: firestoreService.listenToUser(userId),
      builder: (context, snapshot) {
        // Chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Utilisateur non trouvé
        if (!snapshot.hasData || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed('/complete-profile');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data!;

        // Vérifier le rôle
        if (!allowedRoles.contains(user.role)) {
          // Rediriger vers la bonne page selon le rôle
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final correctRoute = _getRouteForRole(user.role);
            Get.offAllNamed(correctRoute);
          });
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.block,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Accès refusé',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Vous n\'avez pas accès à cette page.'),
                  const SizedBox(height: 8),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        // Rôle autorisé
        return child;
      },
    );
  }

  String _getRouteForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return '/admin-home';
      case UserRole.picker:
        return '/picker-home';
      case UserRole.client:
        return '/client-home';
    }
  }
}
