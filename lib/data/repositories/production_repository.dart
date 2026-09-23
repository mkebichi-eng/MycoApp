import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/myco_calculations.dart';
import '../models/bag_model.dart';
import '../models/batch_model.dart';

class ProductionRepository {
  final FirebaseFirestore? _firestore;

  // Données locales initiales pour démonstration et tests immédiats
  final List<BatchModel> _localBatches = [];
  final List<BagModel> _localBags = [];
  final _batchesController = StreamController<List<BatchModel>>.broadcast();
  final _bagsController = StreamController<List<BagModel>>.broadcast();

  ProductionRepository({FirebaseFirestore? firestore}) : _firestore = firestore {
    _seedInitialData();
  }

  void _seedInitialData() {
    final now = DateTime.now();
    final batch1 = BatchModel(
      id: 'LOT-2026-09-01',
      batchCode: 'LOT-2026-09-01',
      pasteurizationDate: now.subtract(const Duration(days: 20)),
      strawDryWeightKg: 50.0,
      strawWetWeightKg: 160.0,
      spawnStrain: 'Pleurote Gris HK35',
      spawnWeightKg: 7.0,
      spawnRatioPercent: 4.37,
      totalBagsPlanned: 32,
      totalBagsCreated: 32,
      status: BatchStatus.fruiting,
      notes: 'Pasteurisation en fût 200L à 75°C pendant 90 min. Égouttage inox.',
      createdBy: 'Karim Responsable',
      createdAt: now.subtract(const Duration(days: 20)),
    );

    _localBatches.add(batch1);

    // Créer des sacs de démonstration pour ce lot
    for (int i = 1; i <= 32; i++) {
      final code = 'MYCO-BAG-${i.toString().padLeft(4, '0')}';
      BagStatus status = BagStatus.fruiting;
      ContaminationRecord contamination = ContaminationRecord();
      List<FlushHarvest> harvests = [];
      double harvested = 0.0;

      if (i == 4) {
        // Sac contaminé au Trichoderma
        status = BagStatus.contaminated;
        contamination = ContaminationRecord(
          isContaminated: true,
          detectedAt: now.subtract(const Duration(days: 5)),
          type: ContaminationType.trichoderma,
          declaredBy: 'Ouvrier Nabil',
          notes: 'Moisissure vert émeraude repérée en coin supérieur.',
        );
      } else if (i <= 10) {
        // Déjà une première vague de récoltée
        harvests.add(
          FlushHarvest(
            flushNumber: 1,
            date: now.subtract(const Duration(days: 2)),
            weightKg: 1.45,
            harvesterId: 'Ouvrier Nabil',
          ),
        );
        harvested = 1.45;
      }

      _localBags.add(
        BagModel(
          id: 'bag_$i',
          qrCode: code,
          batchId: batch1.id,
          batchCode: batch1.batchCode,
          strain: batch1.spawnStrain,
          weightKg: 5.0,
          roomLocation: i <= 16 ? 'Chambre Fruitière A' : 'Chambre Fruitière B',
          status: status,
          spawningDate: now.subtract(const Duration(days: 20)),
          incubationDays: 16,
          fruitingDate: now.subtract(const Duration(days: 4)),
          harvests: harvests,
          totalHarvestedKg: harvested,
          biologicalEfficiencyPercent: MycoCalculations.calculateBiologicalEfficiency(
            totalHarvestedKg: harvested,
            drySubstrateKg: 1.56, // paille sèche par sac
          ),
          contamination: contamination,
          updatedAt: now,
        ),
      );
    }

    _notifyListeners();
  }

  void _notifyListeners() {
    _batchesController.add(List.unmodifiable(_localBatches));
    _bagsController.add(List.unmodifiable(_localBags));
  }

