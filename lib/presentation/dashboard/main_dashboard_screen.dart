import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/myco_calculations.dart';
import '../inventory/inventory_screen.dart';
import '../production/production_dashboard_screen.dart';
import '../production/qr_scanner_screen.dart';
import '../providers/app_providers.dart';
import '../sales/sales_screen.dart';

class MainDashboardScreen extends ConsumerWidget {
  const MainDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final financial = ref.watch(financialMetricsProvider);
    final production = ref.watch(productionStatsProvider);
    final alerts = ref.watch(lowStockAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          // Badge alerte stock
          IconButton(
            icon: Badge(
              isLabelVisible: alerts.isNotEmpty,
              label: Text('${alerts.length}'),
              child: const Icon(Icons.notifications),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const InventoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // En-tête utilisateur avec rôle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Administrateur',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rôle : ${user?.role.label ?? 'Admin'}',
                    style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.secondaryGreen,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const QrScannerScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Synthèse Financière (Devise DA)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Financière',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricTile(
                        'Chiffre d\'Affaires',
                        MycoCalculations.formatCurrency(financial['totalRevenue'] as double? ?? 0.0),
                        Colors.black87,
                      ),
                      _buildMetricTile(
                        'Marge Nette',
                        MycoCalculations.formatCurrency(financial['totalNetMargin'] as double? ?? 0.0),
                        Colors.green.shade800,
                      ),
                      _buildMetricTile(
                        'Volume Vendu',
                        MycoCalculations.formatWeight(financial['totalKgSold'] as double? ?? 0.0),
                        Colors.blueGrey,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Graphique d'évolution des ventes fl_chart
                  const Text(
                    'Évolution des Ventes & Marges (DA) :',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          // Courbe Ventes
                          LineChartBarData(
                            spots: const [
                              FlSpot(1, 10200),
                              FlSpot(2, 5500),
                              FlSpot(3, 20250),
                              FlSpot(4, 18000),
                            ],
                            isCurved: true,
                            color: AppConstants.primaryGreen,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                          ),
                          // Courbe Marge Nette
                          LineChartBarData(
                            spots: const [
                              FlSpot(1, 7675),
                              FlSpot(2, 3900),
                              FlSpot(3, 15900),
                              FlSpot(4, 14200),
                            ],
                            isCurved: true,
                            color: Colors.tealAccent.shade700,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Raccourcis Modules Métier (Grille de gros boutons)
          const Text(
            'Modules de Gestion :',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildModuleCard(
                context,
                title: 'Production',
                subtitle: '${production['totalBags']} sacs suivis',
                icon: Icons.grass,
                color: Colors.green.shade800,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const ProductionDashboardScreen()),
                ),
              ),
              _buildModuleCard(
                context,
                title: 'Ventes & Marges',
                subtitle: 'Saisie & Rapports',
                icon: Icons.monetization_on,
                color: Colors.teal.shade700,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const SalesScreen()),
                ),
              ),
              _buildModuleCard(
                context,
                title: 'Stocks & Intrants',
                subtitle: alerts.isNotEmpty ? '${alerts.length} ALERTE(S)' : 'Niveau normal',
                icon: Icons.inventory_2,
                color: alerts.isNotEmpty ? Colors.red.shade700 : Colors.blueGrey.shade700,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const InventoryScreen()),
                ),
              ),
              _buildModuleCard(
                context,
                title: 'Scan QR Code',
                subtitle: 'Action en 1 tap',
                icon: Icons.qr_code_scanner,
                color: Colors.orange.shade800,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const QrScannerScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        color: color.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
