import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:go_router/go_router.dart';
import 'package:agrisense/core/theme/app_theme.dart';
import 'package:agrisense/core/config/app_config.dart';
import 'package:agrisense/core/services/api_service.dart';
import 'package:agrisense/core/services/cache_service.dart';
import 'package:agrisense/core/services/profile_image_service.dart';
import 'package:agrisense/features/shared/widgets/bottom_nav_bar.dart';
import 'package:agrisense/features/map/data/models/parcel_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models (private)
// ─────────────────────────────────────────────────────────────────────────────

class _WeatherData {
  final double tempC;
  final double? feelsLikeC;
  final double windspeedKmh;
  final int humidityPct;
  final String condition;
  final int weathercode;
  final double precipitationMm;
  final List<double> weekTempMax;
  final List<double> weekTempMin;
  final List<String> weekDayLabels;

  _WeatherData({
    required this.tempC,
    this.feelsLikeC,
    required this.windspeedKmh,
    required this.humidityPct,
    required this.condition,
    required this.weathercode,
    required this.precipitationMm,
    required this.weekTempMax,
    required this.weekTempMin,
    required this.weekDayLabels,
  });
}

class _AlertItem {
  final String emoji;
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color sideColor;
  final Color titleColor;

  const _AlertItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.sideColor,
    required this.titleColor,
  });
}

class _PredictionItem {
  final String crop;
  final String parcelName;
  final double yieldTha;
  final int confidencePct;
  final String when;
  final String emoji;

