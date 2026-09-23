import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/pdf_export_service.dart';
import '../../core/utils/myco_calculations.dart';
import '../../data/models/batch_model.dart';
import '../providers/app_providers.dart';
import '../shared/myco_button.dart';
import 'qr_scanner_screen.dart';

class ProductionDashboardScreen extends ConsumerWidget {
  const ProductionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(batchesStreamProvider);
    final bags = ref.watch(bagsStreamProvider).value ?? [];
    final stats = ref.watch(productionStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Production & Suivi Mycologique'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.secondaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner, size: 28),
        label: const Text('Scanner Sac (1 tap)', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const QrScannerScreen()),
          );
        },
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bandeau Métriques Mycologiques
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'État du Parc Mycologique',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Sacs Totaux', '${stats['totalBags']}'),
                      _buildStat('En Incubation', '${stats['activeIncubation']}', color: Colors.blueGrey),
                      _buildStat('Fructification', '${stats['activeFruiting']}', color: Colors.green),
                      _buildStat(
                        'Contaminés',
                        '${stats['contaminated']} (${stats['contaminationRate'].toStringAsFixed(1)}%)',
                        color: Colors.red,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total récolté à ce jour :'),
                      Text(
                        MycoCalculations.formatWeight(stats['totalHarvestedKg'] as double? ?? 0.0),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.primaryGreen),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bouton Création d'un Nouveau Lot de Pasteurisation
          MycoButton(
            label: 'Nouveau Lot de Pasteurisation (Fût 200L)',
            icon: Icons.add_circle_outline,
            backgroundColor: AppConstants.primaryGreen,
            onPressed: () => _showCreateBatchDialog(context, ref),
          ),
          const SizedBox(height: 20),

          const Text(
            'Lots de Pasteurisation Récents :',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          batchesAsync.when(
            data: (batches) {
              if (batches.isEmpty) {
                return const Center(child: Text('Aucun lot de culture pour le moment.'));
              }
              return Column(
                children: batches.map((batch) {
                  final batchBags = bags.where((b) => b.batchId == batch.id).toList();
                  return _buildBatchCard(context, batch, batchBags);
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Erreur : $err'),
          ),
          const SizedBox(height: 80), // Marge pour le floatingActionButton
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBatchCard(BuildContext context, BatchModel batch, List<dynamic> bags) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  batch.batchCode,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    batch.status.label,
                    style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Souche : ${batch.spawnStrain} • Paille : ${batch.strawDryWeightKg} kg sec (${batch.strawWetWeightKg} kg humide)'),
            Text('Blanc ensemencé : ${batch.spawnWeightKg} kg (Ratio: ${batch.spawnRatioPercent}%)'),
            Text('Sacs générés : ${batch.totalBagsCreated} sacs'),
            const SizedBox(height: 12),

            // Actions sur le lot : Imprimer les étiquettes QR
            OutlinedButton.icon(
              icon: const Icon(Icons.print),
              label: const Text('Imprimer Planche QR Codes (PDF)'),
              onPressed: () {
                // Appel au service d'export PDF
                PdfExportService.printBatchQrLabels(
                  batch: batch,
                  bags: bags.cast(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateBatchDialog(BuildContext context, WidgetRef ref) {
    final codeCtrl = TextEditingController(text: 'LOT-${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-02');
    final strawDryCtrl = TextEditingController(text: '50.0');
    final strawWetCtrl = TextEditingController(text: '160.0');
    final spawnCtrl = TextEditingController(text: '7.0');
    final bagsCtrl = TextEditingController(text: '32');
    final strainCtrl = TextEditingController(text: 'Pleurote Gris HK35');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Nouveau Lot (Pasteurisation Fût 200L)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code du Lot')),
                TextField(controller: strainCtrl, decoration: const InputDecoration(labelText: 'Souche Mycélium')),
                TextField(controller: strawDryCtrl, decoration: const InputDecoration(labelText: 'Paille sèche (kg)'), keyboardType: TextInputType.number),
                TextField(controller: strawWetCtrl, decoration: const InputDecoration(labelText: 'Paille humide après essorage (kg)'), keyboardType: TextInputType.number),
                TextField(controller: spawnCtrl, decoration: const InputDecoration(labelText: 'Poids du blanc de grain (kg)'), keyboardType: TextInputType.number),
                TextField(controller: bagsCtrl, decoration: const InputDecoration(labelText: 'Nombre de sacs à générer'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryGreen, foregroundColor: Colors.white),
              onPressed: () async {
                final user = ref.read(authStateProvider).value;
                await ref.read(productionRepositoryProvider).createBatch(
                      batchCode: codeCtrl.text.trim(),
                      strawDryWeightKg: double.tryParse(strawDryCtrl.text) ?? 50.0,
                      strawWetWeightKg: double.tryParse(strawWetCtrl.text) ?? 160.0,
                      spawnStrain: strainCtrl.text.trim(),
                      spawnWeightKg: double.tryParse(spawnCtrl.text) ?? 7.0,
                      numberOfBags: int.tryParse(bagsCtrl.text) ?? 32,
                      createdBy: user?.displayName ?? 'Responsable Production',
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Créer et Générer QR'),
            ),
          ],
        );
      },
    );
  }
}
