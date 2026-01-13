import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/app_user.dart';
import 'controllers/admin_home_controller.dart';
import 'admin_picker_form_screen.dart';
import 'admin_map_screen.dart';
import 'admin_quartiers_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late final AdminHomeController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AdminHomeController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo-trashpick-admin.png',
          height: 60,
          fit: BoxFit.contain,
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () => _showProfileMenu(controller),
            ),
          ),
        ],
        bottom: TabBar(
          controller: controller.tabController,
          indicatorColor: AppColors.textWhite,
          labelColor: AppColors.textWhite,
          unselectedLabelColor: AppColors.textWhite.withValues(alpha: 0.7),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Tableau de bord'),
            Tab(icon: Icon(Icons.people), text: 'Pickers'),
            Tab(icon: Icon(Icons.person_outline), text: 'Clients'),
            Tab(icon: Icon(Icons.location_city), text: 'Quartiers'),
            Tab(icon: Icon(Icons.map), text: 'Carte'),
          ],
        ),
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: [
          _buildDashboardTab(controller),
          _buildPickersTab(controller),
          _buildClientsTab(controller),
          const AdminQuartiersScreen(),
          const AdminMapScreen(),
        ],
      ),
    );
  }

  void _showProfileMenu(AdminHomeController controller) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(
                'Se déconnecter',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
              ),
              onTap: controller.logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab(AdminHomeController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 16),
          Obx(() => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildClickableStatCard(
                    'Pickers Total',
                    controller.totalPickers.value.toString(),
                    Icons.people,
                    AppColors.primary,
                    () => controller.navigateToPickersTab(),
                  ),
                  _buildClickableStatCard(
                    'Pickers Actifs',
                    controller.activePickers.value.toString(),
                    Icons.check_circle,
                    AppColors.success,
                    () => controller.navigateToPickersTab(activeOnly: true),
                  ),
                  _buildClickableStatCard(
                    'Clients Total',
                    controller.totalClients.value.toString(),
                    Icons.person_outline,
                    AppColors.info,
                    () => controller.navigateToClientsTab(),
                  ),
                  _buildClickableStatCard(
                    'Clients Actifs',
                    controller.clientsWithActiveRequests.value.toString(),
                    Icons.person,
                    AppColors.secondary,
                    () => controller.navigateToClientsTab(activeOnly: true),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildClickableStatCard(
      String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: AppTextStyles.h2.copyWith(color: color),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickersTab(AdminHomeController controller) {
    return Column(
      children: [
        _buildSearchAndFilters(
          controller: controller,
          isPicker: true,
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final pickers = controller.filteredPickers;

            if (pickers.isEmpty) {
              return _buildEmptyState(
                icon: Icons.people_outline,
                message: controller.pickerSearchQuery.value.isNotEmpty ||
                        controller.pickerQuartierFilter.value.isNotEmpty
                    ? 'Aucun picker trouvé'
                    : 'Aucun picker',
                actionLabel: 'Créer un picker',
                onAction: () => Get.to(() => const AdminPickerFormScreen()),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pickers.length,
              itemBuilder: (context, index) {
                final picker = pickers[index];
                return _buildPickerCard(controller, picker);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildClientsTab(AdminHomeController controller) {
    return Column(
      children: [
        _buildSearchAndFilters(
          controller: controller,
          isPicker: false,
        ),
        Expanded(
          child: Obx(() {
            final clients = controller.filteredClients;

            if (clients.isEmpty) {
              return _buildEmptyState(
                icon: Icons.person_outline,
                message: controller.clientSearchQuery.value.isNotEmpty ||
                        controller.clientQuartierFilter.value.isNotEmpty
                    ? 'Aucun client trouvé'
                    : 'Aucun client',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                return _buildClientCard(controller, client);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters({
    required AdminHomeController controller,
    required bool isPicker,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: isPicker
                ? controller.pickerSearchController
                : controller.clientSearchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, téléphone, adresse...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Obx(() {
                final hasText = isPicker
                    ? controller.pickerSearchQuery.value.isNotEmpty
                    : controller.clientSearchQuery.value.isNotEmpty;
                return hasText
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          if (isPicker) {
                            controller.pickerSearchController.clear();
                          } else {
                            controller.clientSearchController.clear();
                          }
                        },
                      )
                    : const SizedBox.shrink();
              }),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filtres
          Row(
            children: [
              // Filtre quartier
              Expanded(
                child: Obx(() {
                  final filterValue = isPicker
                      ? controller.pickerQuartierFilter.value
                      : controller.clientQuartierFilter.value;
                  return DropdownButtonFormField<String>(
                      value: filterValue.isEmpty ? null : filterValue,
                      decoration: InputDecoration(
                        labelText: 'Quartier',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Tous les quartiers'),
                        ),
                        ...controller.availableQuartiers.map((quartier) {
                          return DropdownMenuItem<String>(
                            value: quartier,
                            child: Text(quartier),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        if (isPicker) {
                          controller.setPickerQuartierFilter(value);
                        } else {
                          controller.setClientQuartierFilter(value);
                        }
                      },
                    );
                }),
              ),
              const SizedBox(width: 8),
              // Filtre actifs uniquement
              Obx(() => FilterChip(
                    label: Text(isPicker ? 'Actifs' : 'Avec demande'),
                    selected: isPicker
                        ? controller.pickerActiveOnlyFilter.value
                        : controller.clientActiveOnlyFilter.value,
                    onSelected: (_) {
                      if (isPicker) {
                        controller.togglePickerActiveFilter();
                      } else {
                        controller.toggleClientActiveFilter();
                      }
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                  )),
              const SizedBox(width: 8),
              // Bouton clear
              Obx(() {
                final hasFilters = isPicker
                    ? (controller.pickerSearchQuery.value.isNotEmpty ||
                        controller.pickerQuartierFilter.value.isNotEmpty ||
                        controller.pickerActiveOnlyFilter.value)
                    : (controller.clientSearchQuery.value.isNotEmpty ||
                        controller.clientQuartierFilter.value.isNotEmpty ||
                        controller.clientActiveOnlyFilter.value);

                return hasFilters
                    ? IconButton(
                        icon: const Icon(Icons.clear_all),
                        onPressed: () {
                          if (isPicker) {
                            controller.clearPickerFilters();
                          } else {
                            controller.clearClientFilters();
                          }
                        },
                        tooltip: 'Effacer les filtres',
                      )
                    : const SizedBox.shrink();
              }),
            ],
          ),
          // Bouton créer pour pickers
          if (isPicker) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Get.to(() => const AdminPickerFormScreen()),
                icon: const Icon(Icons.add),
                label: const Text('Créer un picker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPickerCard(AdminHomeController controller, AppUser picker) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        onTap: () => controller.viewPickerDetails(picker),
        leading: CircleAvatar(
          backgroundColor: picker.status == UserStatus.active
              ? AppColors.success
              : AppColors.textSecondary,
          child: const Icon(Icons.local_shipping, color: AppColors.textWhite),
        ),
        title: Text(picker.name, style: AppTextStyles.labelLarge),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(picker.phone, style: AppTextStyles.bodySmall),
            if (picker.quartier != null)
              Text('📍 ${picker.quartier}', style: AppTextStyles.bodySmall),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Get.to(() => const AdminPickerFormScreen(), arguments: picker);
            } else if (value == 'toggle') {
              controller.togglePickerStatus(picker);
            } else if (value == 'delete') {
              _showDeleteConfirmation(controller, picker);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    picker.status == UserStatus.active
                        ? Icons.block
                        : Icons.check_circle,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    picker.status == UserStatus.active
                        ? 'Désactiver'
                        : 'Activer',
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Supprimer',
                      style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(AdminHomeController controller, AppUser client) {
    final hasActiveRequest = controller.hasActiveRequest(client.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              hasActiveRequest ? AppColors.primary : AppColors.textSecondary,
          child: Text(
            client.name[0].toUpperCase(),
            style: AppTextStyles.h4.copyWith(color: AppColors.textWhite),
          ),
        ),
        title: Text(client.name, style: AppTextStyles.labelLarge),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(client.phone, style: AppTextStyles.bodySmall),
            if (client.quartier != null)
              Text('📍 ${client.quartier}', style: AppTextStyles.bodySmall),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: hasActiveRequest
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                hasActiveRequest ? 'Demande active' : 'Pas de demande',
                style: AppTextStyles.bodySmall.copyWith(
                  color: hasActiveRequest
                      ? AppColors.success
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => controller.viewClientDetails(client),
      ),
    );
  }

  void _showDeleteConfirmation(
      AdminHomeController controller, AppUser picker) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${picker.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deletePicker(picker.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
