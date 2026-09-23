import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/call_service.dart';
import '../../core/utils/myco_calculations.dart';
import '../../data/models/delivery_model.dart';
import '../providers/app_providers.dart';

class DeliveryPersonScreen extends ConsumerWidget {
  const DeliveryPersonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveriesAsync = ref.watch(myDeliveriesStreamProvider);

    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🚚 ', style: TextStyle(fontSize: 20)),
            Text(
              'Mes livraisons',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppConstants.alertRed),
            tooltip: 'Se déconnecter',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: deliveriesAsync.when(
        data: (deliveries) {
          if (deliveries.isEmpty) {
            return const Center(
              child: Text(
                'Aucune livraison assignée pour le moment.',
                style: TextStyle(color: Color(0xFF888888)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final delivery = deliveries[index];
              return _buildDeliveryCard(context, ref, delivery);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppConstants.accentGreen),
        ),
        error: (err, stack) => Center(
          child: Text('Erreur: $err', style: const TextStyle(color: AppConstants.alertRed)),
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(BuildContext context, WidgetRef ref, DeliveryModel delivery) {
    final isDelivered = delivery.status == DeliveryStatus.delivered;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDelivered ? AppConstants.primaryGreen : AppConstants.borderDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statut badge style MyDeliveriesScreen
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                delivery.deliveryNumber,
                style: const TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDelivered ? const Color(0xFF1F3A1F) : const Color(0xFF3A2E1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDelivered ? AppConstants.accentGreen : AppConstants.alertYellow,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isDelivered ? '✅ Confirmée / Livrée' : '⏳ En attente de confirmation',
                  style: TextStyle(
                    color: isDelivered ? AppConstants.accentGreen : AppConstants.alertYellow,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Client & Quantité
          Text(
            delivery.clientName,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '🍄 ${delivery.quantityKg} kg de pleurotes frais',
            style: const TextStyle(color: AppConstants.accentGreen, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          // Adresse
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📍 ', style: TextStyle(fontSize: 13)),
              Expanded(
                child: Text(
                  delivery.clientAddress,
                  style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Forfait course
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF122012),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tarif course livreur :', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                Text(
                  '${delivery.deliveryFee.toStringAsFixed(0)} DA',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Actions Terrain
          if (!isDelivered) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Appeler', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => CallService.makePhoneCall(delivery.clientPhone),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFAAAAAA),
                      side: const BorderSide(color: AppConstants.borderDark),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Itinéraire'),
                    onPressed: () => CallService.openMapNavigation(delivery.clientAddress),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF223822),
                  foregroundColor: AppConstants.accentGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppConstants.accentGreen, width: 0.8),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirmer la livraison', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await ref.read(deliveriesRepositoryProvider).updateDeliveryStatus(
                        deliveryId: delivery.id,
                        status: DeliveryStatus.delivered,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Livraison confirmée avec succès !'),
                        backgroundColor: AppConstants.primaryGreen,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
