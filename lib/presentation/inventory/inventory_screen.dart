import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/models/inventory_movement_model.dart';
import '../providers/app_providers.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(inventoryItemsStreamProvider);
    final alerts = ref.watch(lowStockAlertsProvider);
    final movementsAsync = ref.watch(inventoryMovementsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Stocks & Intrants'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bandeau d'alerte si articles sous-seuil
          if (alerts.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade300, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Alerte : ${alerts.length} article(s) sous le seuil critique !',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...alerts.map((item) => Text(
                        '• ${item.name} : reste ${item.currentStock} ${item.unit} (Seuil : ${item.alertThreshold} ${item.unit})',
                        style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w600),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          const Text(
            'Catalogue des Matières Premières & Consommables :',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          itemsAsync.when(
            data: (items) {
              return Column(
                children: items.map((item) => _buildItemCard(context, ref, item)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Erreur : $err'),
          ),

          const SizedBox(height: 24),
          const Text(
            'Derniers Mouvements Traçables :',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          movementsAsync.when(
            data: (movements) {
              return Column(
                children: movements.map((m) => _buildMovementTile(m)).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => Text('Erreur : $err'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, WidgetRef ref, InventoryItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: item.isLowStock
            ? const BorderSide(color: Colors.red, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text('Seuil critique : ${item.alertThreshold} ${item.unit}'),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.currentStock} ${item.unit}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: item.isLowStock ? Colors.red : AppConstants.primaryGreen,
                      ),
                    ),
                    if (item.isLowStock)
                      const Text(
                        'RÉAPPROVISIONNER',
                        style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Entrée Stock'),
                  onPressed: () => _showMovementDialog(context, ref, item, MovementType.stockIn),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.remove, size: 16),
                  label: const Text('Sortie (Usage)'),
                  onPressed: () => _showMovementDialog(context, ref, item, MovementType.stockOut),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementTile(InventoryMovementModel m) {
    final isOut = m.type == MovementType.stockOut;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOut ? Colors.orange.shade100 : Colors.green.shade100,
          child: Icon(
            isOut ? Icons.arrow_upward : Icons.arrow_downward,
            color: isOut ? Colors.deepOrange : Colors.green,
          ),
        ),
        title: Text('${m.itemName} (${isOut ? '-' : '+'}${m.quantity})'),
        subtitle: Text('${m.reason} • Par ${m.performedBy}'),
        trailing: Text(
          '${m.timestamp.day}/${m.timestamp.month} ${m.timestamp.hour}h${m.timestamp.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ),
    );
  }

  void _showMovementDialog(BuildContext context, WidgetRef ref, InventoryItemModel item, MovementType type) {
    final qtyCtrl = TextEditingController();
    final reasonCtrl = TextEditingController(
      text: type == MovementType.stockIn ? 'Achat fournisseur' : 'Utilisation pasteurisation / culture',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('${type.label} : ${item.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantité (${item.unit})',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Motif / Justification',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final qty = double.tryParse(qtyCtrl.text) ?? 0.0;
                if (qty <= 0) return;
                final user = ref.read(authStateProvider).value;
                await ref.read(inventoryRepositoryProvider).recordMovement(
                      itemId: item.id,
                      type: type,
                      quantity: qty,
                      reason: reasonCtrl.text.trim(),
                      performedBy: user?.displayName ?? 'Responsable',
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Valider Mouvement'),
            ),
          ],
        );
      },
    );
  }
}