  Stream<List<BatchModel>> getBatchesStream() {
    if (_firestore != null) {
      return _firestore
          .collection('batches')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => BatchModel.fromMap(doc.data(), doc.id))
              .toList());
    }
    return _batchesController.stream;
  }

  Stream<List<BagModel>> getBagsStream({String? batchId}) {
    if (_firestore != null) {
      Query query = _firestore.collection('bags');
      if (batchId != null) {
        query = query.where('batchId', isEqualTo: batchId);
      }
      return query.snapshots().map((snapshot) => snapshot.docs
          .map((doc) => BagModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList());
    }
    return _bagsController.stream.map((bags) {
      if (batchId == null) return bags;
      return bags.where((b) => b.batchId == batchId).toList();
    });
  }

  /// Recherche instantanée d'un sac via son code QR scanné
  Future<BagModel?> findBagByQrCode(String qrCode) async {
    final cleanQr = qrCode.trim();
    if (_firestore != null) {
      final snap = await _firestore
          .collection('bags')
          .where('qrCode', isEqualTo: cleanQr)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        return BagModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
      }
    }
    try {
      return _localBags.firstWhere((b) => b.qrCode == cleanQr);
    } catch (_) {
      return null;
    }
  }

  /// Création d'un nouveau lot de pasteurisation et génération automatique de ses sacs
  Future<BatchModel> createBatch({
    required String batchCode,
    required double strawDryWeightKg,
    required double strawWetWeightKg,
    required String spawnStrain,
    required double spawnWeightKg,
    required int numberOfBags,
    required String createdBy,
    String notes = '',
  }) async {
    final now = DateTime.now();
    final spawnRatio = MycoCalculations.calculateSpawnRatio(
      spawnWeightKg: spawnWeightKg,
      wetSubstrateKg: strawWetWeightKg,
    );

    final newBatch = BatchModel(
      id: 'LOT-${now.millisecondsSinceEpoch}',
      batchCode: batchCode,
      pasteurizationDate: now,
      strawDryWeightKg: strawDryWeightKg,
      strawWetWeightKg: strawWetWeightKg,
      spawnStrain: spawnStrain,
      spawnWeightKg: spawnWeightKg,
      spawnRatioPercent: spawnRatio,
      totalBagsPlanned: numberOfBags,
      totalBagsCreated: numberOfBags,
      status: BatchStatus.incubating,
      notes: notes,
      createdBy: createdBy,
      createdAt: now,
    );

    // Générer les sacs associés
    final List<BagModel> generatedBags = [];
    final bagWeight = strawWetWeightKg / (numberOfBags > 0 ? numberOfBags : 1);

    for (int i = 1; i <= numberOfBags; i++) {
      final qr = '${batchCode.replaceAll('-', '')}-${i.toString().padLeft(3, '0')}';
      final bag = BagModel(
        id: 'bag_${now.millisecondsSinceEpoch}_$i',
        qrCode: qr,
        batchId: newBatch.id,
        batchCode: newBatch.batchCode,
        strain: newBatch.spawnStrain,
        weightKg: double.parse(bagWeight.toStringAsFixed(1)),
        roomLocation: 'Salle Incubation 1',
        status: BagStatus.incubating,
        spawningDate: now,
        incubationDays: AppConstants.averageIncubationDays,
        updatedAt: now,
      );
      generatedBags.add(bag);
    }

    if (_firestore != null) {
      final batchRef = _firestore.collection('batches').doc(newBatch.id);
      await batchRef.set(newBatch.toMap());
      final writeBatch = _firestore.batch();
      for (final bag in generatedBags) {
        final bagRef = _firestore.collection('bags').doc(bag.id);
        writeBatch.set(bagRef, bag.toMap());
      }
      await writeBatch.commit();
    }

    _localBatches.insert(0, newBatch);
    _localBags.addAll(generatedBags);
    _notifyListeners();

    return newBatch;
  }

  /// Changement d'étape en 1 geste : Passage en fructification
  Future<void> moveToFruiting(String bagId, {String? newLocation}) async {
    final now = DateTime.now();
    if (_firestore != null) {
      await _firestore.collection('bags').doc(bagId).update({
        'status': BagStatus.fruiting.name,
        'fruitingDate': now.toIso8601String(),
        'roomLocation': newLocation ?? 'Chambre Fruitière',
        'updatedAt': now.toIso8601String(),
      });
    }

    final index = _localBags.indexWhere((b) => b.id == bagId);
    if (index != -1) {
      _localBags[index] = _localBags[index].copyWith(
        status: BagStatus.fruiting,
        fruitingDate: now,
        roomLocation: newLocation ?? 'Chambre Fruitière',
        updatedAt: now,
      );
      _notifyListeners();
    }
  }

  /// Déclaration instantanée de contamination et mise à l'écart
  Future<void> declareContamination({
    required String bagId,
    required ContaminationType type,
    required String declaredBy,
    String notes = '',
  }) async {
    final now = DateTime.now();
    final record = ContaminationRecord(
      isContaminated: true,
      detectedAt: now,
      type: type,
      declaredBy: declaredBy,
      notes: notes,
    );

    if (_firestore != null) {
      await _firestore.collection('bags').doc(bagId).update({
        'status': BagStatus.contaminated.name,
        'contamination': record.toMap(),
        'updatedAt': now.toIso8601String(),
      });
    }

    final index = _localBags.indexWhere((b) => b.id == bagId);
    if (index != -1) {
      _localBags[index] = _localBags[index].copyWith(
        status: BagStatus.contaminated,
        contamination: record,
        updatedAt: now,
      );
      _notifyListeners();
    }
  }

  /// Enregistrement de pesée d'une vague de récolte
  Future<void> recordHarvest({
    required String bagId,
    required int flushNumber,
    required double weightKg,
    required String harvesterName,
  }) async {
    final now = DateTime.now();
    final harvest = FlushHarvest(
      flushNumber: flushNumber,
      date: now,
      weightKg: weightKg,
      harvesterId: harvesterName,
    );

    final index = _localBags.indexWhere((b) => b.id == bagId);
    if (index != -1) {
      final current = _localBags[index];
      final updatedHarvests = List<FlushHarvest>.from(current.harvests)..add(harvest);
      final totalHarvested = updatedHarvests.fold(0.0, (acc, h) => acc + h.weightKg);

      final updatedBag = current.copyWith(
        harvests: updatedHarvests,
        totalHarvestedKg: totalHarvested,
        biologicalEfficiencyPercent: MycoCalculations.calculateBiologicalEfficiency(
          totalHarvestedKg: totalHarvested,
          drySubstrateKg: current.weightKg * 0.30, // approximation 30% sec
        ),
        updatedAt: now,
      );

      _localBags[index] = updatedBag;
      _notifyListeners();

      if (_firestore != null) {
        await _firestore.collection('bags').doc(bagId).update(updatedBag.toMap());
      }
    }
  }

  /// Statistiques globales de production
  Map<String, dynamic> getProductionStats() {
    final totalBags = _localBags.length;
    final activeIncubation =
        _localBags.where((b) => b.status == BagStatus.incubating).length;
    final activeFruiting =
        _localBags.where((b) => b.status == BagStatus.fruiting).length;
    final contaminated =
        _localBags.where((b) => b.status == BagStatus.contaminated).length;

    final contaminationRate = totalBags > 0
        ? (contaminated / totalBags) * 100.0
        : 0.0;

    final totalHarvestedKg =
        _localBags.fold(0.0, (acc, b) => acc + b.totalHarvestedKg);

    return {
      'totalBatches': _localBatches.length,
      'totalBags': totalBags,
      'activeIncubation': activeIncubation,
      'activeFruiting': activeFruiting,
      'contaminated': contaminated,
      'contaminationRate': contaminationRate,
      'totalHarvestedKg': totalHarvestedKg,
    };
  }
}