  const _PredictionItem({
    required this.crop,
    required this.parcelName,
    required this.yieldTha,
    required this.confidencePct,
    required this.when,
    required this.emoji,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  String _userName = '';
  String _userInitials = '';
  String _locationName = '';
  double? _locationLat;
  double? _locationLng;
  List<ParcelModel> _parcels = [];
  _WeatherData? _weather;
  List<_AlertItem> _alerts = [];
  List<_PredictionItem> _predictions = [];
  int _notifCount = 0;
  File? _profileImage;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    // Load profile image from service
    _profileImage = ProfileImageService().getProfileImage();

    final cache = CacheService();
    // Load from cache if available
    if (cache.isHomePageCacheValid()) {
      final cachedData = cache.getHomePageCache();
      if (cachedData != null) {
        setState(() {
          _isLoading = false;
          _userName = cachedData['userName'] as String;
          _userInitials = cachedData['userInitials'] as String;
          _locationName = cachedData['locationName'] as String;
          _locationLat = cachedData['locationLat'] as double?;
          _locationLng = cachedData['locationLng'] as double?;
          _parcels = cachedData['parcels'] as List<ParcelModel>;
          _weather = cachedData['weather'] as _WeatherData?;
          _alerts = cachedData['alerts'] as List<_AlertItem>;
          _predictions = cachedData['predictions'] as List<_PredictionItem>;
          _notifCount = cachedData['notifCount'] as int;
        });
        return;
      }
    }
    // Load from API if cache is invalid
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Profile + parcels en parallèle
      final results = await Future.wait([
        ApiService.getProfile(),
        ApiService.getParcels(),
      ]);

      final profileResp = results[0];
      final parcelsResp = results[1];

      // ── Parse profile ──────────────────────────────────────────────────
      final profile = (profileResp['profile'] as Map<String, dynamic>?) ?? {};
      final stats = (profileResp['stats'] as Map<String, dynamic>?) ?? {};
      final firstName = (profile['first_name'] as String?) ?? '';
      final lastName = (profile['last_name'] as String?) ?? '';
      final fullName = '$firstName $lastName'.trim();
      final userName = fullName.isEmpty ? 'Agriculteur' : fullName;
      final userInitials = _initials(userName);
      final notifCount = (stats['notifications_unread'] as int?) ?? 0;
      final avatarUrl = (profile['avatar_url'] as String?);

      double? lat = (profile['location_lat'] as num?)?.toDouble();
      double? lng = (profile['location_lng'] as num?)?.toDouble();
      String locationName = (profile['location_name'] as String?) ?? '';

      // ── Parse parcels ──────────────────────────────────────────────────
      final parcelsData = (parcelsResp['data'] as List<dynamic>?) ?? [];
      final parcels = parcelsData
          .map((p) => ParcelModel.fromJson(p as Map<String, dynamic>))
          .toList();

      // ── Fallback location: centroïde de la première parcelle ───────────
      if ((lat == null || lng == null) && parcels.isNotEmpty) {
        final coords = parcels.first.coordinates;
        if (coords.isNotEmpty) {
          lat = coords.map((c) => c.lat).reduce((a, b) => a + b) / coords.length;
          lng = coords.map((c) => c.lng).reduce((a, b) => a + b) / coords.length;
          locationName = parcels.first.region ?? parcels.first.name;
        }
      }

      // ── Load weather + alerts + predictions (si coordonnées dispo) ─────
      _WeatherData? weather;
      List<_AlertItem> alerts = [];
      List<_PredictionItem> predictions = [];

      if (lat != null && lng != null) {
        final cultureType =
            parcels.isNotEmpty ? parcels.first.cultureType : null;

        final secondaryResults = await Future.wait([
          ApiService.getWeather(lat, lng),
          ApiService.getWeatherAlerts(lat: lat, lng: lng, cultureType: cultureType),
          ApiService.getPredictions(limit: 5),
        ]);

        weather = _parseWeather(secondaryResults[0]);
        alerts = _parseAlerts(secondaryResults[1], parcels);
        predictions = _parsePredictions(secondaryResults[2], parcels);
      } else {
        final predsResp = await ApiService.getPredictions(limit: 5);
        predictions = _parsePredictions(predsResp, parcels);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _userName = userName;
          _userInitials = userInitials;
          _locationName = locationName.isEmpty ? 'France' : locationName;
          _locationLat = lat;
          _locationLng = lng;
          _parcels = parcels;
          _weather = weather;
          _alerts = alerts;
          _predictions = predictions;
          _notifCount = notifCount;
          _avatarUrl = avatarUrl;
        });
        // Store in cache for persistence across page navigations
        CacheService().setHomePageCache({
          'userName': userName,
          'userInitials': userInitials,
          'locationName': locationName.isEmpty ? 'France' : locationName,
          'locationLat': lat,
          'locationLng': lng,
          'parcels': parcels,
          'weather': weather,
          'alerts': alerts,
          'predictions': predictions,
          'notifCount': notifCount,
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _userName = 'Agriculteur';
          _userInitials = 'A';
        });
      }
    }
  }

  // ── Parsers ──────────────────────────────────────────────────────────────

  _WeatherData? _parseWeather(Map<String, dynamic> resp) {
    try {
      final data = resp['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      final current = data['current'] as Map<String, dynamic>;
      final daily = data['daily'] as Map<String, dynamic>;

      final tempMaxRaw = (daily['temp_max'] as List<dynamic>? ?? []);
      final tempMinRaw = (daily['temp_min'] as List<dynamic>? ?? []);
      final precipRaw = (daily['precipitation_mm'] as List<dynamic>? ?? []);
      final datesRaw = (daily['dates'] as List<dynamic>? ?? []);

      final weekDayLabels = datesRaw.map((d) {
        final date = DateTime.tryParse(d as String);
        return date != null ? _dayAbbr(date.weekday) : '?';
      }).toList();

      return _WeatherData(
        tempC: (current['temp_c'] as num? ?? 0).toDouble(),
        feelsLikeC: (current['feels_like_c'] as num?)?.toDouble(),
        windspeedKmh: (current['windspeed_kmh'] as num? ?? 0).toDouble(),
        humidityPct: (current['humidity_pct'] as num? ?? 65).toInt(),
        condition: current['condition'] as String? ?? 'Nuageux',
        weathercode: (current['weathercode'] as num? ?? 0).toInt(),
        precipitationMm:
            precipRaw.isNotEmpty ? (precipRaw[0] as num? ?? 0).toDouble() : 0,
        weekTempMax:
            tempMaxRaw.map((v) => (v as num? ?? 0).toDouble()).toList(),
        weekTempMin:
            tempMinRaw.map((v) => (v as num? ?? 0).toDouble()).toList(),
        weekDayLabels: weekDayLabels,
      );
    } catch (_) {
      return null;
    }
  }

  List<_AlertItem> _parseAlerts(
      Map<String, dynamic> resp, List<ParcelModel> parcels) {
    try {
      final data = resp['data'] as Map<String, dynamic>?;
      if (data == null) return [];
      final alertsData = (data['alerts'] as List<dynamic>? ?? []);
      return alertsData.take(5).map((a) {
        final alert = a as Map<String, dynamic>;
        return _alertItemFrom(alert, parcels);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  _AlertItem _alertItemFrom(
      Map<String, dynamic> alert, List<ParcelModel> parcels) {
    final type = alert['type'] as String? ?? '';
    final severity = alert['severity'] as String? ?? 'MEDIUM';
    final dateStr = alert['date'] as String? ?? '';
    final parcelName =
        parcels.isNotEmpty ? parcels.first.name : 'Parcelle';

    String shortDate = '';
    if (dateStr.isNotEmpty) {
      final date = DateTime.tryParse(dateStr);
      if (date != null) {
        final diff = date.difference(DateTime.now()).inDays;
        shortDate = diff == 0 ? "Aujourd'hui" : diff == 1 ? 'Demain' : 'J+$diff';
      }
    }

    switch (type) {
      case 'FROST':
        return _AlertItem(
          emoji: '❄',
          title: 'Risque de gel',
          subtitle: '$parcelName · $shortDate',
          bgColor: const Color(0xFFFDECEC),
          sideColor: AppColors.error,
          titleColor: AppColors.error,
        );
      case 'DROUGHT':
        return _AlertItem(
          emoji: '☀',
          title: 'Stress hydrique',
          subtitle: '$parcelName · $shortDate',
          bgColor: const Color(0xFFFFF0DC),
          sideColor: AppColors.warning,
          titleColor: AppColors.warning,
        );
      case 'FLOOD':
        return _AlertItem(
          emoji: '🌧',
          title: 'Fortes pluies',
          subtitle: '$parcelName · $shortDate',
          bgColor: const Color(0xFFE3F2FD),
          sideColor: const Color(0xFF1976D2),
          titleColor: const Color(0xFF1976D2),
        );
      default:
        if (severity == 'HIGH') {
          return _AlertItem(
            emoji: '⚠',
            title: 'Alerte',
            subtitle: '$parcelName · $shortDate',
            bgColor: const Color(0xFFFDECEC),
            sideColor: AppColors.error,
            titleColor: AppColors.error,
          );
        }
        return _AlertItem(
          emoji: '✓',
          title: 'Info météo',
          subtitle: '$parcelName · $shortDate',
          bgColor: AppColors.surfacePrimary,
          sideColor: AppColors.success,
          titleColor: AppColors.success,
        );
    }
  }

  List<_PredictionItem> _parsePredictions(
      Map<String, dynamic> resp, List<ParcelModel> parcels) {
    try {
      final data = resp['data'] as Map<String, dynamic>?;
      if (data == null) return [];
      final preds = (data['predictions'] as List<dynamic>? ?? []);
      return preds.take(3).map((p) {
        final pred = p as Map<String, dynamic>;
        final parcelId = pred['parcel_id'] as String?;
        final parcel = parcels.firstWhere(
          (p) => p.id == parcelId,
          orElse: () => ParcelModel(
            id: '',
            name: 'Inconnue',
            cultureType: '',
            areaHa: 0,
            createdAt: DateTime.now(),
            coordinates: [],
          ),
        );
        final cropFromPred = pred['culture_type'] as String?;
        final crop = (cropFromPred?.isNotEmpty == true)
            ? cropFromPred!
            : parcel.cultureType;
        final createdAt =
            DateTime.tryParse(pred['created_at'] as String? ?? '');
        return _PredictionItem(
          crop: crop.isEmpty ? 'Culture' : crop,
          parcelName: parcel.name,
          yieldTha: (pred['predicted_yield_t_ha'] as num? ?? 0).toDouble(),
          confidencePct: (pred['confidence_pct'] as num? ?? 0).toInt(),
          when: createdAt != null ? _relativeTime(createdAt) : '',
          emoji: _cropEmoji(crop),
        );
      }).where((p) => p.yieldTha > 0).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.isNotEmpty
          ? parts.first[0].toUpperCase()
          : 'A';
    }
    final f = parts.first.isNotEmpty ? parts.first[0] : '';
    final l = parts.last.isNotEmpty ? parts.last[0] : '';
    return (f + l).toUpperCase();
  }

  static String _dayAbbr(int weekday) {
    const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return days[(weekday - 1) % 7];
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'hier';
    return 'il y a ${diff.inDays}j';
  }

  static String _cropEmoji(String cultureType) {
    final c = cultureType.toLowerCase();
    if (c.contains('wheat') || c.contains('blé')) return '🌾';
    if (c.contains('maize') || c.contains('corn') || c.contains('maïs')) return '🌽';
    if (c.contains('potato') || c.contains('pomme')) return '🥔';
    if (c.contains('grape') || c.contains('vigne')) return '🍇';
    if (c.contains('sunflower') || c.contains('tournesol')) return '🌻';
    if (c.contains('rape') || c.contains('colza')) return '🌼';
    if (c.contains('rice') || c.contains('riz')) return '🌾';
    if (c.contains('tomato') || c.contains('tomate')) return '🍅';
    return '🌱';
  }

  // ── Location setup ───────────────────────────────────────────────────────

  void _showLocationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LocationSetupSheet(
        onSaved: (name, lat, lng) async {
          final resp = await ApiService.updateProfile({
            'location_name': name,
            'location_lat': lat,
            'location_lng': lng,
          });
          if (resp['error'] == null && mounted) {
            setState(() {
              _locationName = name;
              _locationLat = lat;
              _locationLng = lng;
            });
            _loadAll();
          }
        },
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _DashboardHeader(
              userName: _userName,
              initials: _userInitials,
              notifCount: _notifCount,
              date: _formattedDate(),
              profileImage: _profileImage,
              avatarUrl: _avatarUrl,
            ),
            Expanded(
              child: _isLoading
                  ? const _LoadingDashContent()
                  : _parcels.isEmpty
                      ? _EmptyState(onAddParcel: () => context.go('/map/add'))
                      : _buildDashboard(),
            ),
            const BottomNavBar(activeTab: 'home'),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          _FadeInUp(
            delay: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _weather != null
                  ? _WeatherCard(
                      weather: _weather!,
                      locationName: _locationName,
                      onConfigureTap: _showLocationSheet,
                    )
                  : _WeatherSetupCard(onTap: _showLocationSheet),
            ),
          ),
          if (_alerts.isNotEmpty) ...[
            _FadeInUp(
              delay: 90,
              child: _SectionTitle(
                title: 'Mes alertes',
                trailing: '${_alerts.length} active${_alerts.length > 1 ? 's' : ''}',
              ),
            ),
            _FadeInUp(
              delay: 140,
              child: SizedBox(
                height: 92,
                child: _AlertsList(alerts: _alerts),
              ),
            ),
          ],
          _FadeInUp(
            delay: 180,
            child: _SectionTitle(
              title: 'Mes parcelles',
              trailing: '${_parcels.length} parcelle${_parcels.length > 1 ? 's' : ''}',
              onTrailingTap: () => context.go('/map'),
            ),
          ),
          _FadeInUp(
            delay: 220,
            child: SizedBox(
              height: 130,
              child: _ParcelsList(
                parcels: _parcels,
                onTap: (_) => context.go('/map'),
              ),
            ),
          ),
          if (_predictions.isNotEmpty) ...[
            _FadeInUp(
              delay: 260,
              child: _SectionTitle(
                title: 'Dernières prédictions',
                trailing: 'Tout voir →',
                onTrailingTap: () => context.go('/predict'),
              ),
            ),
            _FadeInUp(
              delay: 300,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (int i = 0; i < _predictions.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _PredictionRow(item: _predictions[i]),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formattedDate() {
    final now = DateTime.now();
    const weekdays = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${weekdays[now.weekday - 1]} ${now.day} ${months[now.month - 1]}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state (aucune parcelle)
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddParcel});

  final VoidCallback onAddParcel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0A102814), blurRadius: 16, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surfacePrimary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.map_outlined,
                    size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                'Commencez votre première parcelle',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutreDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tracez les contours de votre champ sur la carte pour débloquer météo, prédictions IA et recommandations.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.neutreMedium,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onAddParcel,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Ajouter une parcelle'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Ou découvrez',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.neutreMedium,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _DiscoverCard(
              icon: Icons.wb_sunny_outlined,
              title: 'Météo locale',
              subtitle: 'temps réel',
              onTap: () {},
            ),
            _DiscoverCard(
              icon: Icons.smart_toy_outlined,
              title: 'IA Gemini',
              subtitle: 'prédictions',
              onTap: () => GoRouter.of(context).go('/predict'),
            ),
            _DiscoverCard(
              icon: Icons.groups_outlined,
              title: 'Communauté',
              subtitle: '2 400+ agri.',
              onTap: () => GoRouter.of(context).go('/community'),
            ),
            _DiscoverCard(
              icon: Icons.bar_chart_rounded,
              title: 'Statistiques',
              subtitle: 'historique',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08102814), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 26, color: AppColors.neutreDark),
            const Spacer(),
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutreDark)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutreMedium)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.userName,
    required this.initials,
    required this.notifCount,
    required this.date,
    this.profileImage,
    this.avatarUrl,
  });

  final String userName;
  final String initials;
  final int notifCount;
  final String date;
  final File? profileImage;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutreMedium,
                      ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                          text: userName.isEmpty
                              ? 'Bonjour '
                              : 'Bonjour, ${userName.split(' ').first} '),
                      const TextSpan(text: '🌱'),
                    ],
                  ),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          _NotificationBell(count: notifCount),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                image: avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage('${AppConfig.apiUrl}$avatarUrl') as ImageProvider<Object>,
                        fit: BoxFit.cover,
                      )
                    : (profileImage != null
                        ? DecorationImage(
                            image: FileImage(profileImage!) as ImageProvider<Object>,
                            fit: BoxFit.cover,
                          )
                        : null),
              ),
              alignment: Alignment.center,
              child: (avatarUrl == null && profileImage == null)
                  ? Text(
                      initials.isEmpty ? 'A' : initials,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.notifications_none_rounded, size: 20),
        ),
        if (count > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.background, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Weather card (données réelles)
// ─────────────────────────────────────────────────────────────────────────────

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({
    required this.weather,
    required this.locationName,
    required this.onConfigureTap,
  });

  final _WeatherData weather;
  final String locationName;
  final VoidCallback onConfigureTap;

  @override
  Widget build(BuildContext context) {
    final weekVariation = weather.weekTempMax.isNotEmpty
        ? (weather.weekTempMax.last - weather.weekTempMax.first)
        : 0.0;
    final variationStr = weekVariation >= 0
        ? '+${weekVariation.toStringAsFixed(1)}°C cette semaine'
        : '${weekVariation.toStringAsFixed(1)}°C cette semaine';
    final variationColor =
        weekVariation >= 0 ? AppColors.success : AppColors.primary;

    final feelsLike = weather.feelsLikeC;
    final conditionSuffix = feelsLike != null
        ? ' · Ressenti ${feelsLike.toStringAsFixed(0)}°'
        : '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfacePrimary, AppColors.white],
          stops: [0, 0.55],
        ),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14102814), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: onConfigureTap,
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              locationName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutreMedium,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_outlined,
                              size: 11, color: AppColors.neutreMedium),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          weather.tempC.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w700,
                            height: 0.9,
                            letterSpacing: -2.5,
                            color: AppColors.neutreDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 7),
                          child: Text('°C',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.neutreMedium)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${weather.condition}$conditionSuffix',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              _WeatherIconBlob(weathercode: weather.weathercode),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: AppColors.primary.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                    child: _Metric(
                        icon: Icons.water_drop,
                        value: weather.precipitationMm.toStringAsFixed(1),
                        unit: 'mm')),
                Expanded(
                    child: _Metric(
                        icon: Icons.air_rounded,
                        value: weather.windspeedKmh.toStringAsFixed(0),
                        unit: 'km/h')),
                Expanded(
                    child: _Metric(
                        icon: Icons.opacity,
                        value: '${weather.humidityPct}',
                        unit: '%')),
              ],
            ),
          ),
          if (weather.weekTempMax.length >= 2) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('7 JOURS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutreMedium)),
                const SizedBox(width: 6),
                Expanded(
                    child: Container(
                        height: 1,
                        color: AppColors.primary.withOpacity(0.1))),
                const SizedBox(width: 6),
                Text(variationStr,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: variationColor)),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 48,
              child: _Sparkline(temperatures: weather.weekTempMax),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final label in weather.weekDayLabels.take(7))
                  _WeekLabel(label),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WeatherIconBlob extends StatelessWidget {
  const _WeatherIconBlob({required this.weathercode});

  final int weathercode;

  IconData get _icon {
    if (weathercode == 0) return Icons.wb_sunny_rounded;
    if (weathercode <= 2) return Icons.wb_cloudy_outlined;
    if (weathercode == 3) return Icons.cloud_rounded;
    if (weathercode < 51) return Icons.foggy;
    if (weathercode < 71) return Icons.umbrella_rounded;
    if (weathercode < 80) return Icons.ac_unit_rounded;
    if (weathercode < 95) return Icons.grain_rounded;
    return Icons.thunderstorm_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        children: [
          Positioned(
            right: 8,
            top: 2,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.secondary.withOpacity(0.13),
                      spreadRadius: 10),
                  BoxShadow(
                      color: AppColors.secondary.withOpacity(0.07),
                      spreadRadius: 20),
                ],
              ),
              child: Icon(_icon, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

// Weather setup card quand pas encore de localisation
class _WeatherSetupCard extends StatelessWidget {
  const _WeatherSetupCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfacePrimary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.location_on_outlined,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Configurer mon secteur',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutreDark)),
                  SizedBox(height: 3),
                  Text('Indiquez votre secteur pour voir la météo locale',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.neutreMedium)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.neutreMedium),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Parcels list
// ─────────────────────────────────────────────────────────────────────────────

class _ParcelsList extends StatelessWidget {
  const _ParcelsList({required this.parcels, required this.onTap});

  final List<ParcelModel> parcels;
  final ValueChanged<ParcelModel> onTap;

  static const _cultureColors = {
    'Wheat': Color(0xFFFFF8E1),
    'Maize': Color(0xFFF1F8E9),
    'Potatoes': Color(0xFFFBE9E7),
    'Grapes': Color(0xFFF3E5F5),
    'Rapeseed': Color(0xFFE8F5E9),
    'Sunflower': Color(0xFFFFF9C4),
  };

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: parcels.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, i) {
        final parcel = parcels[i];
        final bgColor =
            _cultureColors[parcel.cultureType] ?? AppColors.surfacePrimary;
        return GestureDetector(
          onTap: () => onTap(parcel),
          child: Container(
            width: 160,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0A102814),
                    blurRadius: 8,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: Text(
                        _HomePageState._cropEmoji(parcel.cultureType),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfacePrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${parcel.areaHa.toStringAsFixed(1)} ha',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  parcel.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutreDark),
                ),
                const SizedBox(height: 3),
                Text(
                  parcel.cultureType.isEmpty ? 'Non défini' : parcel.cultureType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.neutreMedium),
                ),
                const Spacer(),
                if (parcel.region != null && parcel.region!.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: AppColors.neutreMedium),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          parcel.region!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.neutreMedium),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alerts list
// ─────────────────────────────────────────────────────────────────────────────

class _AlertsList extends StatelessWidget {
  const _AlertsList({required this.alerts});

  final List<_AlertItem> alerts;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      itemCount: alerts.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, i) {
        final alert = alerts[i];
        return Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: alert.bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: alert.sideColor, width: 3)),
          ),
          child: Row(
            children: [
              Text(alert.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.title,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: alert.titleColor)),
                    const SizedBox(height: 2),
                    Text(alert.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.neutreDark.withOpacity(0.7))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Prediction row
// ─────────────────────────────────────────────────────────────────────────────

class _PredictionRow extends StatelessWidget {
  const _PredictionRow({required this.item});

  final _PredictionItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x0A1C2B2D)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A102814), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(
              color: Color(0x0A102814), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: AppColors.surfacePrimary,
                borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Text(item.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item.crop,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    const Text('·',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.neutreMedium)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(item.parcelName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.neutreMedium,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(item.yieldTha.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: -0.5)),
                    const SizedBox(width: 4),
                    const Text('t/ha',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.neutreMedium,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.neutreLight,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text(item.when,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.neutreMedium)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ConfidenceRing(value: item.confidencePct),
        ],
      ),
    );
  }
}

