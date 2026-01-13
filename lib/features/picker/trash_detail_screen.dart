import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/trash_report.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import 'controllers/picker_home_controller.dart';

class TrashDetailScreen extends StatefulWidget {
  final TrashReport trashReport;
  final double? distance;

  const TrashDetailScreen({
    super.key,
    required this.trashReport,
    this.distance,
  });

  @override
  State<TrashDetailScreen> createState() => _TrashDetailScreenState();
}

class _TrashDetailScreenState extends State<TrashDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  AppUser? clientUser;
  String? clientFoyer;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClientData();
  }

  Future<void> _loadClientData() async {
    final user = await _firestoreService.getUser(widget.trashReport.clientId);

    // Charger le foyer depuis Firestore
    String? foyer;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.trashReport.clientId)
          .get();
      foyer = userDoc.data()?['foyer'] as String?;
    } catch (e) {
      print('Erreur chargement foyer: $e');
    }

    setState(() {
      clientUser = user;
      clientFoyer = foyer;
      isLoading = false;
    });
  }

  Future<void> _openGoogleMaps() async {
    final lat = widget.trashReport.latitude;
    final lng = widget.trashReport.longitude;
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Erreur', 'Impossible d\'ouvrir Google Maps');
    }
  }

  Future<void> _markAsCompleted() async {
    final controller = Get.find<PickerHomeController>();

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmer la récupération'),
        content: const Text('Avez-vous récupéré ce trash?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (result == true) {
      await controller.markAsCompleted(widget.trashReport.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PickerHomeController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isLoading || clientFoyer == null
              ? 'Détails'
              : 'Poubelle $clientFoyer #${widget.trashReport.id.substring(0, 6)}',
        ),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textWhite,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.trashReport.photosUrls.isNotEmpty)
                    SizedBox(
                      height: 250,
                      child: PageView.builder(
                        itemCount: widget.trashReport.photosUrls.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            widget.trashReport.photosUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.divider,
                                child: Icon(
                                  Icons.broken_image,
                                  size: 80,
                                  color: AppColors.textHint,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor()
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getStatusColor(),
                                ),
                              ),
                              child: Text(
                                _getStatusText(),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: _getStatusColor(),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (widget.distance != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.navigation_outlined,
                                    size: 16,
                                    color: AppColors.info,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    controller.formatDistance(widget.distance!),
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Informations du client',
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.person_outline,
                          'Nom',
                          clientUser?.name ?? 'Chargement...',
                        ),
                        const SizedBox(height: 12),
                        if (clientFoyer != null)
                          _buildInfoRow(
                            Icons.home_outlined,
                            'Foyer',
                            clientFoyer!,
                          ),
                        const SizedBox(height: 12),
                        if (clientUser?.address != null)
                          _buildInfoRow(
                            Icons.location_on_outlined,
                            'Adresse',
                            clientUser!.address!,
                          ),
                        const SizedBox(height: 12),
                        if (widget.trashReport.quartier != null)
                          _buildInfoRow(
                            Icons.map_outlined,
                            'Quartier',
                            widget.trashReport.quartier!,
                          ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.phone_outlined,
                          'Téléphone',
                          clientUser?.phone ?? '-',
                        ),
                        if (clientUser?.alternativePhone != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.phone_outlined,
                            'Téléphone alternatif',
                            clientUser!.alternativePhone!,
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (widget.trashReport.clientNotes != null &&
                            widget.trashReport.clientNotes!.isNotEmpty) ...[
                          Text(
                            'Notes du client',
                            style: AppTextStyles.h4,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Text(
                              widget.trashReport.clientNotes!,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openGoogleMaps,
                                icon: const Icon(Icons.navigation),
                                label: const Text('Naviguer'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  foregroundColor: AppColors.info,
                                  side: BorderSide(color: AppColors.info),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (widget.trashReport.status == TrashStatus.pending)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _markAsCompleted,
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Trash récupéré ✓'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: AppColors.textWhite,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (widget.trashReport.status) {
      case TrashStatus.pending:
        return AppColors.warning;
      case TrashStatus.inTransit:
        return AppColors.info;
      case TrashStatus.completed:
        return AppColors.success;
      case TrashStatus.cancelled:
        return AppColors.error;
    }
  }

  String _getStatusText() {
    switch (widget.trashReport.status) {
      case TrashStatus.pending:
        return 'En attente';
      case TrashStatus.inTransit:
        return 'En transit';
      case TrashStatus.completed:
        return 'Récupéré';
      case TrashStatus.cancelled:
        return 'Annulé';
    }
  }
}
