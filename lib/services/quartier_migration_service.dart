import 'package:cloud_firestore/cloud_firestore.dart';

/// Service pour migrer les quartiers existants vers minuscules
/// À exécuter UNE SEULE FOIS pour normaliser les données existantes
class QuartierMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Normalise tous les noms de quartiers dans la collection quartiers
  Future<void> normalizeQuartiersCollection() async {
    print('🔄 Migration des quartiers...');

    final snapshot = await _firestore.collection('quartiers').get();

    int updated = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final currentName = data['name'] as String;
      final normalizedName = currentName.toLowerCase();

      if (currentName != normalizedName) {
        await doc.reference.update({
          'name': normalizedName,
          'updatedAt': Timestamp.now(),
        });
        print('✅ Quartier mis à jour: "$currentName" → "$normalizedName"');
        updated++;
      }
    }

    print('✨ Migration terminée: $updated quartiers normalisés');
  }

  /// Normalise tous les quartiers des utilisateurs
  Future<void> normalizeUsersQuartier() async {
    print('🔄 Migration des quartiers des utilisateurs...');

    final snapshot = await _firestore.collection('users').get();

    int updated = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final currentQuartier = data['quartier'] as String?;

      if (currentQuartier != null) {
        final normalizedQuartier = currentQuartier.toLowerCase();

        if (currentQuartier != normalizedQuartier) {
          await doc.reference.update({
            'quartier': normalizedQuartier,
            'updatedAt': Timestamp.now(),
          });
          print('✅ Utilisateur ${data['name']}: "$currentQuartier" → "$normalizedQuartier"');
          updated++;
        }
      }
    }

    print('✨ Migration terminée: $updated utilisateurs mis à jour');
  }

  /// Normalise tous les quartiers des demandes de récupération
  Future<void> normalizeTrashReportsQuartier() async {
    print('🔄 Migration des quartiers des demandes...');

    final snapshot = await _firestore.collection('trash_reports').get();

    int updated = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final currentQuartier = data['quartier'] as String?;

      if (currentQuartier != null) {
        final normalizedQuartier = currentQuartier.toLowerCase();

        if (currentQuartier != normalizedQuartier) {
          await doc.reference.update({
            'quartier': normalizedQuartier,
            'updatedAt': Timestamp.now(),
          });
          print('✅ Demande ${doc.id}: "$currentQuartier" → "$normalizedQuartier"');
          updated++;
        }
      }
    }

    print('✨ Migration terminée: $updated demandes mises à jour');
  }

  /// Exécute la migration complète
  Future<void> runFullMigration() async {
    print('🚀 Début de la migration complète...\n');

    try {
      await normalizeQuartiersCollection();
      print('');

      await normalizeUsersQuartier();
      print('');

      await normalizeTrashReportsQuartier();
      print('');

      print('✅ Migration complète terminée avec succès!');
    } catch (e) {
      print('❌ Erreur lors de la migration: $e');
      rethrow;
    }
  }

  /// Recherche et affiche les quartiers en double (différence de casse)
  Future<void> findDuplicateQuartiers() async {
    print('🔍 Recherche de doublons...\n');

    final snapshot = await _firestore.collection('quartiers').get();

    final Map<String, List<String>> quartiersMap = {};

    for (final doc in snapshot.docs) {
      final name = doc.data()['name'] as String;
      final normalized = name.toLowerCase();

      if (!quartiersMap.containsKey(normalized)) {
        quartiersMap[normalized] = [];
      }
      quartiersMap[normalized]!.add(name);
    }

    final duplicates = quartiersMap.entries
        .where((entry) => entry.value.length > 1)
        .toList();

    if (duplicates.isEmpty) {
      print('✅ Aucun doublon trouvé');
    } else {
      print('⚠️ Doublons trouvés:');
      for (final entry in duplicates) {
        print('  ${entry.key}: ${entry.value.join(", ")}');
      }
      print('\n💡 Suggestion: Fusionnez ces quartiers manuellement avant la migration');
    }
  }
}
