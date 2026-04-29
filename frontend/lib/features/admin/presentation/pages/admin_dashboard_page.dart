import 'package:flutter/material.dart';
import 'package:agrisense/core/theme/app_theme.dart';
import 'package:agrisense/core/services/api_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<Map<String, dynamic>> _kpiFuture;

  @override
  void initState() {
    super.initState();
    _kpiFuture = _loadKPIs();
  }

  Future<Map<String, dynamic>> _loadKPIs() async {
    // Charger les stats depuis l'API
    final resp = await ApiService.getAdminStats();
    if (resp['data'] != null) {
      return resp['data'];
    }
    return {
      'total_users': 0,
      'total_parcels': 0,
      'total_predictions': 0,
      'total_posts': 0,
      'avg_prediction_confidence': 0,
      'users_this_month': 0,
      'predictions_this_week': 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _kpiFuture,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final kpis = snapshot.data ?? {};
        final totalUsers = kpis['total_users'] as int? ?? 0;
        final totalParcels = kpis['total_parcels'] as int? ?? 0;
        final totalPredictions = kpis['total_predictions'] as int? ?? 0;
        final totalPosts = kpis['total_posts'] as int? ?? 0;
        final avgConfidence = (kpis['avg_prediction_confidence'] as num?)?.toDouble() ?? 0;
        final usersThisMonth = kpis['users_this_month'] as int? ?? 0;
        final predictionsThisWeek = kpis['predictions_this_week'] as int? ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tableau de Bord',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutreDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vue d\'ensemble des statistiques de la plateforme',
                style: TextStyle(fontSize: 14, color: AppColors.neutreMedium),
              ),
              const SizedBox(height: 32),
              // KPI Cards
              GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildKPICard(
                    label: 'Utilisateurs totals',
                    value: totalUsers.toString(),
                    icon: Icons.people_rounded,
                    color: const Color(0xFF2E7D32),
                    subtitle: '$usersThisMonth ce mois',
                  ),
                  _buildKPICard(
                    label: 'Parcelles',
                    value: totalParcels.toString(),
                    icon: Icons.landscape_rounded,
                    color: const Color(0xFFF57C00),
                    subtitle: 'Enregistrées',
                  ),
                  _buildKPICard(
                    label: 'Prédictions',
                    value: totalPredictions.toString(),
                    icon: Icons.analytics_rounded,
                    color: const Color(0xFF0277BD),
                    subtitle: '$predictionsThisWeek cette semaine',
                  ),
                  _buildKPICard(
                    label: 'Posts',
                    value: totalPosts.toString(),
                    icon: Icons.forum_rounded,
                    color: const Color(0xFFE65100),
                    subtitle: 'Communauté',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Confiance moyenne
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Confiance moyenne des prédictions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutreDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${avgConfidence.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'moyenne',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildConfidenceIndicator(
                                label: 'Confiance élevée (>80%)',
                                percentage: 65,
                                color: const Color(0xFF2E7D32),
                              ),
                              const SizedBox(height: 12),
                              _buildConfidenceIndicator(
                                label: 'Confiance moyenne (60-80%)',
                                percentage: 25,
                                color: const Color(0xFFF57C00),
                              ),
                              const SizedBox(height: 12),
                              _buildConfidenceIndicator(
                                label: 'Confiance faible (<60%)',
                                percentage: 10,
                                color: const Color(0xFFE65100),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Activity
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Activité récente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutreDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActivityItem('Nouvelle prédiction', 'Agriculteur#1234 a lancé une prédiction', Icons.analytics_rounded, Colors.blue),
                    _buildActivityItem('Nouvel utilisateur', 'Marc ROUSSEAU s\'est inscrit', Icons.person_add_rounded, const Color(0xFF2E7D32)),
                    _buildActivityItem('Post créé', 'Discussion sur les rendements de blé', Icons.forum_rounded, Colors.orange),
                    _buildActivityItem('Action enregistrée', 'Épandage d\'engrais sur parcelle#5', Icons.agriculture_rounded, Colors.brown),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKPICard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.neutreDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.neutreMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator({
    required String label,
    required double percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            Text('${percentage.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: AppColors.neutreLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(description, style: const TextStyle(fontSize: 12, color: AppColors.neutreMedium)),
              ],
            ),
          ),
          Text('Il y a 2h', style: const TextStyle(fontSize: 11, color: AppColors.neutreMedium)),
        ],
      ),
    );
  }
}
