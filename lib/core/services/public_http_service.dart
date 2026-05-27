import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:portal_assoc/core/services/response_model.dart';

class PublicHttpService {
  final Dio _dio = Dio();
  final String baseUrl = (Uri.base.origin.contains('localhost')
      ? 'http://localhost:3003/api/'
      : 'https://api.iasemburocracia.com.br/api/');

  PublicHttpService() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.headers['Content-Type'] = 'application/json';
        return handler.next(options);
      },
    ));
  }

  Future<ResponseModel> get(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      return ResponseModel(success: true, message: 'OK', data: response.data);
    } catch (e) {
      return ResponseModel(success: false, message: 'Request failed: $e');
    }
  }

  Future<ResponseModel> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return ResponseModel(success: true, message: 'OK', data: response.data);
    } catch (e) {
      log('PublicHttpService.post $endpoint error: $e');
      return ResponseModel(success: false, message: 'Request failed: $e');
    }
  }

  Future<ResponseModel> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(endpoint, data: data);
      return ResponseModel(success: true, message: 'OK', data: response.data);
    } catch (e) {
      return ResponseModel(success: false, message: 'Request failed: $e');
    }
  }
}
