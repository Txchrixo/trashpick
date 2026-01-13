import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/app_user.dart';

class AdminClientDetailsScreen extends StatelessWidget {
  const AdminClientDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Get.arguments as AppUser?;

    if (client == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Détails Client'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
        ),
        body: const Center(
          child: Text('Client introuvable'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails Client'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Carte de profil
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          client.name[0].toUpperCase(),
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.name,
                              style: AppTextStyles.h4.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildStatusChip(client.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildInfoRow(
                    Icons.phone,
                    'Téléphone',
                    client.phone,
                  ),
                  const SizedBox(height: 12),
                  if (client.alternativePhone != null)
                    _buildInfoRow(
                      Icons.phone_android,
                      'Téléphone alternatif',
                      client.alternativePhone!,
                    ),
                  if (client.alternativePhone != null)
                    const SizedBox(height: 12),
                  if (client.quartier != null)
                    _buildInfoRow(
                      Icons.location_on,
                      'Quartier',
                      client.quartier!,
                    ),
                  if (client.quartier != null) const SizedBox(height: 12),
                  if (client.address != null)
                    _buildInfoRow(
                      Icons.home,
                      'Adresse',
                      client.address!,
                    ),
                  if (client.address != null) const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Inscrit le',
                    '${client.createdAt.day}/${client.createdAt.month}/${client.createdAt.year}',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Bouton historique
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.toNamed('/admin-client-history', arguments: client);
              },
              icon: const Icon(Icons.history),
              label: const Text('Voir l\'historique des demandes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(UserStatus status) {
    Color color;
    String text;

    switch (status) {
      case UserStatus.active:
        color = AppColors.success;
        text = 'Actif';
        break;
      case UserStatus.inactive:
        color = AppColors.textSecondary;
        text = 'Inactif';
        break;
      case UserStatus.suspended:
        color = AppColors.error;
        text = 'Suspendu';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textWhite,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
