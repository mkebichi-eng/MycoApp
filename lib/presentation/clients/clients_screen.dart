import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/call_service.dart';
import '../../core/utils/myco_calculations.dart';
import '../../data/models/client_model.dart';
import '../providers/app_providers.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsStreamProvider);

    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        title: const Text('Répertoire & Tarifs Clients', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.cardDark,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Nouveau Client', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddClientDialog(context, ref),
      ),
      body: clientsAsync.when(
        data: (clients) {
          if (clients.isEmpty) {
            return const Center(
              child: Text(
                'Aucun client enregistré.\nAppuyez sur + Nouveau Client pour commencer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF888888), fontSize: 14),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              return _buildClientCard(context, ref, client);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppConstants.primaryGreen)),
        error: (err, _) => Center(child: Text('Erreur : $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, WidgetRef ref, ClientModel client) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (client.contactPerson.isNotEmpty)
                      Text(
                        'Contact : ${client.contactPerson}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppConstants.alertRed, size: 20),
                tooltip: 'Supprimer',
                onPressed: () => _confirmDeleteClient(context, ref, client),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.backgroundDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppConstants.borderDark),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Prix négocié :', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                Text(
                  '${MycoCalculations.formatCurrency(client.presetPricePerKg)} / kg',
                  style: const TextStyle(
                    color: AppConstants.accentGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF888888)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${client.address}, ${client.city}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppConstants.borderDark),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => CallService.callClient(client.phone),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: AppConstants.accentGreen),
                      const SizedBox(width: 6),
                      Text(
                        client.phone,
                        style: const TextStyle(
                          color: AppConstants.accentGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: AppConstants.accentGreen),
                  SizedBox(width: 4),
                  Text('Actif', style: TextStyle(color: AppConstants.accentGreen, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddClientDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+213');
    final addrCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'Alger');
    final priceCtrl = TextEditingController(text: '1200');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppConstants.borderDark),
        ),
        title: const Text('Ajouter un Nouveau Client', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDarkInput(controller: nameCtrl, label: 'Nom du commerce / Enseigne'),
              const SizedBox(height: 10),
              _buildDarkInput(controller: contactCtrl, label: 'Nom du contact (ex: Chef Karim)'),
              const SizedBox(height: 10),
              _buildDarkInput(controller: phoneCtrl, label: 'Téléphone (+213...)', keyboard: TextInputType.phone),
              const SizedBox(height: 10),
              _buildDarkInput(controller: addrCtrl, label: 'Adresse'),
              const SizedBox(height: 10),
              _buildDarkInput(controller: cityCtrl, label: 'Ville (ex: Alger, Blida...)'),
              const SizedBox(height: 10),
              _buildDarkInput(controller: priceCtrl, label: 'Prix négocié (DA / kg)', keyboard: TextInputType.number),
              const SizedBox(height: 10),
              _buildDarkInput(controller: notesCtrl, label: 'Notes (ex: livrer avant 11h)'),
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
              final price = double.tryParse(priceCtrl.text) ?? 1200.0;
              final newClient = ClientModel(
                id: 'client_${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                contactPerson: contactCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                address: addrCtrl.text.trim(),
                city: cityCtrl.text.trim(),
                presetPricePerKg: price,
                notes: notesCtrl.text.trim(),
                createdAt: DateTime.now(),
              );

              await ref.read(clientsRepositoryProvider).addClient(newClient);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Enregistrer Client'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteClient(BuildContext context, WidgetRef ref, ClientModel client) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF5A2A2A)),
        ),
        title: const Text('Supprimer ce client ?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Voulez-vous vraiment retirer "${client.name}" de votre liste ?',
          style: const TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler', style: TextStyle(color: Color(0xFF888888))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.alertRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await ref.read(clientsRepositoryProvider).deleteClient(client.id);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
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
