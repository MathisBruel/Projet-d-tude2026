import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../data/repositories/parcel_repository.dart';

class AddParcelPage extends StatefulWidget {
  const AddParcelPage({Key? key}) : super(key: key);

  @override
  State<AddParcelPage> createState() => _AddParcelPageState();
}

class _AddParcelPageState extends State<AddParcelPage> {
  GoogleMapController? _mapController;
  final List<LatLng> _points = [];
  final Set<Polyline> _polylines = {};
  final Set<Polygon> _polygons = {};
  final Set<Marker> _markers = {};
  double _calculatedAreaHa = 0.0;
  MapType _currentMapType = MapType.hybrid;

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  List<_GeocodingResult> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(46.603354, 1.888334),
    zoom: 5.5,
  );

  static const _greenPrimary = Color(0xFF2E7D32);
  static const _textPrimary = Color(0xFF1C2B2D);
  static const _textSecondary = Color(0xFF546E7A);

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      _goToCurrentLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapTap(LatLng point) {
    if (_showResults) {
      setState(() => _showResults = false);
      _searchFocusNode.unfocus();
    }
    if (_points.length >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 20 points atteint')),
      );
      return;
    }
    setState(() {
      _points.add(point);
      _refreshShapes();
      _calculateArea();
    });
  }

  void _refreshShapes() {
    _markers
      ..clear()
      ..addAll(List.generate(_points.length, (i) {
        return Marker(
          markerId: MarkerId('p_$i'),
          position: _points[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          anchor: const Offset(0.5, 0.5),
        );
      }));

    _polylines.clear();
    _polygons.clear();

    if (_points.length >= 2 && _points.length < 3) {
      _polylines.add(Polyline(
        polylineId: const PolylineId('trace'),
        points: _points,
        color: _greenPrimary,
        width: 3,
      ));
    } else if (_points.length >= 3) {
      _polygons.add(Polygon(
        polygonId: const PolygonId('parcel'),
        points: _points,
        fillColor: _greenPrimary.withOpacity(0.25),
        strokeColor: _greenPrimary,
        strokeWidth: 3,
      ));
    }
  }

  void _calculateArea() {
    if (_points.length < 3) {
      _calculatedAreaHa = 0.0;
      return;
    }
    double area = 0.0;
    final n = _points.length;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += _points[i].longitude * _points[j].latitude;
      area -= _points[j].longitude * _points[i].latitude;
    }
    area = area.abs() / 2.0;
    final avgLat = _points.fold<double>(0, (s, p) => s + p.latitude) / n;
    final lngKmPerDeg = 111.0 * cos(avgLat * pi / 180);
    final sqKm = area * 111.0 * lngKmPerDeg;
    _calculatedAreaHa = double.parse((sqKm * 100).toStringAsFixed(2));
  }

  void _undoLastPoint() {
    if (_points.isEmpty) return;
    setState(() {
      _points.removeLast();
      _refreshShapes();
      _calculateArea();
    });
  }

  void _clearAll() {
    setState(() {
      _points.clear();
      _markers.clear();
      _polylines.clear();
      _polygons.clear();
      _calculatedAreaHa = 0.0;
    });
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      LocationPermission p = perm;
      if (perm == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.deniedForever || p == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission de localisation refusée')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 16),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur localisation : $e')),
        );
      }
    }
  }

  void _cycleMapType() {
    setState(() {
      _currentMapType = switch (_currentMapType) {
        MapType.normal => MapType.hybrid,
        MapType.hybrid => MapType.satellite,
        MapType.satellite => MapType.normal,
        _ => MapType.normal,
      };
    });
  }

  IconData _mapTypeIcon() => switch (_currentMapType) {
        MapType.normal => Icons.layers_outlined,
        MapType.hybrid => Icons.satellite_alt_outlined,
        MapType.satellite => Icons.map_outlined,
        _ => Icons.layers_outlined,
      };

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _doSearch(query.trim());
    });
  }

  Future<void> _doSearch(String query) async {
    setState(() {
      _isSearching = true;
      _showResults = true;
    });
    try {
      final uri = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeQueryComponent(query)}&count=6&language=fr&format=json',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['results'] as List<dynamic>?) ?? [];
        setState(() {
          _searchResults = list.map((e) => _GeocodingResult.fromJson(e)).toList();
          _isSearching = false;
        });
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (_) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(_GeocodingResult r) {
    _searchController.text = r.label;
    _searchFocusNode.unfocus();
    setState(() => _showResults = false);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(r.lat, r.lng), 14),
    );
  }

  Future<void> _validateParcel() async {
    if (_points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tracez au moins 3 points pour former une parcelle')),
      );
      return;
    }

    final result = await showModalBottomSheet<_ParcelFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ParcelFormSheet(area: _calculatedAreaHa),
    );

    if (!mounted || result == null) return;
    await _createParcel(result.name, result.cultureType);
  }

  Future<void> _createParcel(String name, String cultureType) async {
    final coords = _points
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ParcelRepository.createParcel(
        name: name,
        cultureType: cultureType,
        coordinates: coords,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Parcelle "$name" créée')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (c) => _mapController = c,
            initialCameraPosition: _initialCameraPosition,
            mapType: _currentMapType,
            polylines: _polylines,
            polygons: _polygons,
            markers: _markers,
            onTap: _onMapTap,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),

          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                _buildSearchResults(),
              ],
            ),
          ),

          Positioned(
            right: 14,
            top: MediaQuery.of(context).padding.top + 140,
            child: Column(
              children: [
                _MapButton(
                  icon: _mapTypeIcon(),
                  onPressed: _cycleMapType,
                  tooltip: 'Mode de vue',
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.add,
                  onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.remove,
                  onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.my_location,
                  onPressed: _goToCurrentLocation,
                  tooltip: 'Ma position',
                ),
              ],
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        children: [
          Row(
            children: [
              _CircleIconButton(
                icon: Icons.arrow_back,
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(fontSize: 14, color: _textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une adresse, ville…',
                      hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: _textSecondary, size: 20),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _showResults = false;
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(Icons.close, size: 18, color: _textSecondary),
                              ),
                            ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.72),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.touch_app, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _points.isEmpty
                        ? 'Tapez sur la carte pour tracer votre parcelle'
                        : 'Continuez à ajouter des points • ${_points.length}/20',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                if (_points.isNotEmpty)
                  GestureDetector(
                    onTap: _clearAll,
                    child: const Text(
                      'Effacer',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_showResults) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 280),
      child: _isSearching
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : _searchResults.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Aucun résultat',
                    style: TextStyle(color: _textSecondary, fontSize: 13),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 48),
                  itemBuilder: (_, i) {
                    final r = _searchResults[i];
                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      leading: const Icon(Icons.location_on_outlined, color: _greenPrimary, size: 20),
                      title: Text(
                        r.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary),
                      ),
                      subtitle: Text(
                        r.subtitle,
                        style: const TextStyle(fontSize: 12, color: _textSecondary),
                      ),
                      onTap: () => _selectSearchResult(r),
                    );
                  },
                ),
    );
  }

  Widget _buildBottomBar() {
    final canValidate = _points.length >= 3;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.crop_free, color: _greenPrimary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '~${_calculatedAreaHa.toStringAsFixed(2)} ha',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _greenPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _greenPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_points.length} ${_points.length > 1 ? 'points' : 'point'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _greenPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 50,
                height: 42,
                child: OutlinedButton(
                  onPressed: _points.isEmpty ? null : _undoLastPoint,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textPrimary,
                    side: const BorderSide(color: Color(0xFFECEFF1)),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Icon(Icons.undo, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: canValidate ? _validateParcel : null,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text(
                      'Valider le tracé',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _greenPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFCFD8DC),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const _MapButton({required this.icon, required this.onPressed, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: const Color(0xFF1C2B2D), size: 20),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _CircleIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: const Color(0xFF1C2B2D), size: 20),
        ),
      ),
    );
  }
}

