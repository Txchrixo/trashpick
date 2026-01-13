import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final firestoreService = FirestoreService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        // Pas encore chargé
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Pas authentifié
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.currentRoute != '/welcome') {
              Get.offAllNamed('/welcome');
            }
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Authentifié - Vérifier le rôle
        final userId = authSnapshot.data!.uid;

        return StreamBuilder<AppUser?>(
          stream: firestoreService.listenToUser(userId),
          builder: (context, userSnapshot) {
            // Chargement des données utilisateur
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Utilisateur n'existe pas dans Firestore
            if (!userSnapshot.hasData || userSnapshot.data == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Get.currentRoute != '/complete-profile') {
                  Get.offAllNamed('/complete-profile');
                }
              });
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Rediriger selon le rôle
            final user = userSnapshot.data!;
            final targetRoute = _getRouteForRole(user.role);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Get.currentRoute != targetRoute) {
                // Debug: Redirection vers $targetRoute pour role=${user.role.name}
                Get.offAllNamed(targetRoute);
              }
            });

            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        );
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
