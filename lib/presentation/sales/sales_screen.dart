import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/pdf_export_service.dart';
import '../../core/utils/myco_calculations.dart';
import '../../data/models/client_model.dart';
import '../../data/models/sale_model.dart';
import '../providers/app_providers.dart';
import '../shared/myco_button.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesStreamProvider);
    final metrics = ref.watch(financialMetricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventes & Marges Nettes'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exporter Rapport Ventes (PDF)',
            onPressed: () {
              final sales = salesAsync.value ?? [];
              if (sales.isNotEmpty) {
                PdfExportService.printSalesReport(
                  sales: sales,
                  startDate: DateTime.now().subtract(const Duration(days: 30)),
                  endDate: DateTime.now(),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nouvelle Vente'),
        onPressed: () => _showNewSaleDialog(context, ref),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Synthèse financière immédiate
          Card(
            color: Colors.green.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chiffre d\'Affaires Total :',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        MycoCalculations.formatCurrency(metrics['totalRevenue'] as double? ?? 0.0),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Marge Nette Réalisée :',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      Text(
                        MycoCalculations.formatCurrency(metrics['totalNetMargin'] as double? ?? 0.0),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniKPI('Volume Vendu', MycoCalculations.formatWeight(metrics['totalKgSold'] as double? ?? 0.0)),
                      _buildMiniKPI('Taux de Marge', MycoCalculations.formatPercent(metrics['marginRate'] as double? ?? 0.0)),
                      _buildMiniKPI('Frais Livraison', MycoCalculations.formatCurrency(metrics['totalDeliveryFees'] as double? ?? 0.0)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Historique des Ventes Journalières :',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          salesAsync.when(
            data: (sales) {
              if (sales.isEmpty) {
                return const Center(child: Text('Aucune vente enregistrée.'));
              }
              return Column(
                children: sales.map((sale) => _buildSaleCard(sale)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Erreur : $err'),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMiniKPI(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSaleCard(SaleModel sale) {
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
                  sale.saleNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${sale.date.day}/${sale.date.month}/${sale.date.year}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              sale.clientName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('Quantité : ${sale.quantityKg} kg à ${sale.pricePerKg} DA/kg'),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total : ${MycoCalculations.formatCurrency(sale.totalRevenue)}'),
                    Text(
                      'Frais course : -${MycoCalculations.formatCurrency(sale.deliveryFee)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Marge : +${MycoCalculations.formatCurrency(sale.netMargin)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNewSaleDialog(BuildContext context, WidgetRef ref) {
    final clients = ref.read(clientsStreamProvider).value ?? [];
    ClientModel? selectedClient = clients.isNotEmpty ? clients.first : null;
    final qtyCtrl = TextEditingController(text: '5.0');
    final priceCtrl = TextEditingController(
      text: selectedClient != null ? selectedClient.presetPricePerKg.toString() : '1200.0',
    );
    final deliveryFeeCtrl = TextEditingController(text: '350.0');
    final costCtrl = TextEditingController(text: '1250.0'); // ~250 DA/kg coût intrants estimé

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final qty = double.tryParse(qtyCtrl.text) ?? 0.0;
            final price = double.tryParse(priceCtrl.text) ?? 0.0;
            final fee = double.tryParse(deliveryFeeCtrl.text) ?? 0.0;
            final cost = double.tryParse(costCtrl.text) ?? 0.0;
            final rev = qty * price;
            final margin = rev - fee - cost;

            return AlertDialog(
              title: const Text('Enregistrer une Vente & Marge'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (clients.isNotEmpty)
                      DropdownButtonFormField<ClientModel>(
                        value: selectedClient,
                        decoration: const InputDecoration(labelText: 'Client'),
                        items: clients.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c.name));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() {
                              selectedClient = val;
                              priceCtrl.text = val.presetPricePerKg.toString();
                            });
                          }
                        },
                      ),
                    TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantité livrée (kg)'),
                      onChanged: (_) => setStateDialog(() {}),
                    ),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Prix au kilo (DA/kg)'),
                      onChanged: (_) => setStateDialog(() {}),
                    ),
                    TextField(
                      controller: deliveryFeeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tarif Livreur assigné (DA)'),
                      onChanged: (_) => setStateDialog(() {}),
                    ),
                    TextField(
                      controller: costCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Coûts de revient alloués (DA)'),
                      onChanged: (_) => setStateDialog(() {}),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text('Chiffre d\'Affaires : ${MycoCalculations.formatCurrency(rev)}'),
                          Text(
                            'Marge Nette Calculée : ${MycoCalculations.formatCurrency(margin)}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (selectedClient == null) return;
                    final user = ref.read(authStateProvider).value;
                    await ref.read(salesRepositoryProvider).recordSale(
                          clientId: selectedClient!.id,
                          clientName: selectedClient!.name,
                          quantityKg: qty,
                          pricePerKg: price,
                          deliveryFee: fee,
                          allocatedProductionCost: cost,
                          createdBy: user?.displayName ?? 'Admin',
                        );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text('Enregistrer Vente'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
