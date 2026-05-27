import 'public_order_entity.dart';

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/// `delivery_type` é BOOLEAN no banco (TRUE = entrega, FALSE = retirada).
/// O backend pode devolver bool ou string ('delivery'/'pickup') — esta função
/// normaliza para o contrato interno 'delivery' | 'pickup'.
String _parseDeliveryType(dynamic v) {
  if (v == null) return 'delivery';
  if (v is bool) return v ? 'delivery' : 'pickup';
  final s = v.toString().toLowerCase();
  if (s == 'pickup' || s == 'false' || s == 'f' || s == '0') return 'pickup';
  return 'delivery';
}

class PublicCompanyModel extends PublicCompanyEntity {
  PublicCompanyModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    phone = json['phone'];
    status = json['status'];
    logoUrl = json['logo_url'];
    bannerUrl = json['banner_url'];
    brandColor = json['brand_color'];
  }
}

class PublicMenuItemModel extends PublicMenuItemEntity {
  PublicMenuItemModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    companyId = json['company_id'];
    categoryId = json['category_id'];
    name = json['name'];
    description = json['description'];
    price = _toDouble(json['price']);
    imageUrl = json['image_url'];
    categoryName = json['category_name'];
    prepTimeMinutes = json['prep_time_minutes'];
    featured = json['featured'] as bool? ?? false;
    hasOptions = json['has_options'] as bool? ?? false;
  }
}

class PublicCategoryModel extends PublicCategoryEntity {
  PublicCategoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    items = (json['items'] as List? ?? [])
        .map((e) => PublicMenuItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class PublicPromotionItemModel extends PublicPromotionItemEntity {
  PublicPromotionItemModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    menuItemId = json['menu_item_id'];
    name = json['name'];
    imageUrl = json['image_url'];
    price = _toDouble(json['price']);
    quantity = json['quantity'] ?? 1;
    subtotal = _toDouble(json['subtotal']);
  }
}

class PublicPromotionModel extends PublicPromotionEntity {
  PublicPromotionModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    imageUrl = json['image_url'];
    active = json['active'] as bool? ?? true;
    originalPrice = _toDouble(json['original_price']);
    discountPercent = _toDouble(json['discount_percent']);
    finalPrice = _toDouble(json['final_price']);
    items = (json['items'] as List? ?? [])
        .map(
            (e) => PublicPromotionItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class PublicPaymentMethodModel extends PublicPaymentMethodEntity {
  PublicPaymentMethodModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'] is int
        ? json['type'] as int
        : int.tryParse('${json['type']}');
    label = json['label'];
    description = json['description'];
    active = json['active'] as bool? ?? false;
  }
}

class PublicCompanyPreferencesModel extends PublicCompanyPreferencesEntity {
  PublicCompanyPreferencesModel.fromJson(Map<String, dynamic> json) {
    maxDistanceMetersDelivery = json['max_distance_meters_delivery'] is int
        ? json['max_distance_meters_delivery'] as int
        : int.tryParse('${json['max_distance_meters_delivery']}');
    kilometerPrice = _toDouble(json['kilometer_price']);
    maxDistanceMetersFreeDelivery =
        json['max_distance_meters_free_delivery'] is int
            ? json['max_distance_meters_free_delivery'] as int
            : int.tryParse('${json['max_distance_meters_free_delivery']}');
    minPriceOrder = _toDouble(json['min_price_order']);
    minTaxDelivery = _toDouble(json['min_tax_delivery']);
  }
}

class PublicCompanyAddressModel extends PublicCompanyAddressEntity {
  PublicCompanyAddressModel.fromJson(Map<String, dynamic> json) {
    street = json['street']?.toString();
    number = json['number']?.toString();
    neighborhood = json['neighborhood']?.toString();
    city = json['city']?.toString();
    state = json['state']?.toString();
    zipCode = json['zip_code']?.toString();
    latitude = _toDouble(json['latitude']);
    longitude = _toDouble(json['longitude']);
    formattedAddress = json['formatted_address']?.toString();
  }
}

class PublicClientModel extends PublicClientEntity {
  PublicClientModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    companyId = json['company_id'];
    name = json['name'];
    phone = json['phone'];
    street = json['street'];
    number = json['number'];
    complement = json['complement'];
    neighborhood = json['neighborhood'];
    city = json['city'];
    state = json['state'];
    zipCode = json['zip_code'];
    lat = _toDouble(json['lat']);
    lng = _toDouble(json['lng']);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'name': name,
        'phone': phone,
        'street': street,
        'number': number,
        'complement': complement,
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
        'zip_code': zipCode,
        'lat': lat,
        'lng': lng,
      };

