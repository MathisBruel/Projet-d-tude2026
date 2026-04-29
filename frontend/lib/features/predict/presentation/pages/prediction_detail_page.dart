import 'package:flutter/material.dart';
import 'package:agrisense/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class PredictionDetailPage extends StatelessWidget {
  final Map<String, dynamic> prediction;

  const PredictionDetailPage({
    Key? key,
    required this.prediction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final yieldValue = (prediction['predicted_yield_t_ha'] ?? 0).toString();
    final confidence = (prediction['confidence_pct'] ?? 0).toInt();
    final cultureType = prediction['culture_type'] ?? 'Parcelle';
    final parcelName = prediction['parcel_name'] ?? 'Sans nom';
    final createdAt = _parseDate(prediction['created_at']);

    final weatherInput = prediction['weather_input'] as Map<String, dynamic>? ?? {};
    final geminiResponse = prediction['gemini_response'] as Map<String, dynamic>? ?? {};
    final recommendations = (geminiResponse['recommendations'] as List<dynamic>? ?? [])
        .map((r) => r as Map<String, dynamic>)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              elevation: 0,
              backgroundColor: AppColors.background,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Détail Prédiction'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _shareResult(context, parcelName, yieldValue),
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_outline),
                  onPressed: () => _showSnackbar(context, 'Prédiction sauvegardée'),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Success banner with result
                    _ResultCard(
                      yieldValue: yieldValue,
                      parcelName: parcelName,
                      cultureType: cultureType,
                      confidence: confidence,
                    ),

                    const SizedBox(height: 24),

                    // Weather data used
                    if (weatherInput.isNotEmpty) ...[
                      const _SectionTitle('Données météo utilisées'),
                      const SizedBox(height: 10),
                      _WeatherDataCard(weatherData: weatherInput),
                      const SizedBox(height: 24),
                    ],

                    // Soil data
                    if (geminiResponse['soil_data'] != null) ...[
                      const _SectionTitle('Données sol'),
                      const SizedBox(height: 10),
                      _SoilDataCard(soilData: geminiResponse['soil_data'] as Map<String, dynamic>? ?? {}),
                      const SizedBox(height: 24),
                    ],

                    // Recommendations
                    if (recommendations.isNotEmpty) ...[
                      const _SectionTitle('Recommandations'),
                      const SizedBox(height: 10),
                      ..._buildRecommendations(recommendations),
                      const SizedBox(height: 24),
                    ],

                    // Prediction metadata
                    const _SectionTitle('Informations'),
                    const SizedBox(height: 10),
                    _MetadataCard(
                      createdAt: createdAt,
                      modelVersion: geminiResponse['model_version'] as String? ?? 'Gemini 1.5 Pro',
                      confidence: confidence,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Retour'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showSnackbar(context, 'Nouvelle prédiction'),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Nouvelle'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecommendations(List<Map<String, dynamic>> recommendations) {
    return recommendations.asMap().entries.map((entry) {
      final i = entry.key;
      final reco = entry.value;
      final priority = reco['priority'] as String? ?? 'Normal';
      final title = reco['title'] as String? ?? 'Recommandation';
      final description = reco['description'] as String? ?? '';

      final priorityColor = {
        'Haute': AppColors.error,
        'Moyenne': AppColors.warning,
        'Info': AppColors.success,
      }[priority] ?? AppColors.primary;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      priority.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: priorityColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutreMedium,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  void _shareResult(BuildContext context, String parcelName, String yield) {
    _showSnackbar(context, 'Partage: $parcelName - Rendement estimé: $yield t/ha');
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String yieldValue;
  final String parcelName;
  final String cultureType;
  final int confidence;

  const _ResultCard({
    required this.yieldValue,
    required this.parcelName,
    required this.cultureType,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF4F6F4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$parcelName · $cultureType',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.neutreMedium,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                yieldValue,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                't/ha',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutreMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Rendement estimé à la récolte',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.neutreMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySurf,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Confiance du modèle · $confidence% · Bonne',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: confidence / 100.0,
              minHeight: 6,
              backgroundColor: AppColors.neutreLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherDataCard extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  const _WeatherDataCard({required this.weatherData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySurf,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _WeatherItem(
            icon: Icons.thermostat_outlined,
            label: 'Température',
            value: '${weatherData['temperature'] ?? 'N/A'}°C',
          ),
          const SizedBox(height: 8),
          _WeatherItem(
            icon: Icons.water_drop_outlined,
            label: 'Humidité',
            value: '${weatherData['humidity'] ?? 'N/A'}%',
          ),
          const SizedBox(height: 8),
          _WeatherItem(
            icon: Icons.cloud_outlined,
            label: 'Pluie',
            value: '${weatherData['precipitation'] ?? 'N/A'} mm',
          ),
          const SizedBox(height: 8),
          _WeatherItem(
            icon: Icons.air_outlined,
            label: 'Vent',
            value: '${weatherData['wind_speed'] ?? 'N/A'} km/h',
          ),
        ],
      ),
    );
  }
}

class _WeatherItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.neutreMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _SoilDataCard extends StatelessWidget {
  final Map<String, dynamic> soilData;

  const _SoilDataCard({required this.soilData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _SoilItem(
            icon: '🌱',
            label: 'pH du sol',
            value: '${soilData['ph'] ?? 'N/A'}',
          ),
          const SizedBox(height: 8),
          _SoilItem(
            icon: '💧',
            label: 'Matière organique',
            value: '${soilData['organic_matter'] ?? 'N/A'}%',
          ),
          const SizedBox(height: 8),
          _SoilItem(
            icon: '⚙️',
            label: 'Azote',
            value: '${soilData['nitrogen'] ?? 'N/A'} mg/kg',
          ),
        ],
      ),
    );
  }
}

class _SoilItem extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _SoilItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.neutreMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.neutreDark,
          ),
        ),
      ],
    );
  }
}

class _MetadataCard extends StatelessWidget {
  final DateTime? createdAt;
  final String modelVersion;
  final int confidence;

  const _MetadataCard({
    required this.createdAt,
    required this.modelVersion,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = createdAt != null
        ? DateFormat('d MMM yyyy à HH:mm', 'fr_FR').format(createdAt!)
        : 'Date inconnue';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetaItem(label: 'Date', value: dateStr),
          const SizedBox(height: 10),
          _MetaItem(label: 'Modèle', value: modelVersion),
          const SizedBox(height: 10),
          _MetaItem(label: 'Confiance', value: '$confidence%'),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.neutreMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.neutreDark,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.neutreDark,
        letterSpacing: -0.2,
      ),
    );
  }
}