class _ConfidenceRing extends StatelessWidget {
  const _ConfidenceRing({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('CONF.',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.neutreMedium)),
        const SizedBox(height: 3),
        SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 4,
                backgroundColor: AppColors.neutreLight,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              Text('$value%',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Location setup bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _LocationSetupSheet extends StatefulWidget {
  const _LocationSetupSheet({required this.onSaved});

  final Future<void> Function(String name, double lat, double lng) onSaved;

  @override
  State<_LocationSetupSheet> createState() => _LocationSetupSheetState();
}

class _LocationSetupSheetState extends State<_LocationSetupSheet> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ApiService.geocodeAddress(query);
    if (!mounted) return;

    if (result == null) {
      setState(() {
        _loading = false;
        _error = 'Adresse introuvable. Essayez avec une ville.';
      });
      return;
    }

    setState(() => _loading = false);
    await widget.onSaved(
      result['display_name'] as String,
      result['lat'] as double,
      result['lng'] as double,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Mon secteur agricole',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutreDark),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Entrez votre ville ou région pour afficher la météo locale.',
            style: TextStyle(fontSize: 13, color: AppColors.neutreMedium),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onSubmitted: (_) => _search(),
                  decoration: const InputDecoration(
                    hintText: 'Ex: Beauce, Eure-et-Loir',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _search,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(60, 52),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('OK'),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.error)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section title
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.trailing,
    this.onTrailingTap,
  });

  final String title;
  final String trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutreDark)),
          ),
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(trailing,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metric chip
// ─────────────────────────────────────────────────────────────────────────────

class _Metric extends StatelessWidget {
  const _Metric(
      {required this.icon, required this.value, required this.unit});

  final IconData icon;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(unit,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.neutreMedium)),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeekLabel extends StatelessWidget {
  const _WeekLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            fontSize: 10,
            color: AppColors.neutreMedium,
            fontWeight: FontWeight.w600));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sparkline
