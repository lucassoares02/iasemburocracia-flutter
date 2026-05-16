import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:portal_assoc/core/services/response_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HttpService {
  final Dio _dio = Dio();
  // final String baseUrl = (Uri.base.origin.contains('localhost') ? 'http://localhost:3003/api/' : 'https://pa-m9vo.onrender.com/api/');
  final String baseUrl = (Uri.base.origin.contains('localhost') ? 'http://localhost:3003/api/' : 'https://api.iasemburocracia.com.br/api/');
  // final String baseUrl = 'https://backend-automatizai.onrender.com/api/';

  HttpService() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');

          options.headers['Content-Type'] = 'application/json';
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options); // continue
        },
      ),
    );
  }

  Future<ResponseModel> get(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      // log('Endpoint: $endpoint === Response: $response');
      return ResponseModel(
        success: true,
        message: 'Request successful',
        data: response.data,
      );
    } catch (e) {
      return ResponseModel(
        success: false,
        message: 'Request failed: $e',
      );
    }
  }

  Future<ResponseModel> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      // log('Response: $response');
      return ResponseModel(
        success: true,
        message: 'Request successful',
        data: response.data,
      );
    } catch (e) {
      log("Error post: $e");
      return ResponseModel(
        success: false,
        message: 'Request failed: $e',
      );
    }
  }

  Future<ResponseModel> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      // log('Response: $response');
      return ResponseModel(
        success: true,
        message: 'Request successful',
        data: response.data,
      );
    } catch (e) {
      return ResponseModel(
        success: false,
        message: 'Request failed: $e',
      );
    }
  }

  Future<ResponseModel> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      // log('Response: $response');
      return ResponseModel(
        success: true,
        message: 'Request successful',
        data: response.data,
      );
    } catch (e) {
      return ResponseModel(
        success: false,
        message: 'Request failed: $e',
      );
    }
  }

  Future<ResponseModel> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(endpoint, data: data);
      // log('Response: $response');
      return ResponseModel(
        success: true,
        message: 'Request successful',
        data: response.data,
      );
    } catch (e) {
      return ResponseModel(
        success: false,
        message: 'Request failed: $e',
      );
    }
  }
}
