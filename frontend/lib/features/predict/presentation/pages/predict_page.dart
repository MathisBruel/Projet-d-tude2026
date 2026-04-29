import 'package:flutter/material.dart';
import 'package:agrisense/core/theme/app_theme.dart';
import 'package:agrisense/core/services/api_service.dart';
import 'package:agrisense/features/shared/widgets/bottom_nav_bar.dart';
import 'package:agrisense/features/map/data/models/parcel_model.dart';
import 'package:agrisense/features/predict/presentation/pages/prediction_detail_page.dart';

class PredictPage extends StatefulWidget {
  const PredictPage({Key? key}) : super(key: key);

  @override
  State<PredictPage> createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  List<ParcelModel> _parcels = [];
  List<Map<String, dynamic>> _history = [];
  ParcelModel? _selectedParcel;
  bool _isLoading = true;
  bool _isPredicting = false;
  Map<String, dynamic>? _lastResult;

  // Tips IA
  List<Map<String, dynamic>> _tips = [];
  bool _isLoadingTips = false;

  // Actions
  List<Map<String, dynamic>> _actions = [];
  bool _isLoadingActions = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService.getParcels(),
      ApiService.getPredictions(limit: 10),
    ]);

    final parcelsResp = results[0];
    final historyResp = results[1];

    if (mounted) {
      setState(() {
        if (parcelsResp['data'] != null) {
          final raw = parcelsResp['data'];
          final list = (raw is List) ? raw : (raw['parcels'] as List<dynamic>? ?? []);
          _parcels = list.map((p) => ParcelModel.fromJson(p as Map<String, dynamic>)).toList();
        }
        if (historyResp['data'] != null) {
          final raw = historyResp['data'];
          final list = raw is List ? raw : (raw['predictions'] as List<dynamic>? ?? []);
          _history = list.map((p) => Map<String, dynamic>.from(p as Map)).toList();
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTips() async {
    if (_selectedParcel == null) return;
    setState(() => _isLoadingTips = true);
    final resp = await ApiService.getParcelTips(_selectedParcel!.id);
    if (mounted) {
      setState(() {
        _isLoadingTips = false;
        if (resp['data'] != null) {
          final rawTips = resp['data']['tips'] as List<dynamic>? ?? [];
          _tips = rawTips.map((t) => Map<String, dynamic>.from(t as Map)).toList();
        }
      });
    }
  }

  Future<void> _loadActions() async {
    if (_selectedParcel == null) return;
    setState(() => _isLoadingActions = true);
    final resp = await ApiService.getParcelActions(_selectedParcel!.id, limit: 20, days: 90);
    if (mounted) {
      setState(() {
        _isLoadingActions = false;
        if (resp['data'] != null) {
          final rawActions = resp['data']['actions'] as List<dynamic>? ?? [];
          _actions = rawActions.map((a) => Map<String, dynamic>.from(a as Map)).toList();
        }
      });
    }
  }

  void _onParcelChanged(ParcelModel? val) {
    setState(() {
      _selectedParcel = val;
      _tips = [];
      _actions = [];
      _lastResult = null;
    });
    if (val != null) {
      _loadActions();
    }
  }

  Future<void> _runPrediction() async {
    if (_selectedParcel == null) return;

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
          const SnackBar(content: Text('Parcelle sans coordonnees')),
        );
      }
      return;
    }

    final resp = await ApiService.predict(
      lat: center.lat,
      lng: center.lng,
      cultureType: parcel.cultureType,
      parcelId: parcel.id,
    );

    if (mounted) {
      setState(() {
        _isPredicting = false;
        if (resp['data'] != null) {
          _lastResult = resp['data'];
          _history.insert(0, {
            'culture_type': parcel.cultureType,
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

    // Charger les tips IA apres la prediction
    _loadTips();
  }

  Future<void> _showAddActionDialog() async {
    if (_selectedParcel == null) return;

    String actionType = 'fertilizer';
    final productController = TextEditingController();
    final quantityController = TextEditingController();
    String unit = 'kg';
    final notesController = TextEditingController();

    final actionTypes = {
      'fertilizer': 'Engrais',
      'pesticide': 'Pesticide',
      'irrigation': 'Irrigation',
      'harvest': 'Recolte',
      'seeding': 'Semis',
      'tillage': 'Travail du sol',
      'other': 'Autre',
    };

    final units = ['kg', 'L', 'mm', 't', 'unite'];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Enregistrer une action'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: actionType,
                  decoration: const InputDecoration(labelText: 'Type d\'action'),
                  items: actionTypes.entries.map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => actionType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: productController,
                  decoration: const InputDecoration(
                    labelText: 'Produit / description',
                    hintText: 'ex: Ammonitrate 33.5%',
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Quantite'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: unit,
                          decoration: const InputDecoration(labelText: 'Unite'),
                          items: units.map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u),
                          )).toList(),
                          onChanged: (v) => setDialogState(() => unit = v!),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Observations...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final data = <String, dynamic>{
        'action_type': actionType,
      };
      if (productController.text.isNotEmpty) data['product_name'] = productController.text;
      if (quantityController.text.isNotEmpty) {
        data['quantity'] = double.tryParse(quantityController.text);
      }
      data['unit'] = unit;
      if (notesController.text.isNotEmpty) data['notes'] = notesController.text;

      final resp = await ApiService.createParcelAction(_selectedParcel!.id, data);
      if (resp['data'] != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action enregistree')),
        );
        _loadActions();
      }
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
                    if (_selectedParcel != null) ...[
                      const SizedBox(height: 24),
                      _buildActionsSection(),
                    ],
                    if (_tips.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildTipsSection(),
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
            onChanged: _onParcelChanged,
          ),
          if (_selectedParcel != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfacePrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.grass_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Culture : ${_selectedParcel!.cultureType}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.neutreDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_selectedParcel != null && !_isPredicting)
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
    final geminiComment = result['gemini_comment'] as String? ?? '';

    return Column(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PredictionDetailPage(prediction: result),
            ),
          ),
          child: Container(
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
                    'Resultat de la prediction',
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
                      label: 'Rendement estime',
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
                        label: 'Temperature',
                        value: '${(weather['avg_temp_c'] as num?)?.toStringAsFixed(1) ?? '-'}°C',
                        icon: Icons.thermostat_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _resultMetric(
                        label: 'Pluviometrie',
                        value: '${(weather['rainfall_mm'] as num?)?.toStringAsFixed(0) ?? '-'} mm',
                        icon: Icons.water_drop_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          ),
        ),
        if (geminiComment.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8F5E9)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analyse Gemini',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        geminiComment,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.neutreDark,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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

  Widget _buildActionsSection() {
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.agriculture_rounded, color: Color(0xFFE65100), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Journal d\'actions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.neutreDark),
                ),
              ),
              IconButton(
                onPressed: _showAddActionDialog,
                icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 28),
                tooltip: 'Ajouter une action',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingActions)
            const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else if (_actions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aucune action enregistree. Ajoutez vos traitements, semis, irrigations...',
                style: TextStyle(color: AppColors.neutreMedium, fontSize: 13),
              ),
            )
          else
            ...(_actions.take(5).map((a) => _buildActionItem(a))),
        ],
      ),
    );
  }

  Widget _buildActionItem(Map<String, dynamic> action) {
    final typeLabels = {
      'fertilizer': 'Engrais',
      'pesticide': 'Pesticide',
      'irrigation': 'Irrigation',
      'harvest': 'Recolte',
      'seeding': 'Semis',
      'tillage': 'Travail du sol',
      'other': 'Autre',
    };
    final typeIcons = {
      'fertilizer': Icons.science_rounded,
      'pesticide': Icons.bug_report_rounded,
      'irrigation': Icons.water_drop_rounded,
      'harvest': Icons.content_cut_rounded,
      'seeding': Icons.grass_rounded,
      'tillage': Icons.handyman_rounded,
      'other': Icons.more_horiz_rounded,
    };
    final typeColors = {
      'fertilizer': const Color(0xFF1B5E20),
      'pesticide': const Color(0xFFE65100),
      'irrigation': const Color(0xFF0277BD),
      'harvest': const Color(0xFFF9A825),
      'seeding': const Color(0xFF2E7D32),
      'tillage': const Color(0xFF5D4037),
      'other': const Color(0xFF616161),
    };

    final type = action['action_type'] as String? ?? 'other';
    final product = action['product_name'] as String? ?? '';
    final quantity = action['quantity'];
    final unit = action['unit'] as String? ?? '';
    final dateStr = action['date'] as String? ?? '';

    String formattedDate = '';
    if (dateStr.isNotEmpty) {
      try {
        final date = DateTime.parse(dateStr);
        formattedDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (typeColors[type] ?? Colors.grey).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(typeIcons[type] ?? Icons.more_horiz, color: typeColors[type] ?? Colors.grey, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabels[type] ?? type,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: typeColors[type]),
                ),
                if (product.isNotEmpty)
                  Text(
                    '$product${quantity != null ? ' — $quantity $unit' : ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.neutreMedium),
                  ),
              ],
            ),
          ),
          if (formattedDate.isNotEmpty)
            Text(formattedDate, style: const TextStyle(fontSize: 11, color: AppColors.neutreMedium)),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_rounded, color: Color(0xFF2E7D32), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conseils IA',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.neutreDark),
                    ),
                    Text(
                      'Recommandations personnalisees par Gemini',
                      style: TextStyle(fontSize: 11, color: AppColors.neutreMedium),
                    ),
                  ],
                ),
              ),
              if (_isLoadingTips)
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ...(_tips.map((tip) => _buildTipCard(tip))),
        ],
      ),
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip) {
    final priority = tip['priority'] as String? ?? 'low';
    final priorityColors = {
      'high': const Color(0xFFD32F2F),
      'medium': const Color(0xFFF57C00),
      'low': const Color(0xFF388E3C),
    };
    final priorityBg = {
      'high': const Color(0xFFFFEBEE),
      'medium': const Color(0xFFFFF3E0),
      'low': const Color(0xFFE8F5E9),
    };
    final priorityLabels = {
      'high': 'Urgent',
      'medium': 'Important',
      'low': 'Conseil',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: priorityBg[priority] ?? const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (priorityColors[priority] ?? Colors.grey).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColors[priority]?.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  priorityLabels[priority] ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: priorityColors[priority],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tip['title'] as String? ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tip['content'] as String? ?? '',
            style: const TextStyle(fontSize: 12.5, color: AppColors.neutreDark, height: 1.4),
          ),
        ],
      ),
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

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PredictionDetailPage(prediction: prediction),
        ),
      ),
      child: Container(
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
      ),
    );
  }
}
