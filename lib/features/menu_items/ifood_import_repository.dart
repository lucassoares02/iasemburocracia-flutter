import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resultado bruto da API de importação iFood. Preserva o status e o corpo
/// (inclusive em erros) para que a UI possa mapear mensagens específicas.
class IfoodResult {
  final bool ok;
  final int? statusCode;
  final Map<String, dynamic> body;

  IfoodResult({required this.ok, this.statusCode, required this.body});

  String? get errorCode => body['error']?.toString();
}

class IfoodImportRepository {
  final Dio _dio = Dio();

  IfoodImportRepository() {
    _dio.options.baseUrl = Uri.base.origin.contains('localhost') ? 'http://localhost:3003/api/' : 'https://api.iasemburocracia.com.br/api/';
    // run-sync da Apify pode demorar; timeouts generosos.
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 220);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    _dio.options.validateStatus = (_) => true; // não lançar em 4xx/5xx
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          options.headers['Content-Type'] = 'application/json';
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
      ),
    );
  }

  Future<IfoodResult> preview(String restaurantUrl) async {
    try {
      final r = await _dio.post('ifood/import-preview', data: {'restaurantUrl': restaurantUrl});
      return IfoodResult(ok: (r.statusCode ?? 500) < 300, statusCode: r.statusCode, body: _asMap(r.data));
    } catch (e) {
      return IfoodResult(ok: false, body: {'error': 'NETWORK', 'message': '$e'});
    }
  }

  Future<IfoodResult> import({
    required int companyId,
    required List<Map<String, dynamic>> items,
    required String conflictStrategy, // 'ignore' | 'update'
  }) async {
    try {
      final r = await _dio.post('ifood/import', data: {
        'companyId': companyId,
        'items': items,
        'conflictStrategy': conflictStrategy,
      });
      return IfoodResult(ok: (r.statusCode ?? 500) < 300, statusCode: r.statusCode, body: _asMap(r.data));
    } catch (e) {
      return IfoodResult(ok: false, body: {'error': 'NETWORK', 'message': '$e'});
    }
  }

  Map<String, dynamic> _asMap(dynamic d) => d is Map<String, dynamic> ? d : <String, dynamic>{};
}
