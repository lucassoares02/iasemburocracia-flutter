import 'dart:developer';
import 'dart:typed_data';

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

  Future<ResponseModel> uploadFile(
    String endpoint,
    Uint8List bytes,
    String filename,
    String mimeType,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final parts = mimeType.split('/');
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType(parts[0], parts.length > 1 ? parts[1] : 'octet-stream'),
        ),
      });

      // Usa instância separada para não conflitar com o header Content-Type: application/json
      final uploadDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ));

      final response = await uploadDio.post(endpoint, data: formData);
      return ResponseModel(
        success: true,
        message: 'Upload successful',
        data: response.data,
      );
    } on DioException catch (e) {
      // Mensagens amigáveis — nunca expor stacktrace/erro técnico ao usuário.
      log('uploadFile error: $e');
      final status = e.response?.statusCode ?? 0;
      final message = status == 413
          ? 'A imagem enviada excede o tamanho permitido.'
          : 'Falha no upload da imagem. Verifique sua conexão e tente novamente.';
      return ResponseModel(success: false, message: message);
    } catch (e) {
      log('uploadFile error: $e');
      return ResponseModel(
        success: false,
        message: 'Falha no upload da imagem. Tente novamente.',
      );
    }
  }
}