class _GeocodingResult {
  final String name;
  final String subtitle;
  final String label;
  final double lat;
  final double lng;

  _GeocodingResult({
    required this.name,
    required this.subtitle,
    required this.label,
    required this.lat,
    required this.lng,
  });

  factory _GeocodingResult.fromJson(Map<String, dynamic> json) {
    final n = json['name']?.toString() ?? '';
    final admin = [json['admin1'], json['admin2'], json['country']]
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toList();
    final sub = admin.join(', ');
    return _GeocodingResult(
      name: n,
      subtitle: sub,
      label: sub.isEmpty ? n : '$n, $sub',
      lat: (json['latitude'] as num).toDouble(),
      lng: (json['longitude'] as num).toDouble(),
    );
  }
}

class _ParcelFormResult {
  final String name;
  final String cultureType;
  _ParcelFormResult(this.name, this.cultureType);
}

class _ParcelFormSheet extends StatefulWidget {
  final double area;
  const _ParcelFormSheet({required this.area});

  @override
  State<_ParcelFormSheet> createState() => _ParcelFormSheetState();
}

class _ParcelFormSheetState extends State<_ParcelFormSheet> {
  final _nameController = TextEditingController();
  String? _cultureType;
  bool _submitted = false;

  static const _cultures = ['Blé tendre', 'Maïs', 'Colza', 'Orge', 'Tournesol', 'Pomme de terre'];
  static const _greenPrimary = Color(0xFF2E7D32);
  static const _textPrimary = Color(0xFF1C2B2D);
  static const _textSecondary = Color(0xFF546E7A);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _submitted = true);
    final name = _nameController.text.trim();
    if (name.isEmpty || _cultureType == null) return;
    Navigator.of(context).pop(_ParcelFormResult(name, _cultureType!));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
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
          const SizedBox(height: 16),
          const Text(
            'Nouvelle parcelle',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Surface estimée : ~${widget.area.toStringAsFixed(2)} ha',
            style: const TextStyle(fontSize: 13, color: _textSecondary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nom de la parcelle',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Ex: Parcelle Nord',
              hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF5F7F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              errorText: _submitted && _nameController.text.trim().isEmpty
                  ? 'Saisissez un nom'
                  : null,
            ),
            onChanged: (_) {
              if (_submitted) setState(() {});
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Type de culture',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _cultureType,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5F7F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              errorText:
                  _submitted && _cultureType == null ? 'Choisissez un type' : null,
            ),
            hint: const Text('Sélectionner', style: TextStyle(color: _textSecondary, fontSize: 14)),
            items: _cultures
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _cultureType = v),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textPrimary,
                      side: const BorderSide(color: Color(0xFFECEFF1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _greenPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Créer', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