// ─────────────────────────────────────────────────────────────────────────────

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.temperatures});

  final List<double> temperatures;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _SparklinePainter(temperatures: temperatures),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.temperatures});

  final List<double> temperatures;

  @override
  void paint(Canvas canvas, Size size) {
    if (temperatures.length < 2) return;

    final minTemp = temperatures.reduce((a, b) => a < b ? a : b);
    final maxTemp = temperatures.reduce((a, b) => a > b ? a : b);
    final range = (maxTemp - minTemp).abs() < 0.001 ? 1.0 : (maxTemp - minTemp);

    final points = <Offset>[];
    for (var i = 0; i < temperatures.length; i++) {
      final x = (i / (temperatures.length - 1)) * size.width;
      final y =
          size.height - 4 - ((temperatures[i] - minTemp) / range) * (size.height - 8);
      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) linePath.lineTo(p.dx, p.dy);

    final areaPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(areaPath,
        Paint()..style = PaintingStyle.fill..color = AppColors.primary.withOpacity(0.12));
    canvas.drawPath(
        linePath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.primary
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);

    final last = points.last;
    canvas.drawCircle(last, 5, Paint()..color = AppColors.white);
    canvas.drawCircle(last, 3, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.temperatures != temperatures;
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading skeletons
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingDashContent extends StatelessWidget {
  const _LoadingDashContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      children: const [
        _LoadingCardWeather(),
        SizedBox(height: 14),
        _LoadingAlertCards(),
        SizedBox(height: 14),
        _LoadingPredictionCard(),
        SizedBox(height: 10),
        _LoadingPredictionCard(),
      ],
    );
  }
}