  String toAddressString() {
    if (!hasAddress) return '';
    final parts = <String>[];
    var line = street!;
    if ((number ?? '').isNotEmpty) line += ', $number';
    if ((complement ?? '').isNotEmpty) line += ' — $complement';
    parts.add(line);
    if ((neighborhood ?? '').isNotEmpty) parts.add(neighborhood!);
    final cs = [city, state]
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .join(' / ');
    if (cs.isNotEmpty) parts.add(cs);
    if ((zipCode ?? '').isNotEmpty) parts.add('CEP $zipCode');
    return parts.join(', ');
  }

  String toDeliveryAddress() {
    if (!hasAddress) return '';
    final parts = <String>[];
    var line = street!;
    if ((number ?? '').isNotEmpty) line += ', $number';
    if ((complement ?? '').isNotEmpty) line += ' — $complement';
    parts.add(line);
    if ((neighborhood ?? '').isNotEmpty) parts.add(neighborhood!);
    if ((city ?? '').isNotEmpty) parts.add(city!);
    if ((zipCode ?? '').isNotEmpty) parts.add(zipCode!);
    return parts.join(' — ');
  }
}

// ─── Order tracking models ───────────────────────────────────────────────────

class PublicOrderItemOptionModel {
  final int? groupId;
  final String groupName;
  final int? optionId;
  final String optionName;
  final double additionalPrice;
  final int quantity;

  PublicOrderItemOptionModel({
    required this.groupId,
    required this.groupName,
    required this.optionId,
    required this.optionName,
    required this.additionalPrice,
    required this.quantity,
  });

  factory PublicOrderItemOptionModel.fromJson(Map<String, dynamic> j) =>
      PublicOrderItemOptionModel(
        groupId: j['group_id'] as int?,
        groupName: (j['group_name'] ?? '').toString(),
        optionId: j['option_id'] as int?,
        optionName: (j['option_name'] ?? '').toString(),
        additionalPrice: _toDouble(j['additional_price']) ?? 0,
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      );
}

// ─── Reorder models ──────────────────────────────────────────────────────────

class ReorderUnavailableItem {
  final String name;
  final int quantity;
  final String reason;
  final String message;
  final String? imageUrl;

  ReorderUnavailableItem({
    required this.name,
    required this.quantity,
    required this.reason,
    required this.message,
    this.imageUrl,
  });

  factory ReorderUnavailableItem.fromJson(Map<String, dynamic> j) =>
      ReorderUnavailableItem(
        name: (j['name'] ?? '').toString(),
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
        reason: (j['reason'] ?? '').toString(),
        message: (j['message'] ?? 'Indisponível').toString(),
        imageUrl: j['image_url']?.toString(),
      );
}

class ReorderValidItem {
  final int menuItemId;
  final String name;
  final String? description;
  final String? imageUrl;
  final double basePrice;
  final double unitPrice;
  final int quantity;
  final String? notes;
  final double subtotal;
  final List<Map<String, dynamic>> options;
  final List<Map<String, dynamic>> droppedOptions;

  ReorderValidItem({
    required this.menuItemId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.basePrice,
    required this.unitPrice,
    required this.quantity,
    required this.notes,
    required this.subtotal,
    required this.options,
    required this.droppedOptions,
  });

