import 'package:portal_assoc/core/services/public_http_service.dart';
import 'package:portal_assoc/core/services/response_model.dart';
import 'package:portal_assoc/features/marketplace/marketplace_model.dart';

class MarketplaceRepository {
  final _http = PublicHttpService();

  // Cache em memória: evita refetch ao navegar de volta para /order dentro da
  // mesma sessão (os dados mudam pouco; o pull-to-refresh força atualização).
  static MarketplaceData? _cache;
  static DateTime? _cachedAt;
  static const _cacheTtl = Duration(minutes: 2);

  Future<ResponseModel> fetch({bool force = false}) async {
    final cached = _cache;
    if (!force && cached != null && _cachedAt != null && DateTime.now().difference(_cachedAt!) < _cacheTtl) {
      return ResponseModel(success: true, message: 'OK', data: cached);
    }
    final res = await _http.get('public/restaurants');
    if (res.success && res.data is Map) {
      final data = MarketplaceData.fromJson(Map<String, dynamic>.from(res.data as Map));
      _cache = data;
      _cachedAt = DateTime.now();
      res.data = data;
    }
    return res;
  }
}
