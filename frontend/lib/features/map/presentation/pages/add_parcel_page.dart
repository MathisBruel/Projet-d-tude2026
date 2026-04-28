import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../data/models/parcel_model.dart';
import '../../data/repositories/parcel_repository.dart';

class AddParcelPage extends StatefulWidget {
  const AddParcelPage({Key? key}) : super(key: key);

  @override
  State<AddParcelPage> createState() => _AddParcelPageState();
}

class _AddParcelPageState extends State<AddParcelPage> {
  late GoogleMapController mapController;
  final List<LatLng> points = [];
  final Set<Polyline> polylines = {};
  final Set<Marker> markers = {};
  double calculatedAreaHa = 0.0;

  static const initialCameraPosition = CameraPosition(
    target: LatLng(48.8566, 2.3522),
    zoom: 6,
  );

  void _onMapTap(LatLng point) {
    if (points.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 points atteint')),
      );
      return;
    }

    setState(() {
      points.add(point);
      _updateMarkers();
      _updatePolyline();
      _calculateArea();
    });
  }

  void _updateMarkers() {
    markers.clear();
    for (int i = 0; i < points.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('point_$i'),
          position: points[i],
          infoWindow: InfoWindow(title: 'Point ${i + 1}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }
  }

  void _updatePolyline() {
    polylines.clear();
    if (points.length > 1) {
      // Draw polyline between points
      polylines.add(
        Polyline(
          polylineId: const PolylineId('polygon'),
          points: points,
          color: const Color(0xFF2E7D32),
          width: 3,
          geodesic: true,
        ),
      );

      // Close the polygon if there are 3+ points
      if (points.length >= 3) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('close_polygon'),
            points: [points.last, points.first],
            color: const Color(0xFF2E7D32),
            width: 2,
            geodesic: true,
          ),
        );
      }
    }
  }

  void _calculateArea() {
    if (points.length < 3) {
      calculatedAreaHa = 0.0;
      return;
    }

    // Shoelace formula in degrees
    double area = 0.0;
    int n = points.length;
    for (int i = 0; i < n; i++) {
      int j = (i + 1) % n;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    area = area.abs() / 2.0;

    // Approximate to hectares
    double avgLat = points.fold<double>(0, (sum, p) => sum + p.latitude) / n;
    double latKmPerDegree = 111.0;
    double lngKmPerDegree = 111.0 * cos(avgLat * pi / 180);

    double sqKm = area * latKmPerDegree * lngKmPerDegree;
    double hectares = sqKm * 100;

    setState(() => calculatedAreaHa = double.parse(hectares.toStringAsFixed(2)));
  }

  void _undoLastPoint() {
    if (points.isNotEmpty) {
      setState(() {
        points.removeLast();
        _updateMarkers();
        _updatePolyline();
        _calculateArea();
      });
    }
  }

  Future<void> _validateParcel() async {
    if (points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez tracer au moins 3 points')),
      );
      return;
    }

    final nameController = TextEditingController();
    final cultureTypeController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle parcelle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Nom de la parcelle',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: null,
              decoration: const InputDecoration(
                hintText: 'Type de culture',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Blé tendre', child: Text('Blé tendre')),
                DropdownMenuItem(value: 'Maïs', child: Text('Maïs')),
                DropdownMenuItem(value: 'Colza', child: Text('Colza')),
                DropdownMenuItem(value: 'Orge', child: Text('Orge')),
              ],
              onChanged: (value) {
                if (value != null) {
                  cultureTypeController.text = value;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, {
              'name': nameController.text,
              'culture_type': cultureTypeController.text,
            }),
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (result == null) return;
    final name = result['name'] as String?;
    if (name == null || name.isEmpty) return;

    _createParcel(name, result['culture_type'] as String? ?? 'Blé tendre');
  }

  Future<void> _createParcel(String name, String cultureType) async {
    try {
      // Convert LatLng points to coordinate maps
      final coordinates = points
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) =>
            const Center(child: CircularProgressIndicator()),
      );

      final parcel = await ParcelRepository.createParcel(
        name: name,
        cultureType: cultureType,
        coordinates: coordinates,
      );

      if (mounted) {
        context.pop(); // Close loading
        context.pop(); // Close AddParcelPage

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Parcelle "$name" créée avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        context.pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Google Map
            GoogleMap(
              onMapCreated: (controller) => mapController = controller,
              initialCameraPosition: initialCameraPosition,
              polylines: polylines,
              markers: markers,
              onTap: _onMapTap,
            ),

            // Dark overlay
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.25),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Top instruction banner
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tracez votre parcelle',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Tapez les points sur la carte • ${points.length} posés',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom action bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AIRE CALCULÉE',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF546E7A),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '~${calculatedAreaHa.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2E7D32),
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'hectares',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF546E7A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF388E3C),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${points.length} points',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF546E7A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _undoLastPoint,
                          icon: const Icon(Icons.undo),
                          label: const Text('Annuler'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1C2B2D),
                            side: const BorderSide(
                              color: Color(0xFFECEFF1),
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _validateParcel,
                          icon: const Icon(Icons.check),
                          label: const Text('Valider le tracé'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16), // Space for bottom nav
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
