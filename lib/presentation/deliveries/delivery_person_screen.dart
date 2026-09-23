import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/call_service.dart';
import '../../core/utils/myco_calculations.dart';
import '../../data/models/delivery_model.dart';
import '../providers/app_providers.dart';
import '../shared/myco_button.dart';

class DeliveryPersonScreen extends ConsumerWidget {
  const DeliveryPersonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveriesAsync = ref.watch(myDeliveriesStreamProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Livraisons du Jour'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: deliveriesAsync.when(
        data: (deliveries) {
          if (deliveries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune livraison en attente pour aujourd\'hui !',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          final pending = deliveries.where((d) => d.status != DeliveryStatus.delivered).toList();
          final delivered = deliveries.where((d) => d.status == DeliveryStatus.delivered).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Bandeau résumé livreur
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Livreur',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text('${pending.length} course(s) restante(s) • ${delivered.length} effectuée(s)'),
                        ],
                      ),
                      const Icon(Icons.delivery_dining, size: 36, color: Colors.deepOrange),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (pending.isNotEmpty) ...[
                const Text(
                  'Courses à livrer en priorité',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...pending.map((d) => _buildDeliveryCard(context, ref, d)),
              ],

              if (delivered.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Livraisons terminées aujourd\'hui',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ...delivered.map((d) => _buildDeliveryCard(context, ref, d)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildDeliveryCard(BuildContext context, WidgetRef ref, DeliveryModel delivery) {
    final isDelivered = delivery.status == DeliveryStatus.delivered;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isDelivered ? 1 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDelivered
            ? BorderSide(color: Colors.green.shade300, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Numéro de course et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  delivery.deliveryNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: delivery.status.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    delivery.status.label,
                    style: TextStyle(
                      color: delivery.status.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Nom du client & quantité
            Text(
              delivery.clientName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.scale, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text(
                  'Quantité à remettre : ${MycoCalculations.formatWeight(delivery.quantityKg)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Adresse
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.redAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    delivery.clientAddress,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),

            if (delivery.deliveryNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        delivery.deliveryNotes,
                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Actions d'intervention terrain (Gros boutons)
            if (!isDelivered) ...[
              Row(
                children: [
                  // Gros bouton vert : Appeler le client
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.phone),
                      label: const Text('Appeler', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      onPressed: () => CallService.makePhoneCall(delivery.clientPhone),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Bouton Itinéraire GPS
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.navigation),
                      label: const Text('Itinéraire', style: TextStyle(fontSize: 15)),
                      onPressed: () => CallService.openMapNavigation(delivery.clientAddress),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Gros bouton de validation de livraison en 1 tap
              MycoButton(
                label: 'Marquer comme Livré',
                icon: Icons.check_circle,
                backgroundColor: AppConstants.primaryGreen,
                onPressed: () async {
                  await ref.read(deliveriesRepositoryProvider).updateDeliveryStatus(
                        deliveryId: delivery.id,
                        status: DeliveryStatus.delivered,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Livraison ${delivery.deliveryNumber} validée avec succès !'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
