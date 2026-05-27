import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/http_service.dart';
import '../../core/services/response_model.dart';
import 'address_model.dart';

class AddressRepository {
  final _http = HttpService();

  Future<ResponseModel> autocomplete(String input, {String? sessionToken}) async {
    try {
      final params = <String, String>{'input': input};
      if (sessionToken != null) params['sessionToken'] = sessionToken;
      final response = await _http.get(
        'address/autocomplete?input=${Uri.encodeComponent(input)}${sessionToken != null ? '&sessionToken=$sessionToken' : ''}',
      );
      final list = response.data as List;
      response.data = list.map((e) => PlaceSuggestion.fromJson(e)).toList();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> details(String placeId, {String? sessionToken}) async {
    try {
      final query = sessionToken != null ? '?sessionToken=$sessionToken' : '';
      final response = await _http.get('address/details/$placeId$query');
      response.data = PlaceDetails.fromJson(response.data as Map<String, dynamic>);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> findAll() async {
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getInt('company') ?? 0;
    try {
      final response = await _http.get('address/company/$companyId');
      final list = response.data as List;
      response.data = list.map((e) => AddressModel.fromJson(e)).toList();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> create(AddressModel data) async {
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getInt('company') ?? 0;
    data.companyId = companyId;
    try {
      return await _http.post('address', data.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> delete(int id) async {
    try {
      return await _http.delete('address/$id');
    } catch (e) {
      rethrow;
    }
  }
}
