// ─── Models ─────────────────────────────────────────────────────────────────
class TrackingSessionModel {
  final int id;
  final String sessionId;
  final int companyId;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final String status; // browsing | selecting_products | cart | checkout | address_filled | payment_selection | order_created | abandoned
  final String currentStep;
  final int cartItemsCount;
  final double subtotal;
  final double? latitude;
  final double? longitude;
  final String? address;
  final int? orderId;
  final int? orderStatus;
  final String? deviceType;
  final bool isActive;
  final DateTime lastActivityAt;
  final DateTime createdAt;

  TrackingSessionModel({
    required this.id,
    required this.sessionId,
    required this.companyId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.status,
    required this.currentStep,
    required this.cartItemsCount,
    required this.subtotal,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.orderId,
    required this.orderStatus,
    required this.deviceType,
    required this.isActive,
    required this.lastActivityAt,
    required this.createdAt,
  });

  factory TrackingSessionModel.fromJson(Map<String, dynamic> j) {
    DateTime parseDt(dynamic v) {
      if (v is String) return DateTime.tryParse(v)?.toLocal() ?? DateTime.now();
      return DateTime.now();
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return TrackingSessionModel(
      id: parseInt(j['id']) ?? 0,
      sessionId: j['session_id']?.toString() ?? '',
      companyId: parseInt(j['company_id']) ?? 0,
      customerId: parseInt(j['customer_id']),
      customerName: j['customer_name']?.toString(),
      customerPhone: j['customer_phone']?.toString(),
      status: j['status']?.toString() ?? 'browsing',
      currentStep: j['current_step']?.toString() ?? 'menu',
      cartItemsCount: parseInt(j['cart_items_count']) ?? 0,
      subtotal: parseDouble(j['subtotal']) ?? 0,
      latitude: parseDouble(j['latitude']),
      longitude: parseDouble(j['longitude']),
      address: j['address']?.toString(),
      orderId: parseInt(j['order_id']),
      orderStatus: parseInt(j['order_status']),
      deviceType: j['device_type']?.toString(),
      isActive: j['is_active'] == true,
      lastActivityAt: parseDt(j['last_activity_at']),
      createdAt: parseDt(j['created_at']),
    );
  }

  bool get isOrderCreated => status == 'order_created' && orderId != null;
  bool get isAbandoned => status == 'abandoned';
  bool get hasLocation => latitude != null && longitude != null;
}

class TrackingMetricsModel {
  final int browsing;
  final int inCheckout;
  final int completedToday;
  final int abandonedCarts;
  final int activeTotal;
  final double pipelineValue;

  const TrackingMetricsModel({
    required this.browsing,
    required this.inCheckout,
    required this.completedToday,
    required this.abandonedCarts,
    required this.activeTotal,
    required this.pipelineValue,
  });

  factory TrackingMetricsModel.fromJson(Map<String, dynamic> j) {
    double parseD(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }
    int parseI(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return TrackingMetricsModel(
      browsing: parseI(j['browsing']),
      inCheckout: parseI(j['in_checkout']),
      completedToday: parseI(j['completed_today']),
      abandonedCarts: parseI(j['abandoned_carts']),
      activeTotal: parseI(j['active_total']),
      pipelineValue: parseD(j['pipeline_value']),
    );
  }

  static const empty = TrackingMetricsModel(
    browsing: 0,
    inCheckout: 0,
    completedToday: 0,
    abandonedCarts: 0,
    activeTotal: 0,
    pipelineValue: 0,
  );
}
