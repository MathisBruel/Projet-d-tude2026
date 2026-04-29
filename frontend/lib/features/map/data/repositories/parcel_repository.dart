import '../../../../core/services/api_service.dart';
import '../models/parcel_model.dart';

class ParcelRepository {
  static Future<List<ParcelModel>> getParcels() async {
    final response = await ApiService.getParcels();

    if (response.containsKey('error')) {
      throw Exception(response['error']);
    }

    final parcelsData = response['parcels'] as List<dynamic>? ??
        response['data'] as List<dynamic>? ??
        [];

    return parcelsData
        .map((json) => ParcelModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<ParcelModel> createParcel({
    required String name,
    required String cultureType,
    required List<Map<String, double>> coordinates,
  }) async {
    final response = await ApiService.createParcel({
      'name': name,
      'culture_type': cultureType,
      'coordinates': coordinates,
    });

    if (response.containsKey('error')) {
      throw Exception(response['error']);
    }

    final parcelData = response['parcel'] as Map<String, dynamic>? ??
        response['data'] as Map<String, dynamic>? ??
        response;

    return ParcelModel.fromJson(parcelData);
  }

  static Future<void> deleteParcel(String parcelId) async {
    final response = await ApiService.deleteParcel(parcelId);

    if (response.containsKey('error')) {
      throw Exception(response['error']);
    }
  }

  static Future<ParcelModel> updateParcel(
    String parcelId,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiService.updateParcel(parcelId, data);

    if (response.containsKey('error')) {
      throw Exception(response['error']);
    }

    final parcelData = response['parcel'] as Map<String, dynamic>? ??
        response['data'] as Map<String, dynamic>? ??
        response;

    return ParcelModel.fromJson(parcelData);
  }
}
