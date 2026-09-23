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
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        title: const Text('Stocks & Intrants', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.cardDark,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_box),
        label: const Text('Nouvel Article', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddItemDialog(context, ref),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bandeau d'alerte si articles sous-seuil
          if (alerts.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1A1A),
                border: Border.all(color: const Color(0xFF5A2A2A), width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppConstants.alertRed),
                      const SizedBox(width: 8),
                      Text(
                        'Alerte : ${alerts.length} article(s) sous le seuil critique !',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.alertRed, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...alerts.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• ${item.name} : reste ${item.currentStock} ${item.unit} (Seuil : ${item.alertThreshold} ${item.unit})',
                          style: const TextStyle(color: Color(0xFFFFAAAA), fontSize: 12),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          const Text(
            'Catalogue Matières Premières & Consommables :',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppConstants.accentGreen),
          ),
          const SizedBox(height: 10),

          itemsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Aucun article en stock.', style: TextStyle(color: Color(0xFF888888))),
                  ),
                );
              }
              return Column(
                children: items.map((item) => _buildItemCard(context, ref, item)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppConstants.primaryGreen)),
            error: (err, stack) => Text('Erreur : $err', style: const TextStyle(color: Colors.red)),
          ),

          const SizedBox(height: 24),
          const Text(
            'Derniers Mouvements Traçables :',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppConstants.accentGreen),
          ),
          const SizedBox(height: 10),

          movementsAsync.when(
            data: (movements) {
              return Column(
                children: movements.map((m) => _buildMovementTile(m)).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => Text('Erreur : $err', style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, WidgetRef ref, InventoryItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isLowStock ? const Color(0xFF5A2A2A) : AppConstants.borderDark,
          width: item.isLowStock ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Seuil critique : ${item.alertThreshold} ${item.unit} • ${item.unitCost.toStringAsFixed(0)} DA / ${item.unit}',
                      style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.currentStock} ${item.unit}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: item.isLowStock ? AppConstants.alertRed : AppConstants.accentGreen,
                        ),
                      ),
                      if (item.isLowStock)
                        const Text(
                          'RÉAPPROVISIONNER',
                          style: TextStyle(fontSize: 9, color: AppConstants.alertRed, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFF888888), size: 18),
                    tooltip: 'Supprimer article',
                    onPressed: () => _confirmDeleteItem(context, ref, item),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20, color: AppConstants.borderDark),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.accentGreen,
                  side: const BorderSide(color: AppConstants.accentGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Entrée (Réappro)'),
                onPressed: () => _showMovementDialog(context, ref, item, MovementType.stockIn),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A1A1A),
                  foregroundColor: AppConstants.alertRed,
                  side: const BorderSide(color: Color(0xFF5A2A2A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.remove, size: 16),
                label: const Text('Sortie (Usage)'),
                onPressed: () => _showMovementDialog(context, ref, item, MovementType.stockOut),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMovementTile(InventoryMovementModel m) {
    final isOut = m.type == MovementType.stockOut;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderDark),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isOut ? const Color(0xFF3A1A1A) : const Color(0xFF1F3A1F),
            child: Icon(
              isOut ? Icons.arrow_upward : Icons.arrow_downward,
              color: isOut ? AppConstants.alertRed : AppConstants.accentGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${m.itemName} (${isOut ? '-' : '+'}${m.quantity})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
                Text(
                  '${m.reason} • ${m.performedBy}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
          Text(
            '${m.timestamp.day}/${m.timestamp.month} ${m.timestamp.hour}h${m.timestamp.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '10');
    final unitCtrl = TextEditingController(text: 'kg');
    final thresholdCtrl = TextEditingController(text: '5');
    final costCtrl = TextEditingController(text: '500');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppConstants.borderDark),
        ),
        title: const Text('Ajouter un Article au Stock', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDarkInput(controller: nameCtrl, label: 'Nom de l\'article (ex: Chaux vive)'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildDarkInput(controller: qtyCtrl, label: 'Quantité init.', keyboard: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDarkInput(controller: unitCtrl, label: 'Unité (kg, L, unités)')),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildDarkInput(controller: thresholdCtrl, label: 'Seuil d\'alerte', keyboard: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDarkInput(controller: costCtrl, label: 'Coût unitaire DA', keyboard: TextInputType.number)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler', style: TextStyle(color: Color(0xFF888888))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final qty = double.tryParse(qtyCtrl.text) ?? 0.0;
              final threshold = double.tryParse(thresholdCtrl.text) ?? 5.0;
              final cost = double.tryParse(costCtrl.text) ?? 0.0;

              final newItem = InventoryItemModel(
                id: 'item_${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                category: 'raw_material',
                currentStock: qty,
                unit: unitCtrl.text.trim().isEmpty ? 'kg' : unitCtrl.text.trim(),
                alertThreshold: threshold,
                unitCost: cost,
                updatedAt: DateTime.now(),
              );

              await ref.read(inventoryRepositoryProvider).addItem(newItem);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Enregistrer Article'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteItem(BuildContext context, WidgetRef ref, InventoryItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF5A2A2A)),
        ),
        title: const Text('Supprimer cet article ?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Voulez-vous supprimer "${item.name}" du stock ?',
          style: const TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler', style: TextStyle(color: Color(0xFF888888))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.alertRed, foregroundColor: Colors.white),
            onPressed: () async {
              await ref.read(inventoryRepositoryProvider).deleteItem(item.id);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
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
          backgroundColor: AppConstants.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppConstants.borderDark),
          ),
          title: Text('${type.label} : ${item.name}', style: const TextStyle(color: Colors.white, fontSize: 15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDarkInput(controller: qtyCtrl, label: 'Quantité (${item.unit})', keyboard: TextInputType.number),
              const SizedBox(height: 12),
              _buildDarkInput(controller: reasonCtrl, label: 'Motif / Justification'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF888888))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildDarkInput({
    required TextEditingController controller,
    required String label,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 12),
        filled: true,
        fillColor: AppConstants.backgroundDark,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppConstants.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppConstants.accentGreen),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
