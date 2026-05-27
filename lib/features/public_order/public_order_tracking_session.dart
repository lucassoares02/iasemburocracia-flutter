part of 'public_order_page.dart';

// ─── Customer Tracking Session ──────────────────────────────────────────────
// Tracker fire-and-forget que reporta o progresso do cliente no funil público
// (cardápio → carrinho → checkout → endereço → pedido) ao painel operacional
// da loja. Falhas são silenciadas — nunca afeta o fluxo do usuário.
class _CustomerTrackingSession {
  final int companyId;
  final String sessionId;

  String _lastStatus = '';
  Timer? _heartbeatTimer;
  static const _kHeartbeat = Duration(seconds: 45);

  _CustomerTrackingSession({required this.companyId}) : sessionId = _makeId() {
    _startHeartbeat();
  }

  static String _makeId() {
    final ms = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final us = (DateTime.now().microsecondsSinceEpoch % 1000000).toRadixString(36);
    return 'cts_${ms}_$us';
  }

  // Mapeia o _Step do front em status canônico do funil.
  static String statusFromStep(_Step step, {int cartCount = 0}) {
    switch (step) {
      case _Step.menu:
        return cartCount > 0 ? 'selecting_products' : 'browsing';
      case _Step.cart:
        return 'cart';
      case _Step.identify:
      case _Step.address:
        return 'checkout';
      case _Step.checkout:
        return 'payment_selection';
      case _Step.success:
      case _Step.tracking:
        return 'order_created';
      case _Step.history:
      case _Step.loading:
      case _Step.error:
        return 'browsing';
    }
  }

  static String stepName(_Step step) {
    switch (step) {
      case _Step.menu:
        return 'menu';
      case _Step.cart:
        return 'cart';
      case _Step.identify:
        return 'identify';
      case _Step.address:
        return 'address';
      case _Step.checkout:
        return 'checkout';
      case _Step.success:
        return 'success';
      case _Step.tracking:
        return 'tracking';
      case _Step.history:
        return 'history';
      case _Step.loading:
      case _Step.error:
        return 'menu';
    }
  }

  // ── Upsert principal — chamado a cada mudança de estado relevante ──────────
  void sync({
    required _Step step,
    required int cartItemsCount,
    required double subtotal,
    String? customerName,
    String? customerPhone,
    int? customerId,
    double? latitude,
    double? longitude,
    String? address,
    int? orderId,
  }) {
    final status = statusFromStep(step, cartCount: cartItemsCount);
    final payload = <String, dynamic>{
      'company_id': companyId,
      'session_id': sessionId,
      'status': status,
      'current_step': stepName(step),
      'cart_items_count': cartItemsCount,
      'subtotal': subtotal,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null && customerName.isNotEmpty) 'customer_name': customerName,
      if (customerPhone != null && customerPhone.isNotEmpty) 'customer_phone': customerPhone,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (address != null && address.isNotEmpty) 'address': address,
      if (orderId != null) 'order_id': orderId,
      'device_type': 'web',
    };

    // Dispara evento de funil quando há mudança de status (somente uma vez por transição).
    if (status != _lastStatus) {
      _lastStatus = status;
      _fireEvent('status_change', step, extra: {'new_status': status});
    }

    PublicHttpService()
        .post('public/customer-tracking/session', payload)
        .ignore();
  }

  // ── Atualiza coordenadas (chamado quando o cliente preenche o endereço) ────
  void updateLocation({
    required double latitude,
    required double longitude,
    required String address,
  }) {
    PublicHttpService().post('public/customer-tracking/location', {
      'company_id': companyId,
      'session_id': sessionId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    }).ignore();
    _fireEvent('address_filled', _Step.address);
  }

  // ── Marca a sessão como pedido criado ──────────────────────────────────────
  void attachOrder(int orderId) {
    _lastStatus = 'order_created';
    PublicHttpService().post('public/customer-tracking/order', {
      'company_id': companyId,
      'session_id': sessionId,
      'order_id': orderId,
    }).ignore();
    _fireEvent('order_created', _Step.success, extra: {'order_id': orderId});
  }

  // ── Eventos discretos do funil (entrou no cardápio, adicionou produto, etc) ─
  void track(String eventType, _Step step, {Map<String, dynamic>? extra}) {
    _fireEvent(eventType, step, extra: extra);
  }

  void _fireEvent(String type, _Step step, {Map<String, dynamic>? extra}) {
    PublicHttpService().post('public/customer-tracking/event', {
      'company_id': companyId,
      'session_id': sessionId,
      'event_type': type,
      'step': stepName(step),
      if (extra != null) 'payload': extra,
    }).ignore();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_kHeartbeat, (_) {
      // Heartbeat leve mantém a sessão "ativa" sem dados novos.
      PublicHttpService().post('public/customer-tracking/event', {
        'company_id': companyId,
        'session_id': sessionId,
        'event_type': 'heartbeat',
      }).ignore();
    });
  }

  void dispose() {
    _heartbeatTimer?.cancel();
  }
}
