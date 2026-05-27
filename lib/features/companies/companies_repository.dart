import 'dart:typed_data';

import 'package:portal_assoc/features/companies/models/business_address_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/response_model.dart';
import '../../core/services/http_service.dart';
import 'companies_model.dart';

class CompaniesRepository {
  final httpService = HttpService();

  Future<ResponseModel> find() async {
    try {
      ResponseModel response = await httpService.get("companies");
      final list = response.data[0];
      final item = CompaniesModel.fromJson(list);
      response.data = item;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> findBusinessAddress() async {
    final prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt('company') ?? 0;
    try {
      ResponseModel response = await httpService.get("company/address/$id");
      final list = response.data;
      final item = BusinessAddressModel.fromJson(list);
      response.data = item;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> findAll() async {
    try {
      ResponseModel response = await httpService.get("companiessss");
      List list = response.data as List;
      final item = list.map((e) => CompaniesModel.fromJson(e)).toList();
      response.data = item;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> create(CompaniesModel data) async {
    try {
      ResponseModel response = await httpService.post("companiessss", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> update(CompaniesModel data) async {
    try {
      ResponseModel response = await httpService.patch("companiessss", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> addressAutocomplete(String input, {String? sessionToken}) async {
    try {
      final q = 'address/autocomplete?input=${Uri.encodeComponent(input)}'
          '${sessionToken != null ? '&sessionToken=$sessionToken' : ''}';
      final response = await httpService.get(q);
      final list = response.data as List;
      response.data = list.map((e) => PlaceSuggestion.fromJson(e)).toList();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> addressDetails(String placeId, {String? sessionToken}) async {
    try {
      final q = 'address/details/$placeId'
          '${sessionToken != null ? '?sessionToken=$sessionToken' : ''}';
      final response = await httpService.get(q);
      response.data = PlaceDetails.fromJson(response.data as Map<String, dynamic>);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> updateBusiness(BusinessAddressModel data) async {
    try {
      ResponseModel response = await httpService.patch("company/address", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> uploadCompanyImage(
    Uint8List bytes,
    String filename,
    String mimeType, {
    String type = 'logo',
  }) async {
    try {
      return await httpService.uploadFile(
        "companiessss/upload-image?type=$type",
        bytes,
        filename,
        mimeType,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> delete(int id) async {
    try {
      ResponseModel response = await httpService.delete("companiessss/$id");
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
