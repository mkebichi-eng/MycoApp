import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/myco_calculations.dart';
import '../clients/clients_screen.dart';
import '../inventory/inventory_screen.dart';
import '../production/production_dashboard_screen.dart';
import '../production/qr_scanner_screen.dart';
import '../providers/app_providers.dart';
import '../sales/sales_screen.dart';

class MainDashboardScreen extends ConsumerStatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  ConsumerState<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends ConsumerState<MainDashboardScreen> {
  String _selectedPeriod = 'month'; // day | month1 | month | month12 | all

  @override
  Widget build(BuildContext context) {
    final financial = ref.watch(financialMetricsProvider);
    final production = ref.watch(productionStatsProvider);
    final alerts = ref.watch(lowStockAlertsProvider);

    final totalRev = financial['totalRevenue'] as double? ?? 35950.0;
    final totalFee = financial['totalDeliveryFees'] as double? ?? 1350.0;
    final totalExp = 7125.0; // Achats intrants et paille
    final netProfit = totalRev - totalFee - totalExp;
    final totalPaid = 30450.0;
    final totalDue = totalRev - totalPaid;

    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🍄 ', style: TextStyle(fontSize: 20)),
            Text(
              'MycoTrack',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppConstants.accentGreen),
            tooltip: 'Scanner QR Sac',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const QrScannerScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppConstants.alertRed),
            tooltip: 'Se déconnecter',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Titre de section stylé MycoTrack
          _buildSectionHeader('RÉSUMÉ FINANCIER GLOBAL'),

          // Grille de KPI Cards (style MycoTrack exact)
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  title: 'Chiffre d\'affaires',
                  value: '${totalRev.toStringAsFixed(0)} DA',
                  subtitle: 'Total livraisons',
                  color: AppConstants.accentGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKPICard(
                  title: 'Frais livreurs',
                  value: '${totalFee.toStringAsFixed(0)} DA',
                  subtitle: 'Total courses',
                  color: AppConstants.alertYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  title: 'Dépenses',
                  value: '${totalExp.toStringAsFixed(0)} DA',
                  subtitle: 'Achats + matériel',
                  color: AppConstants.alertRed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKPICard(
                  title: 'Bénéfice net',
                  value: '${netProfit.toStringAsFixed(0)} DA',
                  subtitle: 'Marge réelle',
                  color: netProfit >= 0 ? AppConstants.accentGreen : AppConstants.alertRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  title: 'Encaissé',
                  value: '${totalPaid.toStringAsFixed(0)} DA',
                  subtitle: 'Reçu en caisse',
                  color: AppConstants.accentGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKPICard(
                  title: 'Impayés',
                  value: '${totalDue.toStringAsFixed(0)} DA',
                  subtitle: '1 client +30j',
                  color: totalDue > 0 ? AppConstants.alertYellow : AppConstants.accentGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Graphique Bénéfice Net avec sélecteur de périodes (MycoTrack)
          _buildSectionHeader('BÉNÉFICE NET'),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodChip('day', '7 jours'),
                _buildPeriodChip('month1', '1 mois'),
                _buildPeriodChip('month', '6 mois'),
                _buildPeriodChip('month12', '12 mois'),
                _buildPeriodChip('all', 'Tout'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppConstants.borderDark),
            ),
            height: 170,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        const labels = ['Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep'];
                        final idx = val.toInt();
                        if (idx >= 0 && idx < labels.length) {
                          return Text(labels[idx], style: const TextStyle(color: Color(0xFF888888), fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _buildBarGroup(0, 12.5),
                  _buildBarGroup(1, 18.0),
                  _buildBarGroup(2, 22.0),
                  _buildBarGroup(3, 19.5),
                  _buildBarGroup(4, 25.0),
                  _buildBarGroup(5, 27.4),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Section Alertes (Style MycoTrack exact)
          if (alerts.isNotEmpty) ...[
            _buildSectionHeader('⚠️ ALERTES'),
            ...alerts.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1A1A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF5A2A2A)),
                  ),
                  child: Text(
                    '🔴 Stock bas — ${item.name} : ${item.currentStock} ${item.unit}',
                    style: const TextStyle(color: AppConstants.alertRed, fontSize: 13),
                  ),
                )),
            const SizedBox(height: 8),
          ],

          // Production sacs actifs (Style MycoTrack exact)
          _buildSectionHeader('🍄 PRODUCTION — SACS ACTIFS'),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppConstants.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppConstants.borderDark),
            ),
            child: Column(
              children: [
                _buildBagRow('🧪 Ensemencement', '0'),
                _buildBagRow('🌡️ Incubation', '${production['activeIncubation'] ?? 21}'),
                _buildBagRow('🍄 Fructification', '${production['activeFruiting'] ?? 10}'),
                _buildBagRow('☣️ Contaminés', '${production['contaminated'] ?? 1}', isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Grille de raccourcis modules
          _buildSectionHeader('MODULES DE GESTION'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: [
              _buildModuleTile(
                title: 'Culture & Sacs',
                subtitle: 'Lots 200L & Scan',
                emoji: '🍄',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const ProductionDashboardScreen()),
                ),
              ),
              _buildModuleTile(
                title: 'Ventes & Marges',
                subtitle: 'Saisie & Recettes',
                emoji: '💰',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const SalesScreen()),
                ),
              ),
              _buildModuleTile(
                title: 'Stocks & Intrants',
                subtitle: '${alerts.length} alerte(s)',
                emoji: '📦',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const InventoryScreen()),
                ),
              ),
              _buildModuleTile(
                title: 'Clients & Tarifs',
                subtitle: 'Ajout & Prix DA/kg',
                emoji: '👤',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const ClientsScreen()),
                ),
              ),
              _buildModuleTile(
                title: 'Scanner QR',
                subtitle: 'Action en 1 tap',
                emoji: '📷',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const QrScannerScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppConstants.accentGreen,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConstants.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Color(0xFF666666), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String key, String label) {
    final isActive = _selectedPeriod == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = key),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppConstants.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppConstants.primaryGreen : AppConstants.borderDark,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const TextStyle(color: Color(0xFFAAAAAA)).color,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppConstants.primaryGreen,
          width: 22,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildBagRow(String label, String count, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppConstants.borderDark)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
          Text(count, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildModuleTile({
    required String title,
    required String subtitle,
    required String emoji,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppConstants.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppConstants.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
            ),
          ],
        ),
      ),
    );
  }
}
