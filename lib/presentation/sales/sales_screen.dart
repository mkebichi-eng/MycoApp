import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/pdf_export_service.dart';
import '../../core/utils/myco_calculations.dart';
import '../../data/models/client_model.dart';
import '../../data/models/deliverer_model.dart';
import '../../data/models/sale_model.dart';
import '../providers/app_providers.dart';
import '../shared/myco_button.dart';

enum SalesFilterMode { recent5, today, unpaid, all, date }

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  SalesFilterMode _filterMode = SalesFilterMode.recent5;
  DateTime? _selectedDate;

  List<SaleModel> _applyFilters(List<SaleModel> originalSales) {
    // 1. Tri par date décroissante (plus récentes en premier)
    final sorted = List<SaleModel>.from(originalSales)
      ..sort((a, b) => b.date.compareTo(a.date));

    var filtered = sorted;

    // 2. Filtrage selon le mode ou la date
    if (_filterMode == SalesFilterMode.date && _selectedDate != null) {
      filtered = filtered.where((s) =>
          s.date.year == _selectedDate!.year &&
          s.date.month == _selectedDate!.month &&
          s.date.day == _selectedDate!.day).toList();
    } else if (_filterMode == SalesFilterMode.today) {
      final now = DateTime.now();
      filtered = filtered.where((s) =>
          s.date.year == now.year &&
          s.date.month == now.month &&
          s.date.day == now.day).toList();
    } else if (_filterMode == SalesFilterMode.unpaid) {
      filtered = filtered.where((s) => s.paymentStatus != PaymentStatus.paid).toList();
    } else if (_filterMode == SalesFilterMode.recent5) {
      filtered = filtered.take(5).toList();
    }

    return filtered;
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Filtrer les ventes par date',
      confirmText: 'Filtrer',
      cancelText: 'Annuler',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _filterMode = SalesFilterMode.date;
      });
    }
  }

  void _navigateDate(int offsetDays) {
    final base = _selectedDate ?? (_filterMode == SalesFilterMode.today ? DateTime.now() : DateTime.now());
    final newDate = base.add(Duration(days: offsetDays));
    setState(() {
      _selectedDate = newDate;
      _filterMode = SalesFilterMode.date;
    });
  }

  String _getDateDisplay() {
    if (_selectedDate == null) {
      if (_filterMode == SalesFilterMode.today) return 'Aujourd\'hui';
      return 'Date';
    }
    final now = DateTime.now();
    if (_selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day) {
      return 'Aujourd\'hui';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (_selectedDate!.year == yesterday.year &&
        _selectedDate!.month == yesterday.month &&
        _selectedDate!.day == yesterday.day) {
      return 'Hier';
    }
    return '${_selectedDate!.day}/${_selectedDate!.month}';
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
      _filterMode = SalesFilterMode.recent5;
    });
  }

  @override
  Widget build(BuildContext context) {
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

          // Barre de filtres ultra-compacte (1 seule ligne avec scroll rapide + sélecteur calendrier)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: '⏱️ 5 Dernières',
                            mode: SalesFilterMode.recent5,
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            label: '📅 Aujourd\'hui',
                            mode: SalesFilterMode.today,
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            label: '🔴 Impayés',
                            mode: SalesFilterMode.unpaid,
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            label: '📜 Tout',
                            mode: SalesFilterMode.all,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Sélecteur de date ergonomique jour par jour (◀ Date ▶ ✕)
                  Container(
                    decoration: BoxDecoration(
                      color: _selectedDate != null
                          ? AppConstants.primaryGreen.withOpacity(0.12)
                          : Colors.grey.shade100,
                      border: Border.all(
                        color: _selectedDate != null
                            ? AppConstants.primaryGreen
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _navigateDate(-1),
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 7),
                            child: Icon(Icons.chevron_left, size: 18, color: AppConstants.primaryGreen),
                          ),
                        ),
                        InkWell(
                          onTap: () => _pickDate(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_month, size: 15, color: AppConstants.primaryGreen),
                                const SizedBox(width: 3),
                                Text(
                                  _getDateDisplay(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: _selectedDate != null ? FontWeight.bold : FontWeight.w600,
                                    color: _selectedDate != null ? AppConstants.primaryGreen : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _navigateDate(1),
                          borderRadius: BorderRadius.horizontal(
                            right: _selectedDate == null ? const Radius.circular(9) : Radius.zero,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 7),
                            child: Icon(Icons.chevron_right, size: 18, color: AppConstants.primaryGreen),
                          ),
                        ),
                        if (_selectedDate != null) ...[
                          InkWell(
                            onTap: _clearDateFilter,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
                            child: const Padding(
                              padding: EdgeInsets.only(right: 6, left: 2, top: 7, bottom: 7),
                              child: Icon(Icons.close, size: 14, color: Colors.red),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // En-tête de section avec statut du filtre actif
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _filterMode == SalesFilterMode.recent5
                    ? '5 Dernières Ventes :'
                    : (_filterMode == SalesFilterMode.date && _selectedDate != null
                        ? 'Ventes du ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} :'
                        : (_filterMode == SalesFilterMode.today
                            ? 'Ventes d\'Aujourd\'hui :'
                            : (_filterMode == SalesFilterMode.unpaid
                                ? 'Ventes avec impayés :'
                                : 'Historique Complet des Ventes :'))),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),

          salesAsync.when(
            data: (allSales) {
              if (allSales.isEmpty) {
                return const Center(child: Text('Aucune vente enregistrée.'));
              }

              final displayedSales = _applyFilters(allSales);

              if (displayedSales.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text(
                        'Aucune vente trouvée pour ce filtre.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedDate = null;
                            _filterMode = SalesFilterMode.recent5;
                          });
                        },
                        child: const Text('Réinitialiser aux 5 dernières'),
                      ),
                    ],
                  ),
                );
              }

              final bool hasMoreThan5 = allSales.length > 5;
              final bool isLimitedTo5 = _filterMode == SalesFilterMode.recent5 && hasMoreThan5;

              return Column(
                children: [
                  ...displayedSales.map((sale) => _buildSaleCard(sale)),
                  
                  // Ergonomie : Bouton pour déplier l'historique complet
                  if (isLimitedTo5) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.history, color: AppConstants.primaryGreen),
                        label: Text(
                          'Afficher les ${allSales.length - 5} ventes plus anciennes ↓',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryGreen),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppConstants.primaryGreen),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          setState(() => _filterMode = SalesFilterMode.all);
                        },
                      ),
                    ),
                  ],

                  if (_filterMode == SalesFilterMode.all && hasMoreThan5) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.keyboard_arrow_up),
                      label: const Text('Réduire aux 5 dernières ventes'),
                      onPressed: () {
                        setState(() => _filterMode = SalesFilterMode.recent5);
                      },
                    ),
                  ],
                ],
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

  Widget _buildFilterChip({required String label, required SalesFilterMode mode}) {
    final isSelected = _filterMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppConstants.primaryGreen.withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppConstants.primaryGreen : Colors.black87,
      ),
      onSelected: (_) {
        setState(() {
          _filterMode = mode;
          if (mode != SalesFilterMode.date) {
            _selectedDate = null;
          }
        });
      },
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
                  '${sale.date.day.toString().padLeft(2, '0')}/${sale.date.month.toString().padLeft(2, '0')}/${sale.date.year}',
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
    final deliverers = ref.read(deliverersStreamProvider).value ?? [];
    ClientModel? selectedClient = clients.isNotEmpty ? clients.first : null;
    DelivererModel? selectedDeliverer = deliverers.isNotEmpty ? deliverers.first : null;

    final qtyCtrl = TextEditingController(text: '5.0');
    final priceCtrl = TextEditingController(
      text: selectedClient != null ? selectedClient.presetPricePerKg.toString() : '1200.0',
    );
    final deliveryFeeCtrl = TextEditingController(
      text: selectedDeliverer != null ? selectedDeliverer.defaultFee.toString() : '350.0',
    );
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
                    if (deliverers.isNotEmpty)
                      DropdownButtonFormField<DelivererModel>(
                        value: selectedDeliverer,
                        decoration: const InputDecoration(labelText: 'Livreur assigné'),
                        items: deliverers.map((d) {
                          return DropdownMenuItem(
                            value: d,
                            child: Text('${d.name} (${d.vehicle})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() {
                              selectedDeliverer = val;
                              deliveryFeeCtrl.text = val.defaultFee.toString();
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
                      decoration: const InputDecoration(
                        labelText: 'Tarif course livreur (DA) *',
                        helperText: 'Modifiable librement pour cette commande',
                      ),
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