  factory ReorderValidItem.fromJson(Map<String, dynamic> j) => ReorderValidItem(
        menuItemId: (j['menu_item_id'] as num).toInt(),
        name: (j['name'] ?? '').toString(),
        description: j['description']?.toString(),
        imageUrl: j['image_url']?.toString(),
        basePrice: _toDouble(j['base_price']) ?? 0,
        unitPrice: _toDouble(j['unit_price']) ?? 0,
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
        notes: j['notes']?.toString(),
        subtotal: _toDouble(j['subtotal']) ?? 0,
        options: ((j['options'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        droppedOptions: ((j['dropped_options'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
}

class ReorderResultModel {
  final int orderId;
  final int companyId;
  final List<ReorderValidItem> validItems;
  final List<ReorderUnavailableItem> unavailable;
  final double subtotalPreview;
  final int itemsCount;
  final int unavailableCount;

  ReorderResultModel({
    required this.orderId,
    required this.companyId,
    required this.validItems,
    required this.unavailable,
    required this.subtotalPreview,
    required this.itemsCount,
    required this.unavailableCount,
  });

  factory ReorderResultModel.fromJson(Map<String, dynamic> j) {
    final totals = (j['totals_preview'] as Map?) ?? {};
    return ReorderResultModel(
      orderId: (j['order_id'] as num).toInt(),
      companyId: (j['company_id'] as num).toInt(),
      validItems: ((j['valid_items'] as List?) ?? [])
          .map((e) => ReorderValidItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      unavailable: ((j['unavailable'] as List?) ?? [])
          .map((e) => ReorderUnavailableItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotalPreview: _toDouble(totals['subtotal']) ?? 0,
      itemsCount: (totals['items_count'] as num?)?.toInt() ?? 0,
      unavailableCount: (totals['unavailable_count'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasPartial => unavailable.isNotEmpty && validItems.isNotEmpty;
  bool get isEmpty => validItems.isEmpty;
}

class PublicOrderItemModel {
  final int? id;
  final int? menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? notes;
  final int? promotionId;
  final String? promotionGroupKey;
  final List<PublicOrderItemOptionModel> options;

  PublicOrderItemModel({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.notes,
    required this.promotionId,
    required this.promotionGroupKey,
    this.options = const [],
  });

  factory PublicOrderItemModel.fromJson(Map<String, dynamic> j) =>
      PublicOrderItemModel(
        id: j['id'] as int?,
        menuItemId: j['menu_item_id'] as int?,
        name: (j['name'] ?? '').toString(),
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: _toDouble(j['unit_price']) ?? 0,
        subtotal: _toDouble(j['subtotal']) ?? 0,
        notes: j['notes']?.toString(),
        promotionId: j['promotion_id'] as int?,
        promotionGroupKey: j['promotion_group_key']?.toString(),
        options: ((j['options'] as List?) ?? [])
            .map((e) => PublicOrderItemOptionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PublicOrderStatusHistoryModel {
  final int status;
  final String? notes;
  final DateTime? createdAt;

  PublicOrderStatusHistoryModel({
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  factory PublicOrderStatusHistoryModel.fromJson(Map<String, dynamic> j) {
    int parseStatus(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 1;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }

    return PublicOrderStatusHistoryModel(
      status: parseStatus(j['status']),
      notes: j['notes']?.toString(),
      createdAt: parseDate(j['created_at']),
    );
  }
}

class PublicOrderDetailModel {
  final int id;
  final int? companyId;
  final int status;
  final String? notes;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String? deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final String deliveryType; // 'delivery' | 'pickup'
  final double? companyLat;
  final double? companyLng;
  final DateTime? scheduledFor;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? clientName;
  final String? clientPhone;
  final String? companyName;
  final String? brandColor;
  final String? logoUrl;
  final String? companyPhone;
  final String? paymentMethodLabel;
  final int? paymentMethodType;
  final List<PublicOrderItemModel> items;
  final List<PublicOrderStatusHistoryModel> statusHistory;

  PublicOrderDetailModel({
    required this.id,
    required this.companyId,
    required this.status,
    required this.notes,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.deliveryAddress,
    required this.deliveryLat,
    required this.deliveryLng,
    required this.deliveryType,
    required this.companyLat,
    required this.companyLng,
    required this.scheduledFor,
    required this.createdAt,
    required this.updatedAt,
    required this.clientName,
    required this.clientPhone,
    required this.companyName,
    required this.brandColor,
    required this.logoUrl,
    required this.companyPhone,
    required this.paymentMethodLabel,
    required this.paymentMethodType,
    required this.items,
    required this.statusHistory,
  });

  factory PublicOrderDetailModel.fromJson(Map<String, dynamic> j) {
    int parseStatus(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 1;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }

    return PublicOrderDetailModel(
      id: (j['id'] as num).toInt(),
      companyId: (j['company_id'] as num?)?.toInt(),
      status: parseStatus(j['status']),
      notes: j['notes']?.toString(),
      subtotal: _toDouble(j['subtotal']) ?? 0,
      deliveryFee: _toDouble(j['delivery_fee']) ?? 0,
      discount: _toDouble(j['discount']) ?? 0,
      total: _toDouble(j['total']) ?? 0,
      deliveryAddress: j['delivery_address']?.toString(),
      deliveryLat: _toDouble(j['delivery_lat']),
      deliveryLng: _toDouble(j['delivery_lng']),
      deliveryType: _parseDeliveryType(j['delivery_type']),
      companyLat: _toDouble(j['company_lat']),
      companyLng: _toDouble(j['company_lng']),
      scheduledFor: parseDate(j['scheduled_for']),
      createdAt: parseDate(j['created_at']),
      updatedAt: parseDate(j['updated_at']),
      clientName: j['client_name']?.toString(),
      clientPhone: j['client_phone']?.toString(),
      companyName: j['company_name']?.toString(),
      brandColor: j['brand_color']?.toString(),
      logoUrl: j['logo_url']?.toString(),
      companyPhone: j['company_phone']?.toString(),
      paymentMethodLabel: j['payment_method_label']?.toString(),
      paymentMethodType: (j['payment_method_type'] as num?)?.toInt(),
      items: (j['items'] as List? ?? [])
          .map((e) => PublicOrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      statusHistory: (j['status_history'] as List? ?? [])
          .map((e) =>
              PublicOrderStatusHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PublicOpeningHourModel extends PublicOpeningHourEntity {
  PublicOpeningHourModel.fromJson(Map<String, dynamic> json) {
    weekday = json['weekday'] is int
        ? json['weekday'] as int
        : int.tryParse('${json['weekday']}');
    opensAt = json['opens_at']?.toString();
    closesAt = json['closes_at']?.toString();
    isClosed = json['is_closed'] as bool? ?? false;
  }
}

class PublicCompanyPageModel {
  final PublicCompanyModel company;
  final bool isOpen;
  final List<PublicCategoryModel> categories;
  final List<PublicMenuItemModel> uncategorized;
  final List<PublicOpeningHourModel> openingHours;
  final List<PublicPromotionModel> promotions;
  final List<PublicPaymentMethodModel> paymentMethods;
  final PublicCompanyPreferencesModel? companyPreferences;
  final PublicCompanyAddressModel? companyAddress;

  PublicCompanyPageModel({
    required this.company,
    required this.isOpen,
    required this.categories,
    required this.uncategorized,
    required this.openingHours,
    required this.promotions,
    required this.paymentMethods,
    required this.companyPreferences,
    required this.companyAddress,
  });

  factory PublicCompanyPageModel.fromJson(Map<String, dynamic> json) {
    return PublicCompanyPageModel(
      company:
          PublicCompanyModel.fromJson(json['company'] as Map<String, dynamic>),
      isOpen: json['is_open'] as bool? ?? false,
      categories: (json['categories'] as List? ?? [])
          .map((c) => PublicCategoryModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      uncategorized: (json['uncategorized'] as List? ?? [])
          .map((i) => PublicMenuItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      openingHours: (json['opening_hours'] as List? ?? [])
          .map(
              (h) => PublicOpeningHourModel.fromJson(h as Map<String, dynamic>))
          .toList(),
      promotions: (json['promotions'] as List? ?? [])
          .map((p) => PublicPromotionModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      paymentMethods: (json['payment_methods'] as List? ?? [])
          .map((m) =>
              PublicPaymentMethodModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      companyPreferences: json['company_preferences'] is Map<String, dynamic>
          ? PublicCompanyPreferencesModel.fromJson(
              json['company_preferences'] as Map<String, dynamic>,
            )
          : null,
      companyAddress: json['company_address'] is Map<String, dynamic>
          ? PublicCompanyAddressModel.fromJson(
              json['company_address'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  bool get hasItems => categories.isNotEmpty || uncategorized.isNotEmpty;

  List<PublicMenuItemModel> get featured {
    final items = <PublicMenuItemModel>[];
    for (final cat in categories) {
      for (final it in (cat.items ?? []).cast<PublicMenuItemModel>()) {
        if (it.featured) items.add(it);
      }
    }
    for (final it in uncategorized) {
      if (it.featured) items.add(it);
    }
    return items;
  }
}
