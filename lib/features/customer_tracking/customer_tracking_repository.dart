import 'package:portal_assoc/core/services/http_service.dart';
import 'package:portal_assoc/core/services/response_model.dart';
import 'package:portal_assoc/features/customer_tracking/customer_tracking_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerTrackingRepository {
  final _http = HttpService();

  Future<int> _companyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('company') ?? 0;
  }

  Future<ResponseModel> listSessions() async {
    final id = await _companyId();
    final res = await _http.get('customer-tracking/company/$id/sessions');
    if (res.success && res.data is List) {
      res.data = (res.data as List)
          .whereType<Map>()
          .map((e) => TrackingSessionModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    return res;
  }

  Future<ResponseModel> listMapPoints() async {
    final id = await _companyId();
    final res = await _http.get('customer-tracking/company/$id/map');
    if (res.success && res.data is List) {
      res.data = (res.data as List)
          .whereType<Map>()
          .map((e) => TrackingSessionModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    return res;
  }

  Future<ResponseModel> getMetrics() async {
    final id = await _companyId();
    final res = await _http.get('customer-tracking/company/$id/metrics');
    if (res.success && res.data is Map) {
      res.data = TrackingMetricsModel.fromJson(
        (res.data as Map).cast<String, dynamic>(),
      );
    }
    return res;
  }
}
