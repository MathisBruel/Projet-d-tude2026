import 'package:flutter/material.dart';
import 'package:agrisense/core/theme/app_theme.dart';
import 'package:agrisense/core/services/api_service.dart';
import 'package:agrisense/features/shared/widgets/bottom_nav_bar.dart';
import 'package:agrisense/features/map/data/models/parcel_model.dart';

class PredictPage extends StatefulWidget {
  const PredictPage({Key? key}) : super(key: key);

  @override
  State<PredictPage> createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  List<ParcelModel> _parcels = [];
  List<String> _crops = [];
  List<Map<String, dynamic>> _history = [];
  ParcelModel? _selectedParcel;
  String? _selectedCrop;
  bool _isLoading = true;
  bool _isPredicting = false;
  Map<String, dynamic>? _lastResult;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService.getParcels(),
      ApiService.getSupportedCrops(),
      ApiService.getPredictions(limit: 10),
    ]);

    final parcelsResp = results[0];
    final cropsResp = results[1];
    final historyResp = results[2];

    if (mounted) {
      setState(() {
        if (parcelsResp['data'] != null) {
          final list = parcelsResp['data']['parcels'] as List<dynamic>? ?? [];
          _parcels = list.map((p) => ParcelModel.fromJson(p)).toList();
        }
        if (cropsResp['data'] != null) {
          _crops = List<String>.from(cropsResp['data']['crops'] ?? []);
        }
        if (historyResp['data'] != null) {
          _history = List<Map<String, dynamic>>.from(
            historyResp['data']['predictions'] ?? [],
          );
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _runPrediction() async {
    if (_selectedParcel == null || _selectedCrop == null) return;

    setState(() {
      _isPredicting = true;
      _lastResult = null;
    });

    final parcel = _selectedParcel!;
    final center = parcel.coordinates.isNotEmpty
        ? parcel.coordinates.first
        : null;

    if (center == null) {
      setState(() => _isPredicting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parcelle sans coordonnées')),
        );
      }
      return;
    }

    final resp = await ApiService.predict(
      lat: center.lat,
      lng: center.lng,
      cultureType: _selectedCrop!,
      parcelId: parcel.id,
    );

    if (mounted) {
      setState(() {
        _isPredicting = false;
        if (resp['data'] != null) {
          _lastResult = resp['data'];
          _history.insert(0, {
            'culture_type': _selectedCrop,
            'predicted_yield_t_ha': resp['data']['predicted_yield_t_ha'],
            'confidence_pct': resp['data']['confidence_pct'],
            'weather_input': resp['data']['weather_input'],
            'created_at': DateTime.now().toIso8601String(),
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resp['error'] ?? 'Erreur inconnue')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Prédictions IA'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutreDark,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPredictionForm(),
                    if (_lastResult != null) ...[
                      const SizedBox(height: 24),
                      _buildResultCard(),
                    ],
                    const SizedBox(height: 24),
                    _buildHistorySection(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const BottomNavBar(activeTab: 'predict'),
    );
  }

  Widget _buildPredictionForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfacePrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nouvelle prédiction',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutreDark,
                      ),
                    ),
                    Text(
                      'Estimez le rendement de votre parcelle',
                      style: TextStyle(fontSize: 13, color: AppColors.neutreMedium),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<ParcelModel>(
            value: _selectedParcel,
            decoration: const InputDecoration(
              labelText: 'Parcelle',
              prefixIcon: Icon(Icons.landscape_rounded),
            ),
            items: _parcels.map((p) => DropdownMenuItem(
              value: p,
              child: Text('${p.name} (${p.areaHa.toStringAsFixed(1)} ha)'),
            )).toList(),
            onChanged: (val) {
              setState(() {
                _selectedParcel = val;
                if (val != null && _crops.contains(val.cultureType)) {
                  _selectedCrop = val.cultureType;
                }
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCrop,
            decoration: const InputDecoration(
              labelText: 'Culture',
              prefixIcon: Icon(Icons.grass_rounded),
            ),
            items: _crops.map((c) => DropdownMenuItem(
              value: c,
              child: Text(c),
            )).toList(),
            onChanged: (val) => setState(() => _selectedCrop = val),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_selectedParcel != null && _selectedCrop != null && !_isPredicting)
                  ? _runPrediction
                  : null,
              icon: _isPredicting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.rocket_launch_rounded),
              label: Text(_isPredicting ? 'Analyse en cours...' : 'Lancer la prédiction'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _lastResult!;
    final yield_ = (result['predicted_yield_t_ha'] as num).toDouble();
    final confidence = (result['confidence_pct'] as num).toInt();
    final weather = result['weather_input'] as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Résultat de la prédiction',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _resultMetric(
                  label: 'Rendement estimé',
                  value: '${yield_.toStringAsFixed(2)} t/ha',
                  icon: Icons.grain_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _resultMetric(
                  label: 'Confiance',
                  value: '$confidence%',
                  icon: Icons.verified_rounded,
                ),
              ),
            ],
          ),
          if (weather != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _resultMetric(
                    label: 'Température',
                    value: '${(weather['avg_temp_c'] as num?)?.toStringAsFixed(1) ?? '-'}°C',
                    icon: Icons.thermostat_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _resultMetric(
                    label: 'Pluviométrie',
                    value: '${(weather['rainfall_mm'] as num?)?.toStringAsFixed(0) ?? '-'} mm',
                    icon: Icons.water_drop_rounded,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultMetric({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historique',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.neutreDark,
          ),
        ),
        const SizedBox(height: 12),
        if (_history.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Aucune prédiction pour le moment',
                style: TextStyle(color: AppColors.neutreMedium),
              ),
            ),
          )
        else
          ...(_history.take(10).map((p) => _buildHistoryItem(p))),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> prediction) {
    final culture = prediction['culture_type'] ?? 'Inconnu';
    final yield_ = (prediction['predicted_yield_t_ha'] as num?)?.toDouble() ?? 0;
    final confidence = (prediction['confidence_pct'] as num?)?.toInt() ?? 0;
    final dateStr = prediction['created_at'] as String?;
    String formattedDate = '';
    if (dateStr != null) {
      try {
        final date = DateTime.parse(dateStr);
        formattedDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.grass_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  culture,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (formattedDate.isNotEmpty)
                  Text(
                    formattedDate,
                    style: const TextStyle(color: AppColors.neutreMedium, fontSize: 12),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${yield_.toStringAsFixed(2)} t/ha',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '$confidence% confiance',
                style: const TextStyle(color: AppColors.neutreMedium, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
