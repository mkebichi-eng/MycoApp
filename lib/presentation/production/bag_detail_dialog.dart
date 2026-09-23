import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/myco_calculations.dart';
import '../../data/models/bag_model.dart';
import '../providers/app_providers.dart';
import '../shared/myco_button.dart';

class BagDetailDialog extends ConsumerStatefulWidget {
  final BagModel bag;

  const BagDetailDialog({super.key, required this.bag});

  @override
  ConsumerState<BagDetailDialog> createState() => _BagDetailDialogState();
}

class _BagDetailDialogState extends ConsumerState<BagDetailDialog> {
  late BagModel _bag;
  final _harvestWeightController = TextEditingController();
  int _selectedFlush = 1;

  @override
  void initState() {
    super.initState();
    _bag = widget.bag;
    _selectedFlush = _bag.harvests.length + 1;
  }

  @override
  void dispose() {
    _harvestWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête du sac
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _bag.qrCode,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('Lot : ${_bag.batchCode} • Souche : ${_bag.strain}'),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _bag.status.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _bag.status.label,
                    style: TextStyle(
                      color: _bag.status.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Métriques actuelles du sac
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric('Poids Sac', '${_bag.weightKg} kg'),
                _buildMetric('Total Récolté', MycoCalculations.formatWeight(_bag.totalHarvestedKg)),
                _buildMetric('Efficacité (BE)', MycoCalculations.formatPercent(_bag.biologicalEfficiencyPercent)),
              ],
            ),
            const SizedBox(height: 16),

            // Emplacement actuel
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.meeting_room, size: 20, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Text('Localisation : ${_bag.roomLocation}'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ACTIONS RAPIDES DE TERRAIN (1 GESTE)
            const Text(
              'Actions Terrain :',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            // 1. Passer en Fructification
            if (_bag.status == BagStatus.incubating) ...[
              MycoButton(
                label: 'Passer en Chambre Fruitière',
                icon: Icons.water_drop,
                backgroundColor: Colors.teal,
                onPressed: () async {
                  await ref.read(productionRepositoryProvider).moveToFruiting(_bag.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sac transféré en Fructification !')),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
            ],

            // 2. Enregistrer une pesée de récolte (Flush 1, 2, 3)
            if (_bag.status == BagStatus.fruiting) ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pesée de récolte (Vague $_selectedFlush) :',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _harvestWeightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Poids récolté (kg)',
                                hintText: 'ex: 1.25',
                                border: OutlineInputBorder(),
                                suffixText: 'kg',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Enregistrer'),
                            onPressed: () async {
                              final weight = double.tryParse(_harvestWeightController.text) ?? 0.0;
                              if (weight <= 0) return;
                              final user = ref.read(authStateProvider).value;
                              await ref.read(productionRepositoryProvider).recordHarvest(
                                    bagId: _bag.id,
                                    flushNumber: _selectedFlush,
                                    weightKg: weight,
                                    harvesterName: user?.displayName ?? 'Ouvrier',
                                  );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Vague $_selectedFlush enregistrée : $weight kg !')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // 3. Déclarer une contamination (Moisissure verte / trichoderma / etc.)
            if (_bag.status != BagStatus.contaminated && _bag.status != BagStatus.discarded) ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.warning_amber_rounded),
                label: const Text('Signaler une Contamination (Mettre à l\'écart)'),
                onPressed: () => _showContaminationChoice(context),
              ),
            ],

            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  void _showContaminationChoice(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Type de contamination observée :',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 16),
              ...ContaminationType.values.map((type) {
                return ListTile(
                  leading: const Icon(Icons.coronavirus, color: Colors.red),
                  title: Text(type.label),
                  onTap: () async {
                    final user = ref.read(authStateProvider).value;
                    await ref.read(productionRepositoryProvider).declareContamination(
                          bagId: _bag.id,
                          type: type,
                          declaredBy: user?.displayName ?? 'Ouvrier',
                        );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
