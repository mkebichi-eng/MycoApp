import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/myco_calculations.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/models/inventory_movement_model.dart';
import '../providers/app_providers.dart';

enum ExpenseFilterMode { recent5, today, month, stock, operational, all, date }

class InventoryScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const InventoryScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ExpenseFilterMode _expenseFilterMode = ExpenseFilterMode.recent5;
  DateTime? _expenseSelectedDate;

  final List<String> _customUnits = ['kg', 'unités', 'Litres', 'g', 'bottes', 'rouleaux', 'sacs', 'cartons'];
  final List<String> _customCategories = [
    'Matière première (Paille/Blanc)',
    'Sanitation & Hygiène',
    'Consommables & Sacs',
    'Énergie (Sonelgaz/Eau)',
    'Transport & Carburant',
    'Outillage & Équipement',
    'Autre charge',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(inventoryItemsStreamProvider);
    final alerts = ref.watch(lowStockAlertsProvider);
    final movementsAsync = ref.watch(inventoryMovementsStreamProvider);
    final expensesAsync = ref.watch(expensesStreamProvider);

    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        title: const Row(
          children: [
            Text('📦 ', style: TextStyle(fontSize: 20)),
            Text('Stocks & Achats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          ],
        ),
        backgroundColor: AppConstants.cardDark,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.accentGreen,
          labelColor: AppConstants.accentGreen,
          unselectedLabelColor: const Color(0xFF888888),
          tabs: [
            Tab(
              icon: const Icon(Icons.inventory_2_outlined, size: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('État des Stocks'),
                  if (alerts.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppConstants.alertRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${alerts.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(
              icon: Icon(Icons.receipt_long_outlined, size: 20),
              text: 'Dépenses & Achats',
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'fab_new_stock',
                  backgroundColor: AppConstants.cardDark,
                  foregroundColor: AppConstants.accentGreen,
                  elevation: 2,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouvel Article', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () => _showAddItemDialog(context),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.extended(
                  heroTag: 'fab_buy_stock',
                  backgroundColor: AppConstants.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  icon: const Icon(Icons.shopping_cart, size: 18),
                  label: const Text('Acheter / Dépense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () => _showAddExpenseDialog(context),
                ),
              ],
            )
          : FloatingActionButton.extended(
              heroTag: 'fab_new_expense',
              backgroundColor: AppConstants.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Nouvelle Dépense', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _showAddExpenseDialog(context),
            ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ==============================
          // TAB 1 : ÉTAT DES STOCKS
          // ==============================
          ListView(
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
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.alertRed, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
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
                'Catalogue Matières Premières & Intrants :',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.accentGreen),
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
                    children: items.map((item) => _buildItemCard(item)).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppConstants.primaryGreen)),
                error: (err, stack) => Text('Erreur : $err', style: const TextStyle(color: Colors.red)),
              ),

              const SizedBox(height: 24),
              const Text(
                'Derniers Mouvements Traçables :',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.accentGreen),
              ),
              const SizedBox(height: 10),

              movementsAsync.when(
                data: (movements) {
                  return Column(
                    children: movements.take(5).map((m) => _buildMovementTile(m)).toList(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => Text('Erreur : $err', style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 80),
            ],
          ),

          // ==============================
          // TAB 2 : DÉPENSES & ACHATS
          // ==============================
          expensesAsync.when(
            data: (expenses) => _buildExpensesTab(expenses),
            loading: () => const Center(child: CircularProgressIndicator(color: AppConstants.primaryGreen)),
            error: (err, stack) => Center(child: Text('Erreur : $err', style: const TextStyle(color: Colors.red))),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB DÉPENSES & ACHATS
  // -------------------------------------------------------------
  List<ExpenseModel> _applyExpenseFilters(List<ExpenseModel> allExpenses) {
    final sorted = List<ExpenseModel>.from(allExpenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    final now = DateTime.now();
    if (_expenseFilterMode == ExpenseFilterMode.date && _expenseSelectedDate != null) {
      return sorted.where((e) =>
          e.date.year == _expenseSelectedDate!.year &&
          e.date.month == _expenseSelectedDate!.month &&
          e.date.day == _expenseSelectedDate!.day).toList();
    } else if (_expenseFilterMode == ExpenseFilterMode.today) {
      return sorted.where((e) =>
          e.date.year == now.year &&
          e.date.month == now.month &&
          e.date.day == now.day).toList();
    } else if (_expenseFilterMode == ExpenseFilterMode.month) {
      return sorted.where((e) =>
          e.date.year == now.year &&
          e.date.month == now.month).toList();
    } else if (_expenseFilterMode == ExpenseFilterMode.stock) {
      return sorted.where((e) => e.isStockable).toList();
    } else if (_expenseFilterMode == ExpenseFilterMode.operational) {
      return sorted.where((e) => !e.isStockable).toList();
    } else if (_expenseFilterMode == ExpenseFilterMode.recent5) {
      return sorted.take(5).toList();
    }
    return sorted;
  }

  Future<void> _pickExpenseDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseSelectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Filtrer les achats par date',
      confirmText: 'Filtrer',
      cancelText: 'Annuler',
    );
    if (picked != null) {
      setState(() {
        _expenseSelectedDate = picked;
        _expenseFilterMode = ExpenseFilterMode.date;
      });
    }
  }

  void _navigateExpenseDate(int offsetDays) {
    final base = _expenseSelectedDate ?? (_expenseFilterMode == ExpenseFilterMode.today ? DateTime.now() : DateTime.now());
    final newDate = base.add(Duration(days: offsetDays));
    setState(() {
      _expenseSelectedDate = newDate;
      _expenseFilterMode = ExpenseFilterMode.date;
    });
  }

  String _getExpenseDateDisplay() {
    if (_expenseSelectedDate == null) {
      if (_expenseFilterMode == ExpenseFilterMode.today) return 'Aujourd\'hui';
      return 'Date';
    }
    final now = DateTime.now();
    if (_expenseSelectedDate!.year == now.year &&
        _expenseSelectedDate!.month == now.month &&
        _expenseSelectedDate!.day == now.day) {
      return 'Aujourd\'hui';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (_expenseSelectedDate!.year == yesterday.year &&
        _expenseSelectedDate!.month == yesterday.month &&
        _expenseSelectedDate!.day == yesterday.day) {
      return 'Hier';
    }
    return '${_expenseSelectedDate!.day}/${_expenseSelectedDate!.month}';
  }

  void _clearExpenseDateFilter() {
    setState(() {
      _expenseSelectedDate = null;
      _expenseFilterMode = ExpenseFilterMode.recent5;
    });
  }

  Widget _buildExpenseFilterChip({required String label, required ExpenseFilterMode mode}) {
    final isSelected = _expenseFilterMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppConstants.primaryGreen.withOpacity(0.25),
      backgroundColor: AppConstants.cardDark,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppConstants.accentGreen : const Color(0xFFAAAAAA),
      ),
      onSelected: (_) {
        setState(() {
          _expenseFilterMode = mode;
          if (mode != ExpenseFilterMode.date) {
            _expenseSelectedDate = null;
          }
        });
      },
    );
  }

  Widget _buildExpensesTab(List<ExpenseModel> expenses) {
    final displayedExpenses = _applyExpenseFilters(expenses);
    final subTotal = displayedExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final hasMoreThan5 = expenses.length > 5;
    final isLimitedTo5 = _expenseFilterMode == ExpenseFilterMode.recent5 && hasMoreThan5;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Barre de filtres ultra-compacte (1 seule ligne avec scroll rapide + sélecteur calendrier)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppConstants.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppConstants.borderDark),
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildExpenseFilterChip(
                        label: '⏱️ 5 Derniers',
                        mode: ExpenseFilterMode.recent5,
                      ),
                      const SizedBox(width: 6),
                      _buildExpenseFilterChip(
                        label: '📅 Aujourd\'hui',
                        mode: ExpenseFilterMode.today,
                      ),
                      const SizedBox(width: 6),
                      _buildExpenseFilterChip(
                        label: '🗓️ Ce mois',
                        mode: ExpenseFilterMode.month,
                      ),
                      const SizedBox(width: 6),
                      _buildExpenseFilterChip(
                        label: '📦 Stocks (${expenses.where((e) => e.isStockable).length})',
                        mode: ExpenseFilterMode.stock,
                      ),
                      const SizedBox(width: 6),
                      _buildExpenseFilterChip(
                        label: '⚡ Charges (${expenses.where((e) => !e.isStockable).length})',
                        mode: ExpenseFilterMode.operational,
                      ),
                      const SizedBox(width: 6),
                      _buildExpenseFilterChip(
                        label: '📜 Tout (${expenses.length})',
                        mode: ExpenseFilterMode.all,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Sélecteur de date ergonomique jour par jour (◀ Date ▶ ✕)
              Container(
                decoration: BoxDecoration(
                  color: _expenseSelectedDate != null
                      ? AppConstants.primaryGreen.withOpacity(0.12)
                      : AppConstants.backgroundDark,
                  border: Border.all(
                    color: _expenseSelectedDate != null
                        ? AppConstants.primaryGreen
                        : AppConstants.borderDark,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _navigateExpenseDate(-1),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 7),
                        child: Icon(Icons.chevron_left, size: 18, color: AppConstants.accentGreen),
                      ),
                    ),
                    InkWell(
                      onTap: () => _pickExpenseDate(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month, size: 15, color: AppConstants.accentGreen),
                            const SizedBox(width: 3),
                            Text(
                              _getExpenseDateDisplay(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: _expenseSelectedDate != null ? FontWeight.bold : FontWeight.w600,
                                color: _expenseSelectedDate != null ? AppConstants.accentGreen : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _navigateExpenseDate(1),
                      borderRadius: BorderRadius.horizontal(
                        right: _expenseSelectedDate == null ? const Radius.circular(9) : Radius.zero,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 7),
                        child: Icon(Icons.chevron_right, size: 18, color: AppConstants.accentGreen),
                      ),
                    ),
                    if (_expenseSelectedDate != null) ...[
                      InkWell(
                        onTap: _clearExpenseDateFilter,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
                        child: const Padding(
                              padding: EdgeInsets.only(right: 6, left: 2, top: 7, bottom: 7),
                          child: Icon(Icons.close, size: 14, color: AppConstants.alertRed),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // En-tête avec statut du filtre actif & sous-total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _expenseFilterMode == ExpenseFilterMode.recent5
                  ? '5 Derniers Achats :'
                  : (_expenseFilterMode == ExpenseFilterMode.date && _expenseSelectedDate != null
                      ? 'Achats du ${_expenseSelectedDate!.day}/${_expenseSelectedDate!.month} :'
                      : (_expenseFilterMode == ExpenseFilterMode.today
                          ? 'Achats d\'Aujourd\'hui :'
                          : (_expenseFilterMode == ExpenseFilterMode.month
                              ? 'Achats de ce mois :'
                              : (_expenseFilterMode == ExpenseFilterMode.stock
                                  ? 'Achats de Stocks :'
                                  : (_expenseFilterMode == ExpenseFilterMode.operational
                                      ? 'Frais d\'Exploitation :'
                                      : 'Tous les Achats :'))))),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.accentGreen),
            ),
            Text(
              'Total : ${subTotal.toStringAsFixed(0)} DA',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (displayedExpenses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                const Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFF666666)),
                const SizedBox(height: 8),
                const Text(
                  'Aucun achat trouvé pour ce filtre.',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 14),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _expenseSelectedDate = null;
                      _expenseFilterMode = ExpenseFilterMode.recent5;
                    });
                  },
                  child: const Text('Réinitialiser aux 5 derniers', style: TextStyle(color: AppConstants.accentGreen)),
                ),
              ],
            ),
          )
        else ...[
          ...displayedExpenses.map((e) => _buildExpenseCard(e)),

          if (isLimitedTo5) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.history, color: AppConstants.accentGreen),
                label: Text(
                  'Afficher les ${expenses.length - 5} achats plus anciens ↓',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentGreen),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppConstants.accentGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() => _expenseFilterMode = ExpenseFilterMode.all);
                },
              ),
            ),
          ],

          if (_expenseFilterMode == ExpenseFilterMode.all && hasMoreThan5) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.keyboard_arrow_up, color: AppConstants.accentGreen),
              label: const Text('Réduire aux 5 derniers achats', style: TextStyle(color: AppConstants.accentGreen)),
              onPressed: () {
                setState(() => _expenseFilterMode = ExpenseFilterMode.recent5);
              },
            ),
          ],
        ],

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildExpenseCard(ExpenseModel e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(14),
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
                    Flexible(
                      child: Text(
                        e.label,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: e.isStockable ? const Color(0xFF1F3A1F) : const Color(0xFF3A2E1A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: e.isStockable ? AppConstants.accentGreen.withOpacity(0.4) : AppConstants.alertYellow.withOpacity(0.4)),
                      ),
                      child: Text(
                        e.isStockable ? '📦 Stock +${e.quantity.toStringAsFixed(e.quantity.truncateToDouble() == e.quantity ? 0 : 1)} ${e.unit}' : '⚡ Frais direct',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: e.isStockable ? AppConstants.accentGreen : AppConstants.alertYellow,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    '-${MycoCalculations.formatCurrency(e.amount)}',
                    style: const TextStyle(color: AppConstants.alertRed, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFF888888), size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _confirmDeleteExpense(e),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${e.date.day}/${e.date.month} • ${e.category}${e.supplier != null && e.supplier!.isNotEmpty ? " • 🏪 ${e.supplier}" : ""}',
            style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
          ),
          if (e.unitPrice > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.backgroundDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstants.borderDark),
              ),
              child: Text(
                'Détail : ${e.quantity} ${e.unit} × ${e.unitPrice.toStringAsFixed(0)} DA / ${e.unit}',
                style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // CARTE ARTICLE EN STOCK
  // -------------------------------------------------------------
  Widget _buildItemCard(InventoryItemModel item) {
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
                    Row(
                      children: [
                        Text(item.isLowStock ? '🔴 ' : '🟢 '),
                        Flexible(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        InkWell(
                          onTap: () => _showEditThresholdDialog(context, item),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppConstants.backgroundDark,
                              border: Border.all(color: AppConstants.accentGreen.withOpacity(0.4)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Seuil : ${item.alertThreshold} ${item.unit}',
                                  style: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit, size: 11, color: AppConstants.accentGreen),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          '• ${item.unitCost.toStringAsFixed(0)} DA / ${item.unit}',
                          style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                        ),
                      ],
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: item.isLowStock ? AppConstants.alertRed : AppConstants.accentGreen,
                        ),
                      ),
                      if (item.isLowStock)
                        const Text(
                          'CRITIQUE',
                          style: TextStyle(fontSize: 9, color: AppConstants.alertRed, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.tune, color: Color(0xFFAAAAAA), size: 18),
                    tooltip: 'Modifier seuil & coût',
                    onPressed: () => _showEditThresholdDialog(context, item),
                  ),
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
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.accentGreen,
                    side: const BorderSide(color: AppConstants.accentGreen),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Entrée', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showMovementDialog(context, ref, item, MovementType.stockIn),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.alertRed,
                    side: const BorderSide(color: Color(0xFF5A2A2A)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.remove, size: 16),
                  label: const Text('- Sortie', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showMovementDialog(context, ref, item, MovementType.stockOut),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A301A),
                    foregroundColor: AppConstants.alertYellow,
                    side: const BorderSide(color: Color(0xFF6A552A)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.shopping_cart, size: 16),
                  label: const Text('Acheter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _showAddExpenseDialog(context, preselectedItem: item),
                ),
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

  // -------------------------------------------------------------
  // MODALE : ENREGISTRER UNE DÉPENSE / ACHAT AVEC LIAISON STOCK
  // -------------------------------------------------------------
  void _showAddExpenseDialog(BuildContext context, {InventoryItemModel? preselectedItem}) {
    final items = ref.read(inventoryItemsStreamProvider).value ?? [];
    String? selectedStockId = preselectedItem?.id;
    final labelCtrl = TextEditingController(text: preselectedItem != null ? 'Achat ${preselectedItem.name}' : '');
    final qtyCtrl = TextEditingController(text: '1');
    final unitPriceCtrl = TextEditingController(text: preselectedItem != null ? preselectedItem.unitCost.toStringAsFixed(0) : '');
    final totalAmountCtrl = TextEditingController(text: preselectedItem != null ? preselectedItem.unitCost.toStringAsFixed(0) : '');
    final supplierCtrl = TextEditingController();
    final customUnitCtrl = TextEditingController();
    final customCatCtrl = TextEditingController();

    String selectedUnit = preselectedItem?.unit ?? 'kg';
    String selectedCategory = preselectedItem != null ? 'Matière première (Paille/Blanc)' : 'Autre charge';
    bool autoSyncStock = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentStockItem = selectedStockId != null ? items.firstWhere((i) => i.id == selectedStockId, orElse: () => items.first) : null;

          void updateCalculations(String source) {
            final qty = double.tryParse(qtyCtrl.text) ?? 0.0;
            if (source == 'qty' || source == 'unitPrice') {
              final up = double.tryParse(unitPriceCtrl.text) ?? 0.0;
              if (qty > 0 && up > 0) {
                totalAmountCtrl.text = (qty * up).round().toString();
              }
            } else if (source == 'total') {
              final total = double.tryParse(totalAmountCtrl.text) ?? 0.0;
              if (qty > 0 && total > 0) {
                unitPriceCtrl.text = (total / qty).toStringAsFixed(2);
              }
            }
          }

          return AlertDialog(
            backgroundColor: AppConstants.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppConstants.borderDark),
            ),
            title: const Row(
              children: [
                Text('💸 ', style: TextStyle(fontSize: 20)),
                Text('Enregistrer une Dépense / Achat', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sélecteur d'article en stock
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppConstants.backgroundDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConstants.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Article en Stock concerné :', style: TextStyle(color: AppConstants.accentGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String?>(
                            value: selectedStockId,
                            isExpanded: true,
                            dropdownColor: AppConstants.cardDark,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('⚡ Frais d\'exploitation (sans stock)', style: TextStyle(color: Color(0xFF888888))),
                              ),
                              ...items.map((i) => DropdownMenuItem(
                                    value: i.id,
                                    child: Text('📦 ${i.name} (${i.currentStock} ${i.unit})'),
                                  )),
                            ],
                            onChanged: (val) {
                              setModalState(() {
                                selectedStockId = val;
                                if (val != null) {
                                  final s = items.firstWhere((x) => x.id == val);
                                  if (labelCtrl.text.isEmpty || labelCtrl.text.startsWith('Achat ')) {
                                    labelCtrl.text = 'Achat ${s.name}';
                                  }
                                  selectedUnit = s.unit;
                                  if (s.unitCost > 0) {
                                    unitPriceCtrl.text = s.unitCost.toStringAsFixed(0);
                                    updateCalculations('unitPrice');
                                  }
                                }
                              });
                            },
                          ),
                          if (currentStockItem != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Stock actuel : ${currentStockItem.currentStock} ${currentStockItem.unit} ➔ Deviendra : ${(currentStockItem.currentStock + (double.tryParse(qtyCtrl.text) ?? 1)).toStringAsFixed(1)} ${currentStockItem.unit}',
                              style: const TextStyle(color: AppConstants.accentGreen, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Motif de la dépense
                    _buildDarkInput(
                      controller: labelCtrl,
                      label: 'Motif / Désignation de la dépense',
                    ),
                    const SizedBox(height: 10),

                    // Catégorie
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _customCategories.contains(selectedCategory) ? selectedCategory : _customCategories.first,
                            dropdownColor: AppConstants.cardDark,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: const InputDecoration(
                              labelText: 'Catégorie',
                              labelStyle: TextStyle(color: Color(0xFF888888), fontSize: 11),
                              filled: true,
                              fillColor: AppConstants.backgroundDark,
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              ..._customCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))),
                              const DropdownMenuItem(value: '__NEW__', child: Text('+ Nouvelle catégorie...')),
                            ],
                            onChanged: (val) {
                              if (val == '__NEW__') {
                                setModalState(() => selectedCategory = '__NEW__');
                              } else if (val != null) {
                                setModalState(() => selectedCategory = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (selectedCategory == '__NEW__') ...[
                      const SizedBox(height: 8),
                      _buildDarkInput(controller: customCatCtrl, label: 'Nom de la nouvelle catégorie'),
                    ],
                    const SizedBox(height: 10),

                    // Quantité & Unité
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildDarkInput(
                            controller: qtyCtrl,
                            label: 'Quantité',
                            keyboard: TextInputType.number,
                            onChanged: (_) => setModalState(() => updateCalculations('qty')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _customUnits.contains(selectedUnit) ? selectedUnit : _customUnits.first,
                            dropdownColor: AppConstants.cardDark,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: const InputDecoration(
                              labelText: 'Unité',
                              labelStyle: TextStyle(color: Color(0xFF888888), fontSize: 11),
                              filled: true,
                              fillColor: AppConstants.backgroundDark,
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              ..._customUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))),
                              const DropdownMenuItem(value: '__NEW__', child: Text('+ Ajouter...')),
                            ],
                            onChanged: (val) {
                              if (val == '__NEW__') {
                                setModalState(() => selectedUnit = '__NEW__');
                              } else if (val != null) {
                                setModalState(() => selectedUnit = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (selectedUnit == '__NEW__') ...[
                      const SizedBox(height: 8),
                      _buildDarkInput(controller: customUnitCtrl, label: 'Nouvelle unité (ex: paquet, botte)'),
                    ],
                    const SizedBox(height: 10),

                    // Calcul Prix Unitaire & Total
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppConstants.backgroundDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConstants.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildDarkInput(
                                  controller: unitPriceCtrl,
                                  label: 'Prix / unité (DA)',
                                  keyboard: TextInputType.number,
                                  onChanged: (_) => setModalState(() => updateCalculations('unitPrice')),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildDarkInput(
                                  controller: totalAmountCtrl,
                                  label: 'Prix Total (DA)',
                                  keyboard: TextInputType.number,
                                  onChanged: (_) => setModalState(() => updateCalculations('total')),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '💡 Astuce : saisissez Qté × PU ou tapez directement le Prix Total.',
                            style: TextStyle(color: Color(0xFF666666), fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Fournisseur
                    _buildDarkInput(controller: supplierCtrl, label: 'Fournisseur / Lieu (ex: Ferme Blida)'),
                    const SizedBox(height: 8),

                    // Case à cocher auto-sync
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: autoSyncStock,
                      activeColor: AppConstants.primaryGreen,
                      title: const Text('Mettre à jour le stock automatiquement', style: TextStyle(color: Colors.white, fontSize: 12)),
                      onChanged: (v) => setModalState(() => autoSyncStock = v ?? true),
                    ),
                  ],
                ),
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
                  final label = labelCtrl.text.trim();
                  final amount = double.tryParse(totalAmountCtrl.text) ?? 0.0;
                  final qty = double.tryParse(qtyCtrl.text) ?? 1.0;
                  final unitPrice = double.tryParse(unitPriceCtrl.text) ?? (qty > 0 ? amount / qty : 0.0);

                  if (label.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez saisir un libellé.')));
                    return;
                  }
                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Montant invalide.')));
                    return;
                  }

                  String finalCategory = selectedCategory;
                  if (selectedCategory == '__NEW__') {
                    final newCat = customCatCtrl.text.trim();
                    finalCategory = newCat.isNotEmpty ? newCat : 'Autre charge';
                    if (!_customCategories.contains(finalCategory)) _customCategories.add(finalCategory);
                  }

                  String finalUnit = selectedUnit;
                  if (selectedUnit == '__NEW__') {
                    final newU = customUnitCtrl.text.trim();
                    finalUnit = newU.isNotEmpty ? newU : 'unités';
                    if (!_customUnits.contains(finalUnit)) _customUnits.add(finalUnit);
                  }

                  final expense = ExpenseModel(
                    id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
                    label: label,
                    amount: amount,
                    category: finalCategory,
                    quantity: qty,
                    unit: finalUnit,
                    unitPrice: unitPrice,
                    supplier: supplierCtrl.text.trim().isEmpty ? null : supplierCtrl.text.trim(),
                    isStockable: autoSyncStock && selectedStockId != null,
                    stockItemId: autoSyncStock ? selectedStockId : null,
                    date: DateTime.now(),
                  );

                  await ref.read(inventoryRepositoryProvider).addExpense(expense);
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Dépense enregistrée : -${amount.toStringAsFixed(0)} DA')),
                    );
                  }
                },
                child: const Text('Enregistrer Achat'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteExpense(ExpenseModel e) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF5A2A2A)),
        ),
        title: const Text('Supprimer cette dépense ?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Supprimer "${e.label}" (-${e.amount.toStringAsFixed(0)} DA) ?\n${e.isStockable ? "\nCet achat avait alimenté le stock (+${e.quantity} ${e.unit})." : ""}',
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
              await ref.read(inventoryRepositoryProvider).deleteExpense(e.id, revertStock: e.isStockable);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // DIALOGUES STOCK EXISTANTS (AJOUT, SUPPRESSION, MOUVEMENT)
  // -------------------------------------------------------------
  void _showAddItemDialog(BuildContext context) {
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

  void _showEditThresholdDialog(BuildContext context, InventoryItemModel item) {
    final nameCtrl = TextEditingController(text: item.name);
    final thresholdCtrl = TextEditingController(text: item.alertThreshold.toString());
    final costCtrl = TextEditingController(text: item.unitCost.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppConstants.borderDark),
        ),
        title: Row(
          children: [
            const Icon(Icons.tune, color: AppConstants.accentGreen, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Paramètres & Seuil Stock',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.name} (${item.unit})',
                style: const TextStyle(color: AppConstants.accentGreen, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildDarkInput(controller: nameCtrl, label: 'Désignation de l\'article'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDarkInput(
                      controller: thresholdCtrl,
                      label: 'Seuil alerte (${item.unit})',
                      keyboard: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDarkInput(
                      controller: costCtrl,
                      label: 'Coût DA / ${item.unit}',
                      keyboard: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Color(0xFF888888))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              final newThreshold = double.tryParse(thresholdCtrl.text) ?? item.alertThreshold;
              final newCost = double.tryParse(costCtrl.text) ?? item.unitCost;

              final updated = item.copyWith(
                name: newName.isNotEmpty ? newName : item.name,
                alertThreshold: newThreshold,
                unitCost: newCost,
              );

              await ref.read(inventoryRepositoryProvider).updateItem(updated);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Seuil et paramètres mis à jour !'),
                    backgroundColor: AppConstants.primaryGreen,
                  ),
                );
              }
            },
            child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
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
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 11),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
