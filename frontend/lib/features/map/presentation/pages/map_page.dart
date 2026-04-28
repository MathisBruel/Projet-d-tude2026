import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
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
  bool isLoading = true;
  String? selectedParcelId;
  final Set<Polygon> polygons = {};

  static const initialCameraPosition = CameraPosition(
    target: LatLng(48.8566, 2.3522), // Paris comme position par défaut
    zoom: 6,
  );

  @override
  void initState() {
    super.initState();
    _loadParcels();
    _requestLocationPermission();
  }

  Future<void> _loadParcels() async {
    try {
      final loadedParcels = await ParcelRepository.getParcels();
      setState(() {
        parcels = loadedParcels;
        _buildPolygons();
        isLoading = false;
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

  void _buildPolygons() {
    polygons.clear();
    for (final parcel in parcels) {
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
    }
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
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
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
              zoomControlsEnabled: false,
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF546E7A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rechercher une parcelle...',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: const Color(0xFF546E7A)),
                        ),
                      ),
                      Container(
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
            bottom: 90,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () => context.go('/map/add'),
              backgroundColor: const Color(0xFF2E7D32),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Ajouter une parcelle',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      ),
      bottomNavigationBar: const BottomNavBar(activeTab: 'map'),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
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

