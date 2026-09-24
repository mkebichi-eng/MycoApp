import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/call_service.dart';
import '../../core/utils/myco_calculations.dart';
import '../../data/models/client_model.dart';
import '../../data/models/deliverer_model.dart';
import '../providers/app_providers.dart';
import '../sales/sales_screen.dart';

class CarnetProScreen extends ConsumerStatefulWidget {
  final int initialTabIndex; // 0 for Clients, 1 for Deliverers
  const CarnetProScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<CarnetProScreen> createState() => _CarnetProScreenState();
}

class _CarnetProScreenState extends ConsumerState<CarnetProScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsStreamProvider);
    final deliverersAsync = ref.watch(deliverersStreamProvider);

    final clientsCount = clientsAsync.value?.length ?? 0;
    final deliverersCount = deliverersAsync.value?.length ?? 0;

    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        title: const Row(
          children: [
            Text('📖 ', style: TextStyle(fontSize: 20)),
            Text(
              'Carnet Pro',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: AppConstants.cardDark,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.accentGreen,
          indicatorWeight: 3,
          labelColor: AppConstants.accentGreen,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: '👥 Clients ($clientsCount)'),
            Tab(text: '🛵 Livreurs ($deliverersCount)'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            return Text(
              _tabController.index == 0 ? 'Nouveau Client' : 'Nouveau Livreur',
              style: const TextStyle(fontWeight: FontWeight.bold),
            );
          },
        ),
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddClientDialog(context);
          } else {
            _showAddDelivererDialog(context);
          }
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. ONGLET CLIENTS
          _buildClientsTab(context, clientsAsync),

          // 2. ONGLET LIVREURS
          _buildDeliverersTab(context, deliverersAsync),
        ],
      ),
    );
  }

  // ==========================================
  // ONGLET 1 : CLIENTS
  // ==========================================
  Widget _buildClientsTab(BuildContext context, AsyncValue<List<ClientModel>> clientsAsync) {
    return clientsAsync.when(
      data: (clients) {
        if (clients.isEmpty) {
          return const Center(
            child: Text(
              'Aucun client enregistré.\nAppuyez sur + Nouveau Client.',
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
            return _buildClientCard(context, client);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppConstants.primaryGreen)),
      error: (err, _) => Center(child: Text('Erreur : $err', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildClientCard(BuildContext context, ClientModel client) {
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
                child: Text(
                  client.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                tooltip: 'Modifier',
                onPressed: () => _showEditClientDialog(context, client),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppConstants.alertRed),
                tooltip: 'Supprimer',
                onPressed: () => _confirmDeleteClient(context, client),
              ),
            ],
          ),
          if (client.contactPerson.isNotEmpty)
            Text(
              'Contact : ${client.contactPerson}',
              style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
            ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConstants.backgroundDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppConstants.borderDark),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tarif négocié', style: TextStyle(color: Color(0xFF888888), fontSize: 10)),
                    Text(
                      '${client.presetPricePerKg.toStringAsFixed(0)} DA / kg',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.accentGreen,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Solde dû (Impayé)', style: TextStyle(color: Color(0xFF888888), fontSize: 10)),
                    Text(
                      client.totalDue > 0
                          ? '🔴 ${client.totalDue.toStringAsFixed(0)} DA'
                          : '✓ À jour',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: client.totalDue > 0 ? AppConstants.alertRed : AppConstants.accentGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Color(0xFF888888)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${client.address}, ${client.city}',
                  style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: AppConstants.borderDark),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.phone, size: 16, color: AppConstants.accentGreen),
                  label: Text(
                    client.phone,
                    style: const TextStyle(color: AppConstants.accentGreen, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppConstants.borderDark),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => CallService.makePhoneCall(client.phone),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart, size: 16),
                label: const Text('Vente', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const SalesScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ONGLET 2 : FLOTTE LIVREURS
  // ==========================================
  Widget _buildDeliverersTab(BuildContext context, AsyncValue<List<DelivererModel>> deliverersAsync) {
    return deliverersAsync.when(
      data: (deliverers) {
        if (deliverers.isEmpty) {
          return const Center(
            child: Text(
              'Aucun livreur dans votre flotte.\nAppuyez sur + Nouveau Livreur pour en ajouter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF888888), fontSize: 14),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: deliverers.length,
          itemBuilder: (context, index) {
            final deliverer = deliverers[index];
            return _buildDelivererCard(context, deliverer);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppConstants.primaryGreen)),
      error: (err, _) => Center(child: Text('Erreur : $err', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildDelivererCard(BuildContext context, DelivererModel deliverer) {
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
                child: Row(
                  children: [
                    Text(_getVehicleEmoji(deliverer.vehicle), style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        deliverer.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                tooltip: 'Modifier tarif & profil',
                onPressed: () => _showEditDelivererDialog(context, deliverer),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppConstants.alertRed),
                tooltip: 'Supprimer',
                onPressed: () => _confirmDeleteDeliverer(context, deliverer),
              ),
            ],
          ),
          Text(
            'Véhicule : ${deliverer.vehicle}',
            style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConstants.backgroundDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppConstants.borderDark),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tarif de course habituel', style: TextStyle(color: Color(0xFF888888), fontSize: 10)),
                    Row(
                      children: [
                        Text(
                          '${deliverer.defaultFee.toStringAsFixed(0)} DA',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.alertYellow,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('/ course', style: TextStyle(color: Color(0xFF888888), fontSize: 10)),
                      ],
                    ),
                    const Text('(Modifiable lors de chaque vente)', style: TextStyle(color: AppConstants.accentGreen, fontSize: 9)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppConstants.accentGreen.withOpacity(0.4)),
                  ),
                  child: const Text('✓ Actif', style: TextStyle(color: AppConstants.accentGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Color(0xFF888888)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Zone : ${deliverer.address}',
                  style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: AppConstants.borderDark),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.phone, size: 16, color: AppConstants.accentGreen),
                  label: Text(
                    'Appeler (${deliverer.phone})',
                    style: const TextStyle(color: AppConstants.accentGreen, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppConstants.borderDark),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => CallService.makePhoneCall(deliverer.phone),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.tune, size: 16, color: Colors.white70),
                label: const Text('Tarif', style: TextStyle(fontSize: 12, color: Colors.white70)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppConstants.borderDark),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showEditDelivererDialog(context, deliverer),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getVehicleEmoji(String vehicle) {
    final v = vehicle.toLowerCase();
    if (v.contains('kangoo') || v.contains('fourgon') || v.contains('utilitaire') || v.contains('voiture')) return '🚗';
    if (v.contains('scooter')) return '🛴';
    return '🛵';
  }

  // ==========================================
  // MODALES & ACTIONS (CLIENTS)
  // ==========================================
  void _showAddClientDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+213');
    final addressCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '1200.0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardDark,
        title: const Text('Nouveau Client', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Nom / Enseigne *'),
              ),
              TextField(
                controller: contactCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Personne de contact'),
              ),
              TextField(
                controller: phoneCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Téléphone *'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: addressCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Adresse'),
              ),
              TextField(
                controller: priceCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Prix au kilo négocié (DA/kg) *'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryGreen),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await ref.read(clientsRepositoryProvider).addClient(
                    name: nameCtrl.text.trim(),
                    contactPerson: contactCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : 'Alger',
                    city: 'Alger',
                    presetPricePerKg: double.tryParse(priceCtrl.text) ?? 1200.0,
                  );
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showEditClientDialog(BuildContext context, ClientModel client) {
    final priceCtrl = TextEditingController(text: client.presetPricePerKg.toString());
    final dueCtrl = TextEditingController(text: client.totalDue.toString());
    final phoneCtrl = TextEditingController(text: client.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardDark,
        title: Text('Modifier : ${client.name}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Tarif négocié (DA/kg)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: dueCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Solde d\'impayé / Dû (DA)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: phoneCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Téléphone'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryGreen),
            onPressed: () async {
              await ref.read(clientsRepositoryProvider).updateClient(
                    id: client.id,
                    presetPricePerKg: double.tryParse(priceCtrl.text),
                    totalDue: double.tryParse(dueCtrl.text),
                    phone: phoneCtrl.text.trim(),
                  );
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteClient(BuildContext context, ClientModel client) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardDark,
        title: const Text('Confirmer la suppression', style: TextStyle(color: Colors.white)),
        content: Text(
          'Supprimer définitivement le client "${client.name}" du Carnet Pro ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.alertRed),
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

  // ==========================================
  // MODALES & ACTIONS (LIVREURS)
  // ==========================================
  void _showAddDelivererDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+213');
    final addressCtrl = TextEditingController();
    final feeCtrl = TextEditingController(text: '350.0');
    String selectedVehicle = 'Moto rapide';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppConstants.cardDark,
          title: const Text('Nouveau Livreur', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Nom & Prénom *'),
                ),
                TextField(
                  controller: phoneCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Téléphone *'),
                  keyboardType: TextInputType.phone,
                ),
                DropdownButtonFormField<String>(
                  value: selectedVehicle,
                  dropdownColor: AppConstants.cardDark,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Véhicule'),
                  items: const [
                    DropdownMenuItem(value: 'Moto rapide', child: Text('🛵 Moto rapide')),
                    DropdownMenuItem(value: 'Scooter urbain', child: Text('🛴 Scooter urbain')),
                    DropdownMenuItem(value: 'Kangoo / Utilitaire', child: Text('🚗 Kangoo / Utilitaire')),
                    DropdownMenuItem(value: 'Voiture commerciale', child: Text('🚙 Voiture commerciale')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedVehicle = val);
                  },
                ),
                TextField(
                  controller: addressCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Zone de couverture / Adresse'),
                ),
                TextField(
                  controller: feeCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Tarif course de base (DA) *',
                    helperText: 'Modifiable sur chaque commande',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryGreen),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await ref.read(deliverersRepositoryProvider).addDeliverer(
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      vehicle: selectedVehicle,
                      address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : 'Alger',
                      defaultFee: double.tryParse(feeCtrl.text) ?? 350.0,
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDelivererDialog(BuildContext context, DelivererModel deliverer) {
    final nameCtrl = TextEditingController(text: deliverer.name);
    final phoneCtrl = TextEditingController(text: deliverer.phone);
    final addressCtrl = TextEditingController(text: deliverer.address);
    final feeCtrl = TextEditingController(text: deliverer.defaultFee.toString());
    String selectedVehicle = deliverer.vehicle;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppConstants.cardDark,
          title: Text('Modifier Livreur : ${deliverer.name}', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Nom & Prénom'),
                ),
                TextField(
                  controller: phoneCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: addressCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Zone de couverture'),
                ),
                TextField(
                  controller: feeCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Tarif course habituel (DA) *',
                    helperText: 'Tarif de référence pré-rempli sur les ventes',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryGreen),
              onPressed: () async {
                await ref.read(deliverersRepositoryProvider).updateDeliverer(
                      id: deliverer.id,
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      address: addressCtrl.text.trim(),
                      defaultFee: double.tryParse(feeCtrl.text),
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDeliverer(BuildContext context, DelivererModel deliverer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardDark,
        title: const Text('Supprimer le livreur', style: TextStyle(color: Colors.white)),
        content: Text(
          'Supprimer définitivement le livreur "${deliverer.name}" de votre flotte Carnet Pro ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.alertRed),
            onPressed: () async {
              await ref.read(deliverersRepositoryProvider).deleteDeliverer(deliverer.id);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
