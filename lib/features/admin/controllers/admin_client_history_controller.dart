import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/app_user.dart';
import '../../../models/trash_report.dart';
import '../../../services/firestore_service.dart';
import '../../../core/app_colors.dart';

enum QuickDateFilter {
  all,
  today,
  yesterday,
  dayBeforeYesterday,
  lastWeek,
  lastMonth,
  lastYear,
}

class AdminClientHistoryController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

  final Rx<AppUser?> client = Rx<AppUser?>(null);
  final RxList<TrashReport> allRequests = <TrashReport>[].obs;
  final RxBool isLoading = true.obs;

  // Quick date filter
  final Rx<QuickDateFilter> quickDateFilter = QuickDateFilter.all.obs;

  // Custom date filters
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    client.value = Get.arguments as AppUser?;

    if (client.value != null) {
      _loadClientRequests();
    }
  }

  void _loadClientRequests() {
    isLoading.value = true;

    // Fetch requests WITHOUT orderBy to avoid composite index requirement
    _firestoreService.listenToClientTrashReports(client.value!.id).listen(
      (requests) {
        // Sort manually in Dart
        requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        allRequests.value = requests;
        isLoading.value = false;
      },
      onError: (e) {
        isLoading.value = false;
        Get.snackbar('Erreur', 'Impossible de charger l\'historique: $e');
      },
    );
  }

  // Separate active request (only one possible)
  TrashReport? get activeRequest {
    try {
      return allRequests.firstWhere(
        (request) =>
            (request.status == TrashStatus.pending ||
                request.status == TrashStatus.inTransit) &&
            request.isActive, // CRITICAL: Must be active
      );
    } catch (_) {
      return null;
    }
  }

  // Completed requests with date filter applied
  List<TrashReport> get filteredCompletedRequests {
    var completed = allRequests.where((request) {
      return request.status == TrashStatus.completed;
    }).toList();

    // Apply quick date filter
    final dateRange = _getQuickDateRange();
    if (dateRange != null) {
      completed = completed.where((request) {
        final isAfterStart = dateRange['start'] == null ||
            request.createdAt.isAfter(dateRange['start']!) ||
            request.createdAt.isAtSameMomentAs(dateRange['start']!);
        final isBeforeEnd = dateRange['end'] == null ||
            request.createdAt.isBefore(dateRange['end']!) ||
            request.createdAt.isAtSameMomentAs(dateRange['end']!);
        return isAfterStart && isBeforeEnd;
      }).toList();
    }

    // Apply custom date filters (if quick filter is "all")
    if (quickDateFilter.value == QuickDateFilter.all) {
      if (startDate.value != null) {
        completed = completed.where((request) {
          return request.createdAt.isAfter(startDate.value!) ||
              request.createdAt.isAtSameMomentAs(startDate.value!);
        }).toList();
      }

      if (endDate.value != null) {
        final endOfDay = DateTime(
          endDate.value!.year,
          endDate.value!.month,
          endDate.value!.day,
          23,
          59,
          59,
        );
        completed = completed.where((request) {
          return request.createdAt.isBefore(endOfDay) ||
              request.createdAt.isAtSameMomentAs(endOfDay);
        }).toList();
      }
    }

    return completed;
  }

  Map<String, DateTime?>? _getQuickDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (quickDateFilter.value) {
      case QuickDateFilter.all:
        return null;
      case QuickDateFilter.today:
        return {
          'start': today,
          'end': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
      case QuickDateFilter.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return {
          'start': yesterday,
          'end': DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59),
        };
      case QuickDateFilter.dayBeforeYesterday:
        final dayBefore = today.subtract(const Duration(days: 2));
        return {
          'start': dayBefore,
          'end': DateTime(dayBefore.year, dayBefore.month, dayBefore.day, 23, 59, 59),
        };
      case QuickDateFilter.lastWeek:
        return {
          'start': today.subtract(const Duration(days: 7)),
          'end': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
      case QuickDateFilter.lastMonth:
        return {
          'start': DateTime(now.year, now.month - 1, now.day),
          'end': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
      case QuickDateFilter.lastYear:
        return {
          'start': DateTime(now.year - 1, now.month, now.day),
          'end': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
    }
  }

  String getQuickFilterLabel(QuickDateFilter filter) {
    switch (filter) {
      case QuickDateFilter.all:
        return 'Toutes les dates';
      case QuickDateFilter.today:
        return 'Aujourd\'hui';
      case QuickDateFilter.yesterday:
        return 'Hier';
      case QuickDateFilter.dayBeforeYesterday:
        return 'Avant-hier';
      case QuickDateFilter.lastWeek:
        return 'La semaine dernière';
      case QuickDateFilter.lastMonth:
        return 'Le mois dernier';
      case QuickDateFilter.lastYear:
        return 'L\'année dernière';
    }
  }

  void setQuickDateFilter(QuickDateFilter filter) {
    quickDateFilter.value = filter;
    // Reset custom dates when using quick filter
    if (filter != QuickDateFilter.all) {
      startDate.value = null;
      endDate.value = null;
    }
  }

  void setStartDate(DateTime? date) {
    startDate.value = date;
    // Reset quick filter when using custom dates
    if (date != null) {
      quickDateFilter.value = QuickDateFilter.all;
    }
  }

  void setEndDate(DateTime? date) {
    endDate.value = date;
    // Reset quick filter when using custom dates
    if (date != null) {
      quickDateFilter.value = QuickDateFilter.all;
    }
  }

  void clearDateFilters() {
    startDate.value = null;
    endDate.value = null;
    quickDateFilter.value = QuickDateFilter.all;
  }

  String getStatusText(TrashStatus status) {
    switch (status) {
      case TrashStatus.pending:
        return 'En attente';
      case TrashStatus.inTransit:
        return 'En cours';
      case TrashStatus.completed:
        return 'Complété';
      case TrashStatus.cancelled:
        return 'Annulé';
    }
  }

  Color getStatusColor(TrashStatus status) {
    switch (status) {
      case TrashStatus.pending:
        return AppColors.warning;
      case TrashStatus.inTransit:
        return AppColors.primary;
      case TrashStatus.completed:
        return AppColors.success;
      case TrashStatus.cancelled:
        return AppColors.textSecondary;
    }
  }
}
