import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:portal_assoc/core/services/public_http_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:portal_assoc/features/orders/order_message_model.dart';
import 'package:portal_assoc/features/public_order/public_order_entity.dart';
import 'package:portal_assoc/features/public_order/public_order_model.dart';
import 'package:portal_assoc/features/public_order/public_order_repository.dart';
import 'package:portal_assoc/features/public_order/public_order_usecase.dart';
import 'package:portal_assoc/features/product_options/product_options_entity.dart';
import 'package:portal_assoc/features/product_options/product_options_model.dart';
import 'package:portal_assoc/features/product_options/product_options_repository.dart';
import 'package:portal_assoc/features/purchase_goals/purchase_goal_model.dart';
import 'package:portal_assoc/features/purchase_goals/purchase_goal_repository.dart';
import 'package:portal_assoc/shared/widgets/google_map_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'public_order_goal_suggestion.dart';
part 'public_order_cart.dart';
part 'public_order_checkout.dart';
part 'public_order_menu.dart';
part 'public_order_search_analytics.dart';
part 'public_order_success.dart';
part 'public_order_chat.dart';
part 'public_order_tracking.dart';
part 'public_order_history.dart';
part 'public_order_reorder.dart';
part 'public_order_tracking_session.dart';
part 'public_order_delivery_type.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _DS {
  static const ink = Color(0xFF1C1C1E);
  static const brandBlue = Color(0xFF4262FF);
  static const canvas = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF7F8FA);
  static const hairline = Color(0xFFE0E2E8);
  static const hairlineSoft = Color(0xFFEEF0F3);
  static const slate = Color(0xFF555A6A);
  static const steel = Color(0xFF6B6F7E);
  static const stone = Color(0xFF8E91A0);
  static const muted = Color(0xFFA5A8B5);
  static const danger = Color(0xFFE53935);
  static const successAccent = Color(0xFF00B473);
  static const rXl = 16.0;
  static const rLg = 12.0;
  static const rFull = 9999.0;
}

// ─── Premium overrides (escopo: public_order) ─────────────────────────────────
class _DSx {
  static const pageBg = Color(0xFFF8F9FA);
  static const cardBg = Color(0xFFFFFFFF);
  static const yellowSoftBg = Color(0xFFFFF4C4);
  static const yellowSoftFg = Color(0xFF7A6315);
  static const rCard = 16.0;

  static const String _font = 'PlusJakartaSans';

