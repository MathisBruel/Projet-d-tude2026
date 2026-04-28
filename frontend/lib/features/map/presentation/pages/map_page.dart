import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:agrisense/core/services/cache_service.dart';
import '../../data/models/parcel_model.dart';
import '../../data/repositories/parcel_repository.dart';
import '../widgets/parcel_bottom_sheet.dart';
import 'package:agrisense/features/shared/widgets/bottom_nav_bar.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  List<ParcelModel> parcels = [];
  List<ParcelModel> _filteredParcels = [];
  bool isLoading = true;
  String? selectedParcelId;
  final Set<Polygon> polygons = {};
  final Set<Marker> _markers = {};

  StreamSubscription<Position>? _positionStream;
  ParcelModel? _nearbyParcel;
  double? _nearbyDistanceM;

  String _searchQuery = '';
  String? _selectedCulture;
  String _sortBy = 'name'; // 'name', 'area', 'date'
  final TextEditingController _searchController = TextEditingController();

  static const initialCameraPosition = CameraPosition(
    target: LatLng(48.8566, 2.3522), // Paris comme position par défaut
    zoom: 6,
  );

  @override
  void initState() {
    super.initState();
    final cache = CacheService();
    // Load from cache if available
    if (cache.isMapPageCacheValid()) {
      final cachedData = cache.getMapPageCache();
      if (cachedData != null) {
        setState(() {
          parcels = cachedData['parcels'] as List<ParcelModel>;
          _applyFilters();
          isLoading = false;
        });
      }
    } else {
      // Load from API if cache is invalid
      _loadParcels();
    }
    _requestLocationPermission();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _searchController.dispose();
    mapController.dispose();
    super.dispose();
  }

  Future<void> _loadParcels() async {
    try {
      final loadedParcels = await ParcelRepository.getParcels();
      setState(() {
        parcels = loadedParcels;
        _applyFilters();
        isLoading = false;
      });
      // Store in cache for persistence across page navigations
      CacheService().setMapPageCache({
        'parcels': loadedParcels,
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    }
  }

  void _applyFilters() {
    List<ParcelModel> result = parcels;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((p) => p.name.toLowerCase().contains(query)).toList();
    }

    if (_selectedCulture != null && _selectedCulture!.isNotEmpty) {
      result = result.where((p) => p.cultureType == _selectedCulture).toList();
    }

    switch (_sortBy) {
      case 'area':
        result.sort((a, b) => b.areaHa.compareTo(a.areaHa));
        break;
      case 'date':
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      default:
        result.sort((a, b) => a.name.compareTo(b.name));
    }

    setState(() {
      _filteredParcels = result;
      _buildPolygons();
    });
  }

  void _buildPolygons() {
    polygons.clear();
    _markers.clear();
    for (final parcel in _filteredParcels) {
      final points = parcel.toLatLngList();
      if (points.length >= 3) {
        polygons.add(
          Polygon(
            polygonId: PolygonId(parcel.id),
            points: points,
            fillColor: _getCultureTypeColor(parcel.cultureType).withOpacity(0.3),
            strokeColor: _getCultureTypeColor(parcel.cultureType),
            strokeWidth: 2,
            onTap: () => _showParcelDetails(parcel),
          ),
        );
      }
      final centroid = _centroidOf(parcel);
      if (centroid != null) {
        _markers.add(
          Marker(
            markerId: MarkerId('marker_${parcel.id}'),
            position: centroid,
            onTap: () => _showParcelDetails(parcel),
            infoWindow: InfoWindow(
              title: parcel.name,
              snippet: '${parcel.cultureType} · ${parcel.areaHa} ha',
            ),
          ),
        );
      }
    }
  }

  LatLng? _centroidOf(ParcelModel parcel) {
    final points = parcel.toLatLngList();
    if (points.isEmpty) return null;
    final lat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final lng = points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
    return LatLng(lat, lng);
  }

  void _startProximityTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 15,
      ),
    ).listen(_checkProximity);
  }

  void _checkProximity(Position position) {
    ParcelModel? closest;
    double closestDist = double.infinity;

    for (final parcel in _filteredParcels) {
      final centroid = _centroidOf(parcel);
      if (centroid == null) continue;
      final dist = Geolocator.distanceBetween(
        position.latitude, position.longitude,
        centroid.latitude, centroid.longitude,
      );
      if (dist < closestDist) {
        closestDist = dist;
        closest = parcel;
      }
    }

    setState(() {
      if (closest != null && closestDist <= 500.0) {
        _nearbyParcel = closest;
        _nearbyDistanceM = closestDist;
      } else {
        _nearbyParcel = null;
        _nearbyDistanceM = null;
      }
    });
  }

  Color _getCultureTypeColor(String cultureType) {
    switch (cultureType.toLowerCase()) {
      case 'blé':
      case 'blé tendre':
        return const Color(0xFF2E7D32); // Vert primaire
      case 'maïs':
        return const Color(0xFFF9A825); // Ambre secondaire
      case 'colza':
        return const Color(0xFF4CAF50); // Vert clair
      default:
        return const Color(0xFF546E7A); // Gris neutre
    }
  }

  void _showParcelDetails(ParcelModel parcel) {
    setState(() => selectedParcelId = parcel.id);
    showModalBottomSheet(
      context: context,
      builder: (context) => ParcelBottomSheet(
        parcel: parcel,
        onParcelUpdated: _loadParcels,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      _goToCurrentLocation();
      _startProximityTracking();
    }
  }

  void _showFilterMenu() {
    const cultures = ['Blé tendre', 'Maïs', 'Colza', 'Orge', 'Tournesol', 'Pomme de terre'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCFD8DC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Filtrer et trier',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1C2B2D)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Type de culture',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1C2B2D)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'Tous',
                  selected: _selectedCulture == null || _selectedCulture!.isEmpty,
                  onPressed: () {
                    setState(() => _selectedCulture = null);
                    _applyFilters();
                    Navigator.pop(context);
                  },
                ),
                ...cultures.map((c) => _FilterChip(
                  label: c,
                  selected: _selectedCulture == c,
                  onPressed: () {
                    setState(() => _selectedCulture = c);
                    _applyFilters();
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Trier par',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1C2B2D)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SortButton(
                    label: 'Nom',
                    selected: _sortBy == 'name',
                    onPressed: () {
                      setState(() => _sortBy = 'name');
                      _applyFilters();
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SortButton(
                    label: 'Surface',
                    selected: _sortBy == 'area',
                    onPressed: () {
                      setState(() => _sortBy = 'area');
                      _applyFilters();
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SortButton(
                    label: 'Date',
                    selected: _sortBy == 'date',
                    onPressed: () {
                      setState(() => _sortBy = 'date');
                      _applyFilters();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedCulture = null;
                    _sortBy = 'name';
                  });
                  _applyFilters();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F7F8),
                  foregroundColor: const Color(0xFF546E7A),
                  elevation: 0,
                ),
                child: const Text('Réinitialiser les filtres', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      if (mapController != null) {
        mapController.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            12,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur de géolocalisation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Google Map
            GoogleMap(
              onMapCreated: (controller) => mapController = controller,
              initialCameraPosition: initialCameraPosition,
              polygons: polygons,
              markers: _markers,
              zoomControlsEnabled: false,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
            ),

            // Floating header avec recherche
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF546E7A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Rechercher une parcelle...',
                            hintStyle: const TextStyle(color: Color(0xFF546E7A), fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      GestureDetector(
                        onTap: _showFilterMenu,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.tune,
                            color: Color(0xFF2E7D32),
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _loadParcels,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            color: Color(0xFF2E7D32),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Map controls (zoom + geoloc)
          Positioned(
            top: 200,
            right: 14,
            child: Column(
              children: [
                _MapControlButton(
                  icon: Icons.add,
                  onPressed: () => mapController.animateCamera(
                    CameraUpdate.zoomIn(),
                  ),
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.remove,
                  onPressed: () => mapController.animateCamera(
                    CameraUpdate.zoomOut(),
                  ),
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.my_location,
                  onPressed: _goToCurrentLocation,
                ),
              ],
            ),
          ),

          // Legend
          Positioned(
            bottom: 110,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LÉGENDE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF546E7A),
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _LegendItem(color: const Color(0xFF2E7D32), label: 'Blé'),
                  _LegendItem(color: const Color(0xFFF9A825), label: 'Maïs'),
                  _LegendItem(color: const Color(0xFF4CAF50), label: 'Colza'),
                ],
              ),
            ),
          ),

          // FAB - Ajouter une parcelle
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              onPressed: () async {
                await context.push('/map/add');
                _loadParcels();
              },
              backgroundColor: const Color(0xFF2E7D32),
              tooltip: 'Ajouter une parcelle',
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(activeTab: 'map'),
    );
  }

}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MapControlButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFF1C2B2D)),
        iconSize: 20,
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.6),
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1C2B2D),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2E7D32) : const Color(0xFFF5F7F8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF2E7D32) : const Color(0xFFECEFF1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF1C2B2D),
          ),
        ),
      ),
    );
  }
}

class _ProximityCard extends StatelessWidget {
  final ParcelModel parcel;
  final double distanceM;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _ProximityCard({
    required this.parcel,
    required this.distanceM,
    required this.onTap,
    required this.onDismiss,
  });

  String get _distanceLabel {
    if (distanceM < 1000) return '${distanceM.round()} m';
    return '${(distanceM / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.place, color: Color(0xFF2E7D32), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      parcel.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF1C2B2D),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        _MiniChip('🌾 ${parcel.cultureType}'),
                        _MiniChip('📏 ${parcel.areaHa} ha'),
                        _MiniChip('📍 $_distanceLabel'),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF90A4AE), size: 16),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  const _MiniChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF546E7A)),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _SortButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2E7D32) : const Color(0xFFF5F7F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF2E7D32) : const Color(0xFFECEFF1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF1C2B2D),
          ),
        ),
      ),
    );
  }
}

