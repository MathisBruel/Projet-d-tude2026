import 'package:google_maps_flutter/google_maps_flutter.dart';

class ParcelModel {
  final String id;
  final String name;
  final String cultureType;
  final double areaHa;
  final String? region;
  final List<Map<String, double>> coordinates;
  final DateTime createdAt;
  final DateTime updatedAt;

  ParcelModel({
    required this.id,
    required this.name,
    required this.cultureType,
    required this.areaHa,
    this.region,
    required this.coordinates,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ParcelModel.fromJson(Map<String, dynamic> json) {
    final rawCoords = json['coordinates'] as List<dynamic>? ?? [];
    final coords = rawCoords.map<Map<String, double>>((c) {
      final map = c as Map<String, dynamic>;
      return {
        'lat': (map['lat'] as num).toDouble(),
        'lng': (map['lng'] as num).toDouble(),
      };
    }).toList();

    return ParcelModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      cultureType: json['culture_type'] as String? ?? 'Inconnu',
      areaHa: (json['area_ha'] as num?)?.toDouble() ?? 0.0,
      region: json['region'] as String?,
      coordinates: coords,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'culture_type': cultureType,
      'area_ha': areaHa,
      'region': region,
      'coordinates': coordinates,
    };
  }

  List<LatLng> toLatLngList() {
    return coordinates
        .map((c) => LatLng(c['lat']!, c['lng']!))
        .toList();
  }
}