  static List<BoxShadow> get shadowSoft => const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get shadowFloating => const [
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 28,
          offset: Offset(0, 14),
        ),
      ];

  static TextStyle text({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = _DS.ink,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return TextStyle(
      fontFamily: _font,
      fontFamilyFallback: const ['Inter', 'sans-serif'],
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

}

final _currFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

Color _parseBrandColor(String? hex) {
  if (hex == null || hex.isEmpty) return _DS.ink;
  final h = hex.replaceAll('#', '').trim();
  if (h.length != 6) return _DS.ink;
  try {
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return _DS.ink;
  }
}

// ─── Scheduling helpers ───────────────────────────────────────────────────────

(int, int)? _parseHM(String? s) {
  if (s == null || s.isEmpty) return null;
  final parts = s.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return (h, m);
}

/// Generates 30-minute scheduling slots from `opening_hours` for the next 7 days.
/// `weekday` in opening_hours follows the frontend convention 1=Mon..7=Sun
/// (matches `DateTime.weekday`).
List<DateTime> _scheduleSlots(List<PublicOpeningHourModel> hours, DateTime now) {
  final result = <DateTime>[];
  for (var offset = 0; offset < 7; offset++) {
    final day = DateTime(now.year, now.month, now.day).add(Duration(days: offset));
    final wd = day.weekday; // 1..7 Mon..Sun

    PublicOpeningHourModel? dayHours;
    for (final h in hours) {
      if (h.weekday == wd && !h.isClosed && (h.opensAt ?? '').isNotEmpty && (h.closesAt ?? '').isNotEmpty) {
        dayHours = h;
        break;
      }
    }
    if (dayHours == null) continue;

    final openTime = _parseHM(dayHours.opensAt);
    final closeTime = _parseHM(dayHours.closesAt);
    if (openTime == null || closeTime == null) continue;

    var cursor = DateTime(day.year, day.month, day.day, openTime.$1, openTime.$2);
    final end = DateTime(day.year, day.month, day.day, closeTime.$1, closeTime.$2);

    // For today, skip slots that are less than 30 min from now.
    if (offset == 0) {
      final earliest = now.add(const Duration(minutes: 30));
      if (cursor.isBefore(earliest)) {
        // round up to next 30-min boundary >= earliest
        final remainder = earliest.minute % 30;
        final addMin = remainder == 0 ? 0 : (30 - remainder);
        cursor = DateTime(
          earliest.year,
          earliest.month,
          earliest.day,
          earliest.hour,
          earliest.minute,
        ).add(Duration(minutes: addMin));
      }
    }

    while (cursor.isBefore(end)) {
      result.add(cursor);
      cursor = cursor.add(const Duration(minutes: 30));
    }
  }
  return result;
}

DateTime? _firstAvailableSlot(List<PublicOpeningHourModel> hours, DateTime now) {
  final slots = _scheduleSlots(hours, now);
  return slots.isEmpty ? null : slots.first;
}

const _kDayShort = {
  1: 'Seg',
  2: 'Ter',
  3: 'Qua',
  4: 'Qui',
  5: 'Sex',
  6: 'Sáb',
  7: 'Dom',
};

const _kDayFull = {
  1: 'Segunda',
  2: 'Terça',
  3: 'Quarta',
  4: 'Quinta',
  5: 'Sexta',
  6: 'Sábado',
  7: 'Domingo',
};

String _scheduleLabel(DateTime dt, {bool full = false}) {
  final today = DateTime.now();
  final isToday = dt.year == today.year && dt.month == today.month && dt.day == today.day;
  final tomorrow = today.add(const Duration(days: 1));
  final isTomorrow = dt.year == tomorrow.year && dt.month == tomorrow.month && dt.day == tomorrow.day;

  String prefix;
  if (isToday) {
    prefix = 'Hoje';
  } else if (isTomorrow) {
    prefix = 'Amanhã';
  } else {
    prefix = full ? '${_kDayFull[dt.weekday]}, ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}' : '${_kDayShort[dt.weekday]} ${dt.day.toString().padLeft(2, '0')}';
  }
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$prefix · $hh:$mm';
}

// ─── Cart item ────────────────────────────────────────────────────────────────

/// Snapshot of one selected option in the cart. Mirrors the row that the
/// backend persists in `order_item_options`.
class _PubCartOption {
  final int? groupId;
  final String groupName;
  final int? optionId;
  final String optionName;
  final double additionalPrice;
  final int quantity;

  _PubCartOption({
    this.groupId,
    required this.groupName,
    this.optionId,
    required this.optionName,
    this.additionalPrice = 0,
    this.quantity = 1,
  });

  double get total => additionalPrice * quantity;

  Map<String, dynamic> toStorageJson() => {
        'group_id': groupId,
        'group_name': groupName,
        'option_id': optionId,
        'option_name': optionName,
        'additional_price': additionalPrice,
        'quantity': quantity,
      };

  factory _PubCartOption.fromJson(Map<String, dynamic> j) => _PubCartOption(
        groupId: j['group_id'] as int?,
        groupName: (j['group_name'] ?? '').toString(),
        optionId: j['option_id'] as int?,
        optionName: (j['option_name'] ?? '').toString(),
        additionalPrice: (j['additional_price'] as num?)?.toDouble() ?? 0,
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      );
}

class _PubCartItem {
  final int? menuItemId;
  final int? promotionId;
  final String? promotionGroupKey;
  final String name;
  final double unitPrice;
  int quantity;
  String? notes;
  final String? imageUrl;
  final List<Map<String, dynamic>> promotionItems;
  final int? upsellRuleId;
  final double? originalPrice;
  final List<_PubCartOption> options;
  final String? optionsHash;
  final int? purchaseGoalId;
  final double? goalDiscountPercentage;

  _PubCartItem({
    this.menuItemId,
    this.promotionId,
    this.promotionGroupKey,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.notes,
    this.imageUrl,
    this.promotionItems = const [],
    this.upsellRuleId,
    this.originalPrice,
    this.options = const [],
    this.optionsHash,
    this.purchaseGoalId,
    this.goalDiscountPercentage,
  });

  double get subtotal => unitPrice * quantity;
  String get cartKey {
    if (promotionId != null) return 'promo_$promotionId';
    final h = optionsHash ?? '';
    return h.isEmpty ? 'item_$menuItemId' : 'item_${menuItemId}_$h';
  }

  Map<String, dynamic> toStorageJson() => {
        'menu_item_id': menuItemId,
        'promotion_id': promotionId,
        'promotion_group_key': promotionGroupKey,
        'name': name,
        'unit_price': unitPrice,
        'quantity': quantity,
        'notes': notes,
        'image_url': imageUrl,
        'promotion_items': promotionItems,
        'upsell_rule_id': upsellRuleId,
        'original_price': originalPrice,
        'options': options.map((o) => o.toStorageJson()).toList(),
        'options_hash': optionsHash,
        'purchase_goal_id': purchaseGoalId,
        'goal_discount_percentage': goalDiscountPercentage,
      };

  Map<String, dynamic> toOrderItem() => {
        'menu_item_id': menuItemId,
        'promotion_id': promotionId,
        'promotion_group_key': promotionGroupKey,
        'name': name,
        'unit_price': unitPrice,
        'quantity': quantity,
        'subtotal': subtotal,
        'notes': notes,
        'upsell_rule_id': upsellRuleId,
        'original_price': originalPrice,
        if (options.isNotEmpty) 'options': _groupOptionsForServer(),
        if (purchaseGoalId != null) 'purchase_goal_id': purchaseGoalId,
        if (goalDiscountPercentage != null) 'goal_discount_percentage': goalDiscountPercentage,
      };

  // Server expects: [{ group_id, options: [{ option_id, quantity }] }]
  List<Map<String, dynamic>> _groupOptionsForServer() {
    final map = <int, Map<String, dynamic>>{};
    for (final o in options) {
      final gid = o.groupId ?? 0;
      final entry = map.putIfAbsent(
          gid,
          () => {
                'group_id': o.groupId,
                'options': <Map<String, dynamic>>[],
              });
      (entry['options'] as List).add({
        'option_id': o.optionId,
        'quantity': o.quantity,
      });
    }
    return map.values.toList();
  }

  factory _PubCartItem.fromJson(Map<String, dynamic> j) => _PubCartItem(
        menuItemId: j['menu_item_id'] as int?,
        promotionId: j['promotion_id'] as int?,
        promotionGroupKey: j['promotion_group_key'] as String?,
        name: j['name'] as String,
        unitPrice: (j['unit_price'] as num).toDouble(),
        quantity: j['quantity'] as int,
        notes: j['notes'] as String?,
        imageUrl: j['image_url'] as String?,
        promotionItems: ((j['promotion_items'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        upsellRuleId: j['upsell_rule_id'] as int?,
        originalPrice: j['original_price'] != null ? (j['original_price'] as num).toDouble() : null,
        options: ((j['options'] as List?) ?? []).map((e) => _PubCartOption.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        optionsHash: j['options_hash'] as String?,
        purchaseGoalId: j['purchase_goal_id'] as int?,
        goalDiscountPercentage: j['goal_discount_percentage'] != null ? (j['goal_discount_percentage'] as num).toDouble() : null,
      );
}

// ─── Delivery type ───────────────────────────────────────────────────────────
enum _DeliveryType { delivery, pickup }

String _deliveryTypeToApi(_DeliveryType t) =>
    t == _DeliveryType.pickup ? 'pickup' : 'delivery';

// ─── Step enum ────────────────────────────────────────────────────────────────
enum _Step {
  loading,
  error,
  menu,
  cart,
  identify,
  address,
  checkout,
  success,
  tracking,
  history,
}

// ─── Status mapping (matches admin orders_page) ──────────────────────────────
class _OrderStatusInfo {
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;
  const _OrderStatusInfo({
    required this.label,
    required this.bg,
    required this.fg,
    required this.icon,
  });
}

const Map<int, _OrderStatusInfo> _kOrderStatus = {
  1: _OrderStatusInfo(
    label: 'Aguardando',
    bg: Color(0xFFEEF3FF),
    fg: Color(0xFF4262FF),
    icon: Icons.hourglass_top_rounded,
  ),
  2: _OrderStatusInfo(
    label: 'Confirmado',
    bg: Color(0xFFEDE9FE),
    fg: Color(0xFF6D28D9),
    icon: Icons.thumb_up_alt_rounded,
  ),
  3: _OrderStatusInfo(
    label: 'Em preparo',
    bg: Color(0xFFFFF4C4),
    fg: Color(0xFF946C0A),
    icon: Icons.soup_kitchen_rounded,
  ),
  4: _OrderStatusInfo(
    label: 'Em entrega',
    bg: Color(0xFFFEF3C7),
    fg: Color(0xFFB45309),
    icon: Icons.two_wheeler_rounded,
  ),
  5: _OrderStatusInfo(
    label: 'Entregue',
    bg: Color(0xFFD1FAE5),
    fg: Color(0xFF065F46),
    icon: Icons.celebration_rounded,
  ),
  6: _OrderStatusInfo(
    label: 'Cancelado',
    bg: Color(0xFFFFEBEA),
    fg: Color(0xFFE53935),
    icon: Icons.cancel_rounded,
  ),
  7: _OrderStatusInfo(
    label: 'Rejeitado',
    bg: Color(0xFFFEE2E2),
    fg: Color(0xFF991B1B),
    icon: Icons.do_disturb_alt_rounded,
  ),
  8: _OrderStatusInfo(
    label: 'Pronto p/ retirada',
    bg: Color(0xFFCCFBF1),
    fg: Color(0xFF187574),
    icon: Icons.takeout_dining_rounded,
  ),
  9: _OrderStatusInfo(
    label: 'Retirado',
    bg: Color(0xFFDCFCE7),
    fg: Color(0xFF166534),
    icon: Icons.local_mall_rounded,
  ),
};

_OrderStatusInfo _statusInfo(int s) =>
    _kOrderStatus[s] ??
    const _OrderStatusInfo(
      label: 'Status',
      bg: _DS.surface,
      fg: _DS.slate,
      icon: Icons.help_outline_rounded,
    );

final _orderDateFmt = DateFormat('dd/MM/yyyy · HH:mm', 'pt_BR');

// Status terminais — pedido encerrado (sucesso ou falha). Polling para nessas situações.
const Set<int> _kTerminalStatuses = {5, 6, 7, 9};

// ─── Page ─────────────────────────────────────────────────────────────────────
class PublicOrderPage extends StatefulWidget {
  final String? company;
  final String? phone;
  const PublicOrderPage({super.key, this.company, this.phone});

  @override
  State<PublicOrderPage> createState() => _PublicOrderPageState();
}

class _PublicOrderPageState extends State<PublicOrderPage> {
  final _useCase = PublicOrderUseCase(PublicOrderRepository());
  final _publicHttp = PublicHttpService();

  int _companyId = 0;
  _Step _step = _Step.loading;
  String? _loadError;

  PublicCompanyPageModel? _companyData;
  PublicClientModel? _customer;
  List<_PubCartItem> _cart = [];
  int? _createdOrderId;
  bool _placingOrder = false;
  String? _orderError;
  int? _selectedPaymentMethodId;
  double _deliveryFee = 0;
  String? _deliveryDistanceLabel;
  String? _deliveryDurationText;
  bool _isFreeDelivery = false;
  String? _deliveryRuleError;
  bool _loadingDeliveryFee = false;
  double? _destinationLat;
  double? _destinationLng;
  double? _minOrderValue;

  // Scheduling state
  bool _useScheduling = false;
  DateTime? _scheduledFor;
  DateTime? _placedScheduledFor; // snapshot at place-order time (for success screen)

  // Tracking & history state
  PublicOrderDetailModel? _trackedOrder;
  List<PublicOrderDetailModel> _orderHistory = const [];
  bool _loadingTracking = false;
  bool _loadingHistory = false;
  String? _trackingError;
  String? _historyError;
  _Step _previousStepBeforeTracking = _Step.menu;
  Timer? _trackingPollTimer;
  static const _kTrackingPollInterval = Duration(seconds: 12);

  // Keys for SharedPreferences
  String get _cartKey => 'pub_cart_$_companyId';
  String get _sessionKey => 'pub_customer_$_companyId';
  String get _activeOrderKey => 'pub_active_order_$_companyId';

  // Pedido ativo (em andamento) para exibir banner no menu
  PublicOrderDetailModel? _activeOrder;

  // Customer tracking session — fire-and-forget para painel operacional da loja.
  _CustomerTrackingSession? _tracking;

  // Tipo de entrega escolhido — começa sempre como Entrega a cada visita.
  _DeliveryType _deliveryType = _DeliveryType.delivery;
  bool get _isPickup => _deliveryType == _DeliveryType.pickup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _tracking?.dispose();
    _trackingPollTimer?.cancel();
    _trackingPollTimer = null;
    super.dispose();
  }

  // ── Tracking helpers ─────────────────────────────────────────────────────────
  void _syncTracking({_Step? overrideStep, int? orderId}) {
    final t = _tracking;
    if (t == null) return;
    final cartCount = _cart.fold<int>(0, (s, c) => s + c.quantity);
    final subtotal = _cart.fold<double>(0, (s, c) => s + c.subtotal);
    t.sync(
      step: overrideStep ?? _step,
      cartItemsCount: cartCount,
      subtotal: subtotal,
      customerId: _customer?.id,
      customerName: _customer?.name,
      customerPhone: _customer?.phone,
      latitude: _destinationLat,
      longitude: _destinationLng,
      address: _customer?.hasAddress == true ? _customer!.toDeliveryAddress() : null,
      orderId: orderId,
    );
  }

  // ─── Initialization ────────────────────────────────────────────────────────

  Future<void> _init() async {
    final id = int.tryParse(widget.company ?? '');
    if (id == null) {
      setState(() {
        _loadError = 'Link inválido: parâmetro company ausente.';
        _step = _Step.error;
      });
      return;
    }
    _companyId = id;

    await _restoreCart();

    final res = await _useCase.getCompanyMenu(_companyId);
    if (!mounted) return;
    if (!res.success || res.data is! PublicCompanyPageModel) {
      setState(() {
        _loadError = 'Empresa não encontrada ou indisponível.';
        _step = _Step.error;
      });
      return;
    }
    _companyData = res.data as PublicCompanyPageModel;
    _selectedPaymentMethodId = null;
    _minOrderValue = _companyData?.companyPreferences?.minPriceOrder;

    await _restoreCustomer(widget.phone);

    // If the restaurant is closed, default to scheduling mode with the
    // earliest available slot already picked.
    if (!_companyData!.isOpen) {
      final firstSlot = _firstAvailableSlot(_companyData!.openingHours, DateTime.now());
      _useScheduling = true;
      _scheduledFor = firstSlot;
    }

    if (mounted) setState(() => _step = _Step.menu);
    _tracking = _CustomerTrackingSession(companyId: _companyId);
    _tracking!.track('menu_opened', _Step.menu);
    _syncTracking();
    _checkActiveOrder();
  }

  void _setDeliveryType(_DeliveryType t) {
    if (_deliveryType == t) return;
    setState(() {
      _deliveryType = t;
      // Em retirada: zera taxa e estados associados.
      if (t == _DeliveryType.pickup) {
        _deliveryFee = 0;
        _isFreeDelivery = false;
        _deliveryRuleError = null;
        _deliveryDistanceLabel = null;
        _deliveryDurationText = null;
      }
    });
    _tracking?.track(
      'delivery_type_changed',
      _step,
      extra: {'delivery_type': _deliveryTypeToApi(t)},
    );
    // Em entrega com endereço já preenchido, recalcula taxa.
    if (t == _DeliveryType.delivery && _destinationLat != null && _destinationLng != null) {
      _refreshDeliveryFee();
    }
  }

  // ─── Cart persistence ──────────────────────────────────────────────────────

  Future<void> _restoreCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cartKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        if (mounted) setState(() => _cart = list.map((e) => _PubCartItem.fromJson(e as Map<String, dynamic>)).toList());
      }
    } catch (_) {}
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cartKey, jsonEncode(_cart.map((c) => c.toStorageJson()).toList()));
    } catch (_) {}
    _syncTracking();
  }

  Future<void> _clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartKey);
    } catch (_) {}
    if (mounted) setState(() => _cart = []);
    _syncTracking();
  }

  // ─── Customer session ──────────────────────────────────────────────────────

  Future<void> _restoreCustomer(String? phone) async {
    // 1. Try SharedPreferences first
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionKey);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        final c = PublicClientModel.fromJson(m);
        if (mounted) {
          setState(() {
            _customer = c;
            if (c.lat != null && c.lng != null) {
              _destinationLat = c.lat;
              _destinationLng = c.lng;
            }
          });
        }
        return;
      }
    } catch (_) {}

    // 2. Try phone param from URL
    if (phone != null && phone.isNotEmpty) {
      try {
        final res = await _useCase.findClientByPhone(phone, _companyId);
        if (res.success && res.data is PublicClientModel) {
          final c = res.data as PublicClientModel;
          await _saveCustomer(c);
          if (mounted) setState(() => _customer = c);
        }
      } catch (_) {}
    }
  }

  Future<void> _saveCustomer(PublicClientModel c) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, jsonEncode(c.toJson()));
    } catch (_) {}
  }

  // ─── Active order banner ───────────────────────────────────────────────────

  Future<void> _saveActiveOrder(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_activeOrderKey, orderId);
    } catch (_) {}
  }

  Future<void> _clearActiveOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeOrderKey);
    } catch (_) {}
    if (mounted) setState(() => _activeOrder = null);
  }

  Future<void> _checkActiveOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderId = prefs.getInt(_activeOrderKey);
      if (orderId == null) return;
      final phone = _customer?.phone;
      final res = await _useCase.getOrder(orderId, phone: phone);
      if (!mounted) return;
      if (res.success && res.data is PublicOrderDetailModel) {
        final order = res.data as PublicOrderDetailModel;
        if (_kTerminalStatuses.contains(order.status)) {
          await _clearActiveOrder();
        } else {
          setState(() => _activeOrder = order);
        }
      } else {
        await _clearActiveOrder();
      }
    } catch (_) {}
  }

  // ─── Cart mutations ────────────────────────────────────────────────────────

  // ─── Upsell state (shown inside cart, not as modal) ───────────────────────
  List<Map<String, dynamic>> _cartUpsellItems = const [];
  int? _cartUpsellRuleId;
  String? _cartUpsellDescription;
  int? _lastUpsellTriggerId;

  // ─── Purchase goal (Objetivo de Compra) state ─────────────────────────────
  final PurchaseGoalRepository _goalRepo = PurchaseGoalRepository();
  final Set<int> _goalExcludedProductIds = <int>{};
  PurchaseGoalSuggestionModel? _checkoutGoalSuggestion;
  bool _loadingGoalSuggestion = false;

  Future<void> _refreshCartUpsell(int triggerItemId) async {
    if (_lastUpsellTriggerId == triggerItemId) {
      _filterUpsellItems();
      return;
    }
    _lastUpsellTriggerId = triggerItemId;

    try {
      final svc = PublicHttpService();
      final res = await svc.get('public/upsell/suggestions?company_id=$_companyId&trigger_item_id=$triggerItemId');
      if (!mounted) return;
      if (!res.success || res.data == null) return;

      final raw = res.data as Map<String, dynamic>?;
      if (raw == null) return;
      final ruleId = raw['rule_id'] as int?;
      final description = raw['description'] as String?;
      final rawItems = raw['items'] as List? ?? [];
      if (rawItems.isEmpty || ruleId == null) return;

      final cartIds = _cart.map((c) => c.menuItemId).whereType<int>().toSet();
      final filtered = rawItems.map((e) => e as Map<String, dynamic>).where((it) {
        final id = it['menu_item_id'] as int?;
        return id == null || !cartIds.contains(id);
      }).toList();

      if (!mounted) return;
      setState(() {
        _cartUpsellItems = filtered;
        _cartUpsellRuleId = ruleId;
        _cartUpsellDescription = description;
      });
    } catch (_) {
      // Silently ignore upsell errors — non-critical
    }
  }

  void _filterUpsellItems() {
    if (_cartUpsellItems.isEmpty) return;
    final cartIds = _cart.map((c) => c.menuItemId).whereType<int>().toSet();
    final filtered = _cartUpsellItems.where((it) {
      final id = it['menu_item_id'] as int?;
      return id == null || !cartIds.contains(id);
    }).toList();
    if (filtered.length != _cartUpsellItems.length) {
      setState(() => _cartUpsellItems = filtered);
    }
  }

  void _addUpsellToCart(Map<String, dynamic> item, double finalPrice, double origPrice) {
    final ruleId = _cartUpsellRuleId;
    setState(() {
      final id = item['menu_item_id'] as int;
      final idx = _cart.indexWhere((c) => c.menuItemId == id && c.promotionId == null && c.upsellRuleId == null);
      if (idx >= 0) {
        _cart[idx].quantity += 1;
      } else {
        _cart.add(_PubCartItem(
          menuItemId: id,
          name: item['item_name'] as String? ?? '',
          unitPrice: finalPrice,
          quantity: 1,
          imageUrl: item['item_image_url'] as String?,
          upsellRuleId: ruleId,
          originalPrice: origPrice,
        ));
      }
      // Remove added item from upsell suggestions immediately
      _cartUpsellItems = _cartUpsellItems.where((it) => (it['menu_item_id'] as int?) != id).toList();
    });
    _saveCart();
  }

  void _addToCart(
    PublicMenuItemModel item,
    int qty,
    String? notes, {
    List<_PubCartOption> options = const [],
  }) {
    final extraPerUnit = options.fold<double>(0, (s, o) => s + o.additionalPrice * o.quantity);
    final basePrice = item.price ?? 0;
    final unitPrice = basePrice + extraPerUnit;
    final hash = _optionsHash(options);

    setState(() {
      final idx = _cart.indexWhere((c) => c.menuItemId == item.id && c.promotionId == null && (c.optionsHash ?? '') == hash);
      if (idx >= 0) {
        _cart[idx].quantity += qty;
        if (notes != null && notes.isNotEmpty) _cart[idx].notes = notes;
      } else {
        _cart.add(_PubCartItem(
          menuItemId: item.id,
          name: item.name ?? '',
          unitPrice: unitPrice,
          quantity: qty,
          notes: notes,
          imageUrl: item.imageUrl,
          options: List<_PubCartOption>.from(options),
          optionsHash: hash.isEmpty ? null : hash,
        ));
      }
    });
    _saveCart();
    if (item.id != null) _refreshCartUpsell(item.id!);
  }

  String _optionsHash(List<_PubCartOption> options) {
    if (options.isEmpty) return '';
    final parts = options.map((o) => '${o.groupId ?? 0}:${o.optionId ?? 0}x${o.quantity}').toList()..sort();
    return parts.join('|');
  }

  void _addPromotionToCart(
    PublicPromotionModel promo, {
    int quantity = 1,
    String? notes,
  }) {
    final promoId = promo.id;
    if (promoId == null || quantity <= 0) return;
    final cleanNotes = (notes ?? '').trim().isEmpty ? null : notes!.trim();
    setState(() {
      final idx = _cart.indexWhere(
        (c) => c.promotionId == promoId && (c.notes ?? '') == (cleanNotes ?? ''),
      );
      if (idx >= 0) {
        _cart[idx].quantity += quantity;
      } else {
        final groupKey = 'promo_${promoId}_${DateTime.now().millisecondsSinceEpoch}';
        final items = (promo.items ?? [])
            .map((it) => {
                  'menu_item_id': it.menuItemId,
                  'name': it.name,
                  'unit_price': it.price ?? 0,
                  'quantity': it.quantity,
                  'subtotal': (it.price ?? 0) * it.quantity,
                  'promotion_id': promoId,
                  'promotion_group_key': groupKey,
                })
            .toList();
        _cart.add(_PubCartItem(
          promotionId: promoId,
          promotionGroupKey: groupKey,
          name: promo.name ?? 'Promoção',
          unitPrice: promo.finalPrice ?? 0,
          quantity: quantity,
          notes: cleanNotes,
          imageUrl: promo.imageUrl,
          promotionItems: items,
        ));
      }
    });
    _saveCart();
  }

  void _updateCartQty(String cartKey, int qty) {
    setState(() {
      if (qty <= 0) {
        final item = _cart.where((c) => c.cartKey == cartKey).firstOrNull;
        _cart.removeWhere((c) => c.cartKey == cartKey);
        if (item?.menuItemId == _lastUpsellTriggerId) {
          _clearUpsellCartItems();
        } else {
          if (item?.upsellRuleId != null) _restoreUpsellItem(item!);
          _filterUpsellItems();
        }
      } else {
        final idx = _cart.indexWhere((c) => c.cartKey == cartKey);
        if (idx >= 0) _cart[idx].quantity = qty;
        _filterUpsellItems();
      }
    });
    _saveCart();
  }

  // Decremento rápido a partir do cardápio: encontra a entrada de carrinho
  // mais recente do item e reduz em 1 (ou remove se chegar a zero). Casos com
  // várias variações (options) só são tratados aqui parcialmente — a tela de
  // carrinho continua sendo o lugar para gerência granular.
  void _decrementMenuItem(PublicMenuItemModel item) {
    final id = item.id;
    if (id == null) return;
    final entry = _cart.lastWhereOrNull((c) => c.menuItemId == id);
    if (entry == null) return;
    _updateCartQty(entry.cartKey, entry.quantity - 1);
  }

  void _removeFromCart(String cartKey) {
    setState(() {
      final item = _cart.where((c) => c.cartKey == cartKey).firstOrNull;
      _cart.removeWhere((c) => c.cartKey == cartKey);
      if (item?.menuItemId == _lastUpsellTriggerId) {
        _clearUpsellCartItems();
      } else {
        if (item?.upsellRuleId != null) _restoreUpsellItem(item!);
        _filterUpsellItems();
      }
    });
    _saveCart();
  }

  // Remove do carrinho todos os itens adicionados via upsell da regra atual
  // e limpa o estado de upsell.
  void _clearUpsellCartItems() {
    if (_cartUpsellRuleId != null) {
      _cart.removeWhere((c) => c.upsellRuleId == _cartUpsellRuleId);
    }
    _cartUpsellItems = const [];
    _cartUpsellRuleId = null;
    _cartUpsellDescription = null;
    _lastUpsellTriggerId = null;
  }

  // Devolve um item de upsell removido do carrinho à lista de sugestões.
  void _restoreUpsellItem(_PubCartItem item) {
    if (_cartUpsellRuleId == null || item.upsellRuleId != _cartUpsellRuleId) return;
    final alreadyIn = _cartUpsellItems.any(
      (it) => (it['menu_item_id'] as int?) == item.menuItemId,
    );
    if (alreadyIn) return;
    final origPrice = item.originalPrice ?? item.unitPrice;
    final finalPrice = item.unitPrice;
    final pct = origPrice > finalPrice && origPrice > 0 ? (origPrice - finalPrice) / origPrice * 100 : 0.0;
    _cartUpsellItems = [
      ..._cartUpsellItems,
      {
        'menu_item_id': item.menuItemId,
        'item_name': item.name,
        'item_price': origPrice,
        'final_price': finalPrice,
        'discount_percent': pct,
        'item_image_url': item.imageUrl,
      },
    ];
  }

  // Calcula o tempo médio de preparo a partir do menu (categorias + uncategorized).
  int? _avgPrepFromMenu(PublicCompanyPageModel? data) {
    if (data == null) return null;
    final items = <int>[];
    for (final cat in data.categories) {
      for (final it in (cat.items ?? [])) {
        if (it is PublicMenuItemModel) {
          final t = it.prepTimeMinutes ?? 0;
          if (t > 0) items.add(t);
        }
      }
    }
    for (final it in data.uncategorized) {
      final t = it.prepTimeMinutes ?? 0;
      if (t > 0) items.add(t);
    }
    if (items.isEmpty) return null;
    final avg = items.reduce((a, b) => a + b) / items.length;
    return avg.round();
  }

  // ─── Step navigation ───────────────────────────────────────────────────────

  void _continueFromCart() {
    // Safety guard: double-check minimum order (UI disables button, backend validates too)
    final subtotal = _cart.fold<double>(0, (s, c) => s + c.subtotal);
    final minVal = _minOrderValue ?? _companyData?.companyPreferences?.minPriceOrder;
    if (minVal != null && subtotal < minVal) return;

    if (_customer == null) {
      setState(() => _step = _Step.identify);
    } else if (!_isPickup && !_customer!.hasAddress) {
      // Em retirada pulamos a tela de endereço; sem cliente identificado vai
      // para identify; caso já identificado, vai direto para o checkout.
      setState(() => _step = _Step.address);
    } else {
      _minOrderValue ??= _companyData?.companyPreferences?.minPriceOrder;
      setState(() => _step = _Step.checkout);
      if (_isPickup) {
        setState(() => _deliveryFee = 0);
      } else {
        _refreshDeliveryFee();
      }
      _fetchGoalSuggestion();
    }
    _syncTracking();
    _tracking?.track('checkout_started', _step);
  }

  /// Busca a próxima sugestão de Objetivo de Compra e armazena em
  /// `_checkoutGoalSuggestion`. Mostrado dentro do `_CheckoutScreen` como
  /// um card destacado acima de "Seu pedido".
  Future<void> _fetchGoalSuggestion() async {
    if (_cart.isEmpty) {
      if (_checkoutGoalSuggestion != null) {
        setState(() => _checkoutGoalSuggestion = null);
      }
      return;
    }
    final cartCategoryIds = _collectCartCategoryIds();
    if (cartCategoryIds.isEmpty) {
      if (_checkoutGoalSuggestion != null) {
        setState(() => _checkoutGoalSuggestion = null);
      }
      return;
    }
    setState(() => _loadingGoalSuggestion = true);
    try {
      final res = await _goalRepo.suggest(
        companyId: _companyId,
        categoryIds: cartCategoryIds.toList(),
        excludedProductIds: _goalExcludedProductIds.toList(),
      );
      if (!mounted) return;
      PurchaseGoalSuggestionModel? next;
      if (res.success && res.data is PurchaseGoalSuggestionModel) {
        final s = res.data as PurchaseGoalSuggestionModel;
        // Pula produtos que já estão no carrinho com goal aplicado.
        if (_cart.any((c) => c.menuItemId == s.productId && c.purchaseGoalId != null)) {
          _goalExcludedProductIds.add(s.productId);
          // Re-tenta uma vez para pegar outra sugestão.
          final res2 = await _goalRepo.suggest(
            companyId: _companyId,
            categoryIds: cartCategoryIds.toList(),
            excludedProductIds: _goalExcludedProductIds.toList(),
          );
          if (!mounted) return;
          if (res2.success && res2.data is PurchaseGoalSuggestionModel) {
            next = res2.data as PurchaseGoalSuggestionModel;
          }
        } else {
          next = s;
        }
      }
      setState(() {
        _checkoutGoalSuggestion = next;
        _loadingGoalSuggestion = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingGoalSuggestion = false;
        });
      }
    }
  }

  /// Acionado pelo botão "+" do card: adiciona 1 unidade direto, sem popup.
  Future<void> _quickAcceptGoalSuggestion() async {
    final s = _checkoutGoalSuggestion;
    if (s == null) return;
    await _acceptGoalSuggestion(s, 1);
    await _fetchGoalSuggestion();
  }

  /// Acionado ao tocar no corpo do card: abre o bottom-sheet com detalhes.
  Future<void> _openGoalSuggestionSheet() async {
    final s = _checkoutGoalSuggestion;
    if (s == null) return;
    await _presentGoalSuggestion(s);
    if (!mounted) return;
    // Tanto aceitar quanto pular movem o produto para a lista de excluídos
    // (via _acceptGoalSuggestion ou via onSkip), então buscamos a próxima.
    await _fetchGoalSuggestion();
  }

  Set<int> _collectCartCategoryIds() {
    final ids = <int>{};
    final cats = _companyData?.categories ?? const <PublicCategoryModel>[];
    final byProductId = <int, int>{};
    for (final cat in cats) {
      for (final item in (cat.items ?? const <PublicMenuItemEntity>[])) {
        if (item.id != null && item.categoryId != null) {
          byProductId[item.id!] = item.categoryId!;
        }
      }
    }
    // Inclui produtos do uncategorized também
    final uncat = _companyData?.uncategorized ?? const <PublicMenuItemModel>[];
    for (final it in uncat) {
      if (it.id != null && it.categoryId != null) {
        byProductId[it.id!] = it.categoryId!;
      }
    }
    for (final c in _cart) {
      final id = c.menuItemId;
      if (id == null) continue;
      final catId = byProductId[id];
      if (catId != null) ids.add(catId);
    }
    return ids;
  }

  Future<bool> _presentGoalSuggestion(PurchaseGoalSuggestionModel suggestion) async {
    bool accepted = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) {
        final brand = _parseBrandColor(_companyData?.company.brandColor);
        return _GoalSuggestionSheet(
          suggestion: suggestion,
          brandColor: brand,
          onAccept: (qty) async {
            accepted = await _acceptGoalSuggestion(suggestion, qty);
            return accepted;
          },
          onSkip: () {
            _goalExcludedProductIds.add(suggestion.productId);
          },
        );
      },
    );
    return accepted;
  }

  Future<bool> _acceptGoalSuggestion(PurchaseGoalSuggestionModel s, int qty) async {
    setState(() {
      // Evita duplicar — se já existe no carrinho com o mesmo goal, incrementa qty
      final idx = _cart.indexWhere(
        (c) => c.menuItemId == s.productId && c.purchaseGoalId == s.goalId,
      );
      if (idx >= 0) {
        _cart[idx].quantity += qty;
      } else {
        _cart.add(_PubCartItem(
          menuItemId: s.productId,
          name: s.productName,
          unitPrice: s.finalPrice,
          quantity: qty,
          imageUrl: s.productImageUrl,
          originalPrice: s.originalPrice,
          purchaseGoalId: s.goalId,
          goalDiscountPercentage: s.discountPercentage,
        ));
      }
      _goalExcludedProductIds.add(s.productId);
    });
    await _saveCart();
    return true;
  }

  // ─── Identify callback ─────────────────────────────────────────────────────

  Future<String?> _onSaveIdentify(String name, String phone) async {
    try {
      final res = await _useCase.createClient({'company_id': _companyId, 'name': name, 'phone': phone.isEmpty ? null : phone});
      if (!mounted) return null;
      if (res.success && res.data is PublicClientModel) {
        final c = res.data as PublicClientModel;
        await _saveCustomer(c);
        setState(() => _customer = c);
        // Em retirada pula a tela de endereço.
        if (!_isPickup && !c.hasAddress) {
          setState(() => _step = _Step.address);
        } else {
          setState(() => _step = _Step.checkout);
          if (_isPickup) {
            setState(() => _deliveryFee = 0);
          } else {
            _refreshDeliveryFee();
          }
        }
        _syncTracking();
        return null;
      }
      return 'Não foi possível salvar. Tente novamente.';
    } catch (_) {
      return 'Erro de conexão. Tente novamente.';
    }
  }

  // ─── Address callback ──────────────────────────────────────────────────────

  Future<String?> _onSaveAddress(Map<String, dynamic> addrData) async {
    if (_customer == null) return 'Cliente não identificado.';
    try {
      final payload = {
        'name': _customer!.name,
        'phone': _customer!.phone,
        ...addrData,
      };
      final res = await _useCase.updateClient(_customer!.id!, payload);
      if (!mounted) return null;
      if (res.success && res.data is PublicClientModel) {
        final c = res.data as PublicClientModel;
        // Persist coordinates in the session model so they survive restores
        c.lat = (addrData['lat'] as num?)?.toDouble();
        c.lng = (addrData['lng'] as num?)?.toDouble();
        await _saveCustomer(c);
        setState(() {
          _customer = c;
          _destinationLat = c.lat;
          _destinationLng = c.lng;
          _step = _Step.checkout;
        });
        if (c.lat != null && c.lng != null) {
          _tracking?.updateLocation(
            latitude: c.lat!,
            longitude: c.lng!,
            address: c.toDeliveryAddress(),
          );
        }
        _syncTracking();
        await _refreshDeliveryFee();
        return null;
      }
      return 'Não foi possível salvar o endereço. Tente novamente.';
    } catch (_) {
      return 'Erro de conexão. Tente novamente.';
    }
  }

  // ─── Place order ───────────────────────────────────────────────────────────

  Future<void> _placeOrder() async {
    if (_customer == null || _cart.isEmpty) return;
    if (_selectedPaymentMethodId == null) {
      setState(() => _orderError = 'Selecione uma forma de pagamento para continuar.');
      return;
    }
    // Em entrega: respeita validação de regra de entrega.
    if (!_isPickup && _deliveryRuleError != null) {
      setState(() => _orderError = _deliveryRuleError);
      return;
    }
    final subtotal = _cart.fold<double>(0, (sum, item) => sum + item.subtotal);
    if (_minOrderValue != null && subtotal < _minOrderValue!) {
      setState(() {
        _orderError = 'Pedido mínimo de ${_currFmt.format(_minOrderValue)} para entrega.';
      });
      return;
    }
    if (_useScheduling && _scheduledFor == null) {
      setState(() => _orderError = 'Escolha um horário para agendamento ou desative a opção.');
      return;
    }
    setState(() {
      _placingOrder = true;
      _orderError = null;
    });
    try {
      final delivery = (!_isPickup && _customer!.hasAddress) ? _customer!.toDeliveryAddress() : null;
      final scheduledIso = _useScheduling ? _scheduledFor?.toUtc().toIso8601String() : null;
      final orderItems = <Map<String, dynamic>>[];
      for (final c in _cart) {
        if (c.promotionId == null) {
          orderItems.add(c.toOrderItem());
          continue;
        }
        for (final base in c.promotionItems) {
          final unit = (base['unit_price'] as num? ?? 0).toDouble();
          final itemQty = (base['quantity'] as num? ?? 1).toInt() * c.quantity;
          orderItems.add({
            ...base,
            'quantity': itemQty,
            'unit_price': unit,
            'subtotal': unit * itemQty,
          });
        }
      }
      final res = await _useCase.createOrder({
        'company_id': _companyId,
        'client_id': _customer!.id,
        'items': orderItems,
        'delivery_fee': _isPickup ? 0 : _deliveryFee,
        'delivery_type': _deliveryTypeToApi(_deliveryType),
        if (_selectedPaymentMethodId != null) 'payment_method_id': _selectedPaymentMethodId,
        if (!_isPickup && delivery != null) 'delivery_address': delivery,
        if (scheduledIso != null) 'scheduled_for': scheduledIso,
        if (!_isPickup && _destinationLat != null) 'delivery_lat': _destinationLat,
        if (!_isPickup && _destinationLng != null) 'delivery_lng': _destinationLng,
      });
      if (!mounted) return;
      if (res.success && res.data is Map<String, dynamic>) {
        final orderId = (res.data as Map<String, dynamic>)['id'] as int?;
        await _clearCart();
        if (orderId != null) await _saveActiveOrder(orderId);
        setState(() {
          _createdOrderId = orderId;
          _placedScheduledFor = _useScheduling ? _scheduledFor : null;
        });
        if (orderId != null) {
          _tracking?.attachOrder(orderId);
          await _openTrackingForOrder(orderId, fromStep: _Step.menu);
        } else {
          setState(() => _step = _Step.success);
        }
        _syncTracking(orderId: orderId);
      } else {
        setState(() => _orderError = 'Não foi possível fazer o pedido. Tente novamente.');
      }
    } catch (_) {
      if (mounted) setState(() => _orderError = 'Erro de conexão. Tente novamente.');
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  Future<void> _refreshDeliveryFee() async {
    final lat = _destinationLat;
    final lng = _destinationLng;
    final prefs = _companyData?.companyPreferences;

    // No coordinates: fall back to min_tax_delivery as a flat fee
    if (lat == null || lng == null) {
      if (!mounted) return;
      setState(() {
        _deliveryFee = prefs?.minTaxDelivery ?? 0;
        _deliveryDistanceLabel = null;
        _deliveryDurationText = null;
        _isFreeDelivery = false;
        _deliveryRuleError = null;
        _minOrderValue = prefs?.minPriceOrder;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _loadingDeliveryFee = true;
      _deliveryRuleError = null;
      _deliveryDistanceLabel = null;
      _deliveryDurationText = null;
      _isFreeDelivery = false;
    });
    try {
      final res = await _publicHttp.get(
        'public/delivery-fee?company_id=$_companyId&destination_lat=$lat&destination_lng=$lng',
      );
      if (!mounted) return;
      final minOrderFallback = prefs?.minPriceOrder;
      if (res.success && res.data is Map<String, dynamic>) {
        final map = res.data as Map<String, dynamic>;
        setState(() {
          _deliveryFee = (map['delivery_fee'] as num?)?.toDouble() ?? 0;
          _deliveryDistanceLabel = map['distance_text']?.toString();
          _deliveryDurationText = map['duration_text']?.toString();
          _isFreeDelivery = map['is_free_delivery'] == true;
          _deliveryRuleError = map['ok'] == true ? null : map['message']?.toString();
          _minOrderValue = (map['min_price_order'] as num?)?.toDouble() ?? minOrderFallback;
        });
      } else {
        setState(() {
          _deliveryFee = prefs?.minTaxDelivery ?? 0;
          _deliveryDistanceLabel = null;
          _deliveryDurationText = null;
          _isFreeDelivery = false;
          _deliveryRuleError = 'Não foi possível calcular a taxa de entrega. Tente novamente.';
          _minOrderValue = minOrderFallback;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deliveryFee = 0;
        _deliveryDistanceLabel = null;
        _deliveryDurationText = null;
        _isFreeDelivery = false;
        _deliveryRuleError = 'Não foi possível calcular a taxa de entrega.';
      });
    } finally {
      if (mounted) setState(() => _loadingDeliveryFee = false);
    }
  }

  // ─── Tracking ──────────────────────────────────────────────────────────────

  Future<void> _openTrackingForOrder(int orderId, {_Step? fromStep, PublicOrderDetailModel? prefetched}) async {
    setState(() {
      _previousStepBeforeTracking = fromStep ?? _step;
      _step = _Step.tracking;
      _trackingError = null;
      if (prefetched != null) {
        _trackedOrder = prefetched;
        _loadingTracking = false;
      } else {
        _trackedOrder = null;
        _loadingTracking = true;
      }
    });
    if (prefetched != null) {
      // Refresh in background for fresh status
      await _refreshTrackedOrder(orderId);
    } else {
      await _refreshTrackedOrder(orderId);
    }
    _startTrackingPoll(orderId);
  }

  Future<void> _refreshTrackedOrder(int orderId) async {
    final phone = _customer?.phone;
    final res = await _useCase.getOrder(orderId, phone: phone);
    if (!mounted) return;
    if (res.success && res.data is PublicOrderDetailModel) {
      final updated = res.data as PublicOrderDetailModel;
      setState(() {
        _trackedOrder = updated;
        _loadingTracking = false;
        _trackingError = null;
      });
      // Para o polling automaticamente quando o pedido chega a status terminal.
      if (_kTerminalStatuses.contains(updated.status)) {
        _stopTrackingPoll();
        _clearActiveOrder();
      }
    } else {
      setState(() {
        _loadingTracking = false;
        if (_trackedOrder == null) {
          _trackingError = 'Não foi possível carregar os detalhes do pedido. Tente novamente.';
        }
      });
    }
  }

  void _startTrackingPoll(int orderId) {
    _stopTrackingPoll();
    final order = _trackedOrder;
    if (order != null && _kTerminalStatuses.contains(order.status)) return;
    _trackingPollTimer = Timer.periodic(_kTrackingPollInterval, (_) {
      if (!mounted || _step != _Step.tracking) {
        _stopTrackingPoll();
        return;
      }
      final current = _trackedOrder;
      if (current != null && _kTerminalStatuses.contains(current.status)) {
        _stopTrackingPoll();
        return;
      }
      _refreshTrackedOrder(orderId);
    });
  }

  void _stopTrackingPoll() {
    _trackingPollTimer?.cancel();
    _trackingPollTimer = null;
  }

  Future<void> _openHistory() async {
    _stopTrackingPoll();
    final phone = _customer?.phone;
    if (phone == null || phone.isEmpty) {
      setState(() {
        _step = _Step.identify;
      });
      return;
    }
    setState(() {
      _step = _Step.history;
      _loadingHistory = true;
      _historyError = null;
    });
    final res = await _useCase.findOrdersByPhone(_companyId, phone);
    if (!mounted) return;
    if (res.success && res.data is List) {
      setState(() {
        _orderHistory = (res.data as List).cast<PublicOrderDetailModel>();
        _loadingHistory = false;
      });
    } else {
      setState(() {
        _loadingHistory = false;
        _historyError = 'Não foi possível carregar seus pedidos. Tente novamente.';
      });
    }
  }

  /// Triggered by the "Pedir novamente" CTA in tracking/history.
  /// Calls the backend reorder endpoint, adds available items to the cart
  /// with up-to-date prices, shows a summary sheet for any partial state
  /// and navigates to the cart for one-click checkout.
  Future<void> _handleReorder(int orderId) async {
    final phone = _customer?.phone;
    final res = await _useCase.reorderOrder(orderId, phone: phone);
    if (!mounted) return;
    if (!res.success || res.data is! ReorderResultModel) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty ? res.message : 'Não foi possível repetir o pedido. Tente novamente.'),
          backgroundColor: _DS.danger,
        ),
      );
      return;
    }

    final result = res.data as ReorderResultModel;

    if (result.isEmpty) {
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _ReorderSummarySheet(
          result: result,
          brandColor: _parseBrandColor(_companyData?.company.brandColor),
          onGoToCart: () => Navigator.pop(context),
        ),
      );
      return;
    }

    // Merge into cart using the same path as a manual add. Each reorder line
    // already carries up-to-date `unit_price` (base + extras with current
    // prices) and resolved option snapshots.
    int addedQty = 0;
    for (final v in result.validItems) {
      final options = v.options
          .map((o) => _PubCartOption(
                groupId: o['group_id'] as int?,
                groupName: (o['group_name'] ?? '').toString(),
                optionId: o['option_id'] as int?,
                optionName: (o['option_name'] ?? '').toString(),
                additionalPrice: (o['additional_price'] as num?)?.toDouble() ?? 0,
                quantity: (o['quantity'] as num?)?.toInt() ?? 1,
              ))
          .toList();
      final synthetic = PublicMenuItemModel.fromJson({
        'id': v.menuItemId,
        'name': v.name,
        'description': v.description,
        'price': v.basePrice,
        'image_url': v.imageUrl,
        'featured': false,
        'has_options': options.isNotEmpty,
      });
      _addToCart(synthetic, v.quantity, v.notes, options: options);
      addedQty += v.quantity;
    }

    // Stop tracking polling — we're moving to the cart flow.
    _stopTrackingPoll();

    final brand = _parseBrandColor(_companyData?.company.brandColor);

    if (result.unavailable.isNotEmpty) {
      // Premium summary so the customer sees exactly what was dropped.
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _ReorderSummarySheet(
          result: result,
          brandColor: brand,
          onGoToCart: () {
            Navigator.pop(context);
            setState(() => _step = _Step.cart);
          },
        ),
      );
    } else {
      // Clean path — go straight to cart with a tiny confirmation.
      setState(() => _step = _Step.cart);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _DS.ink,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Pedido adicionado ao carrinho · $addedQty ${addedQty == 1 ? 'item' : 'itens'} 🚀',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  void _backFromTracking() {
    _stopTrackingPoll();
    // Sync banner: if the tracked order is now terminal, hide it; otherwise refresh.
    final tracked = _trackedOrder;
    if (tracked != null) {
      if (_kTerminalStatuses.contains(tracked.status)) {
        _clearActiveOrder();
      } else {
        setState(() => _activeOrder = tracked);
      }
    }
    setState(() {
      _step = _previousStepBeforeTracking == _Step.tracking ? _Step.menu : _previousStepBeforeTracking;
    });
  }

  void _startNewOrder() {
    _stopTrackingPoll();
    final stillClosed = !(_companyData?.isOpen ?? true);
    final freshSlot = stillClosed && _companyData != null ? _firstAvailableSlot(_companyData!.openingHours, DateTime.now()) : null;
    setState(() {
      _step = _Step.menu;
      _createdOrderId = null;
      _orderError = null;
      _placedScheduledFor = null;
      _useScheduling = stillClosed;
      _scheduledFor = freshSlot;
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DS.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return _buildPageContent();
          }

          final viewportWidth = constraints.maxWidth.clamp(0.0, 1920.0);
          final viewportHeight = constraints.maxHeight.clamp(0.0, 1080.0);

          return Center(
            child: SizedBox(
              width: viewportWidth,
              height: viewportHeight,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF4F5F8), Color(0xFFE9EBF2)],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 420,
                    height: 860,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(52),
                      border: Border.all(color: const Color(0xFF2C2C30), width: 8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(42),
                      child: ColoredBox(
                        color: Colors.white,
                        child: Stack(
                          children: [
                            Positioned.fill(child: _buildPageContent()),
                            Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: 140,
                                height: 30,
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color get _brandAccent => _parseBrandColor(_companyData?.company.brandColor);

  Widget _buildPageContent() {
    return SafeArea(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
        child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
      ),
    );
  }

  Widget _buildStep() {
    final brand = _brandAccent;
    switch (_step) {
      case _Step.loading:
        return const _SkeletonScreen();
      case _Step.error:
        return _ErrorScreen(message: _loadError ?? 'Ocorreu um erro.');
      case _Step.menu:
        return _MenuScreen(
          data: _companyData!,
          cart: _cart,
          brandColor: brand,
          scheduledFor: _useScheduling ? _scheduledFor : null,
          onAdd: _addToCart,
          onDecrement: _decrementMenuItem,
          onAddPromotion: _addPromotionToCart,
          onCartTap: () => setState(() => _step = _Step.cart),
          customerName: (_customer?.name != null && (_customer!.name ?? '').isNotEmpty) ? _customer!.name : null,
          onViewHistory: (_customer != null && (_customer!.phone ?? '').isNotEmpty) ? _openHistory : null,
          activeOrder: _activeOrder,
          onViewActiveOrder: _activeOrder != null
              ? () => _openTrackingForOrder(_activeOrder!.id, fromStep: _Step.menu)
              : null,
        );
      case _Step.cart:
        return _CartScreen(
          cart: _cart,
          brandColor: brand,
          onBack: () => setState(() => _step = _Step.menu),
          onUpdateQty: _updateCartQty,
          onRemove: _removeFromCart,
          onContinue: _continueFromCart,
          minOrderValue: _minOrderValue,
          upsellItems: _cartUpsellItems,
          upsellDescription: _cartUpsellDescription,
          onAddUpsell: _addUpsellToCart,
          deliveryType: _deliveryType,
          onDeliveryTypeChange: _setDeliveryType,
          companyAddress: _companyData?.companyAddress,
          companyName: _companyData?.company.name ?? '',
          avgPrepMinutes: _avgPrepFromMenu(_companyData),
        );
      case _Step.identify:
        return _IdentifyScreen(
          initialName: _customer?.name,
          initialPhone: _customer?.phone,
          brandColor: brand,
          onBack: () => setState(() => _step = _Step.cart),
          onSave: _onSaveIdentify,
        );
      case _Step.address:
        return _AddressScreen(
          customer: _customer!,
          brandColor: brand,
          onBack: () => setState(() => _step = _customer == null ? _Step.identify : _Step.cart),
          onSave: _onSaveAddress,
        );
      case _Step.checkout:
        return _CheckoutScreen(
          cart: _cart,
          customer: _customer!,
          company: _companyData!.company,
          companyDescription: _companyData?.company.description,
          avgPrepMinutes: _avgPrepFromMenu(_companyData),
          paymentMethods: _companyData?.paymentMethods ?? const [],
          selectedPaymentMethodId: _selectedPaymentMethodId,
          onSelectPaymentMethod: (id) => setState(() => _selectedPaymentMethodId = id),
          brandColor: brand,
          isOpen: _companyData?.isOpen ?? false,
          openingHours: _companyData?.openingHours ?? const [],
          useScheduling: _useScheduling,
          scheduledFor: _scheduledFor,
          onScheduleToggle: (v) => setState(() {
            _useScheduling = v;
            if (!v) _scheduledFor = null;
            if (v && _scheduledFor == null) {
              _scheduledFor = _firstAvailableSlot(_companyData?.openingHours ?? const [], DateTime.now());
            }
          }),
          onScheduleChange: (dt) => setState(() => _scheduledFor = dt),
          onBack: () => setState(() => _step = _isPickup ? _Step.cart : _Step.address),
          onEditCustomer: () => setState(() => _step = _Step.identify),
          onEditAddress: () => setState(() => _step = _Step.address),
          onConfirm: _placeOrder,
          placing: _placingOrder,
          deliveryFee: _deliveryFee,
          deliveryDistanceLabel: _deliveryDistanceLabel,
          deliveryDurationText: _deliveryDurationText,
          isFreeDelivery: _isFreeDelivery,
          loadingDeliveryFee: _loadingDeliveryFee,
          deliveryRuleError: _deliveryRuleError,
          minOrderValue: _minOrderValue,
          onRetryDeliveryFee: _refreshDeliveryFee,
          error: _orderError,
          goalSuggestion: _checkoutGoalSuggestion,
          loadingGoalSuggestion: _loadingGoalSuggestion,
          onAddGoalSuggestion: _quickAcceptGoalSuggestion,
          onOpenGoalSuggestion: _openGoalSuggestionSheet,
          deliveryType: _deliveryType,
          onDeliveryTypeChange: _setDeliveryType,
          companyAddress: _companyData?.companyAddress,
        );
      case _Step.success:
        return ColoredBox(
          color: Colors.white,
          child: _SuccessScreen(
            orderId: _createdOrderId ?? 0,
            companyName: _companyData?.company.name ?? '',
            brandColor: brand,
            scheduledFor: _placedScheduledFor,
            onNewOrder: _startNewOrder,
          ),
        );
      case _Step.tracking:
        return ColoredBox(
          color: Colors.white,
          child: _TrackingScreen(
          loading: _loadingTracking,
          error: _trackingError,
          order: _trackedOrder,
          brandColor: brand,
          companyName: _companyData?.company.name ?? '',
          onRefresh: () async {
            final id = _trackedOrder?.id ?? _createdOrderId;
            if (id != null) await _refreshTrackedOrder(id);
          },
          onBack: _backFromTracking,
          onViewHistory: _openHistory,
          onNewOrder: _startNewOrder,
          onReorder: _handleReorder,
          onOpenChat: (_customer?.phone != null && _trackedOrder != null)
              ? () {
                  final phone = _customer!.phone!;
                  final orderId = _trackedOrder!.id;
                  _openOrderChat(
                    context,
                    orderId: orderId,
                    phone: phone,
                    clientName: _customer!.name ?? 'Cliente',
                    brandColor: brand,
                    companyName: _companyData?.company.name ?? '',
                  );
                }
              : null,
          ),
        );
      case _Step.history:
        return _HistoryScreen(
          loading: _loadingHistory,
          error: _historyError,
          orders: _orderHistory,
          brandColor: brand,
          customerName: _customer?.name,
          onBack: () => setState(() => _step = _Step.menu),
          onOpenOrder: (order) {
            _openTrackingForOrder(order.id, fromStep: _Step.history, prefetched: order);
          },
          onRetry: _openHistory,
          onReorder: _handleReorder,
        );
    }
  }
}

// ─── Skeleton screen ──────────────────────────────────────────────────────────
class _SkeletonScreen extends StatelessWidget {
  const _SkeletonScreen();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 160,
          decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16))),
              const SizedBox(height: 12),
              Container(width: 160, height: 16, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
            3,
            (_) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  height: 100,
                  decoration: BoxDecoration(color: _DS.canvas, borderRadius: BorderRadius.circular(_DS.rXl), border: Border.all(color: _DS.hairlineSoft)),
                )),
      ],
    );
  }
}

// ─── Error screen ─────────────────────────────────────────────────────────────
class _ErrorScreen extends StatelessWidget {
  final String message;
  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: const Color(0xFFFFEBEA), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.error_outline, size: 32, color: Color(0xFFE53935)),
            ),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 15, color: _DS.slate), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Shared app bar ───────────────────────────────────────────────────────────
/// Seta de voltar inline — sem header. Renderizada dentro do conteúdo,
/// no mesmo nível visual da primeira informação de cada tela.
class _InlineBackArrow extends StatelessWidget {
  final VoidCallback onBack;
  const _InlineBackArrow({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _DS.ink),
        onPressed: onBack,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        visualDensity: VisualDensity.compact,
        splashRadius: 18,
      ),
    );
  }
}