class _LoadingCardWeather extends StatelessWidget {
  const _LoadingCardWeather();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x0A1C2B2D)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A102814), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(
              color: Color(0x0A102814), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: const [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Skeleton(width: 140, height: 12, radius: 8),
                    SizedBox(height: 10),
                    _Skeleton(width: 80, height: 40, radius: 8),
                    SizedBox(height: 10),
                    _Skeleton(width: 120, height: 12, radius: 8),
                  ],
                ),
              ),
              _Skeleton(width: 64, height: 64, radius: 32),
            ],
          ),
          SizedBox(height: 18),
          _Skeleton(height: 56, radius: 12),
        ],
      ),
    );
  }
}

class _LoadingAlertCards extends StatelessWidget {
  const _LoadingAlertCards();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, __) =>
            const _Skeleton(width: 180, height: 60, radius: 14),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: 3,
      ),
    );
  }
}

class _LoadingPredictionCard extends StatelessWidget {
  const _LoadingPredictionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x0A1C2B2D)),
      ),
      child: const Row(
        children: [
          _Skeleton(width: 44, height: 44, radius: 14),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                    widthFactor: 0.6, child: _Skeleton(height: 16, radius: 8)),
                SizedBox(height: 8),
                FractionallySizedBox(
                    widthFactor: 0.4, child: _Skeleton(height: 12, radius: 8)),
              ],
            ),
          ),
          SizedBox(width: 12),
          _Skeleton(width: 44, height: 44, radius: 22),
        ],
      ),
    );
  }
}

class _Skeleton extends StatefulWidget {
  const _Skeleton({this.width, this.height = 16, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (t * 2.0), 0),
              end: Alignment(1.0 + (t * 2.0), 0),
              colors: const [
                AppColors.neutreLight,
                Color(0xFFF7F9F7),
                AppColors.neutreLight,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fade in animation
// ─────────────────────────────────────────────────────────────────────────────

class _FadeInUp extends StatelessWidget {
  const _FadeInUp({required this.child, required this.delay});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delay),
      curve: Curves.easeOutCubic,
      builder: (_, value, childWidget) => Transform.translate(
        offset: Offset(0, (1 - value) * 10),
        child: Opacity(opacity: value, child: childWidget),
      ),
      child: child,
    );
  }
}
