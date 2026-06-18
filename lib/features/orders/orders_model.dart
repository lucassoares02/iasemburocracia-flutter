import 'orders_entity.dart';

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

class ClientModel extends ClientEntity {
  ClientModel.fromJson(Map<String, dynamic> json) {
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
    createdAt = json['created_at'] != null
        ? DateTime.tryParse(json['created_at'])
        : null;
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
      };
}

class OrderItemOptionModel extends OrderItemOptionEntity {
  OrderItemOptionModel.fromJson(Map<String, dynamic> json) {
    groupId = json['group_id'] as int?;
    groupName = json['group_name']?.toString();
    optionId = json['option_id'] as int?;
    optionName = json['option_name']?.toString();
    additionalPrice = _toDouble(json['additional_price']);
    quantity = _toInt(json['quantity']);
  }
}

class OrderItemModel extends OrderItemEntity {
  OrderItemModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    orderId = json['order_id'];
    menuItemId = json['menu_item_id'];
    name = json['item_name'] ?? json['name'];
    quantity = _toInt(json['quantity']);
    unitPrice = _toDouble(json['item_price'] ?? json['unit_price']);
    subtotal = _toDouble(json['subtotal']);
    final rawOpts = json['options'];
    if (rawOpts is List) {
      options = rawOpts
          .map((e) => OrderItemOptionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      options = [];
    }
  }

  Map<String, dynamic> toJson() => {
        'menu_item_id': menuItemId,
        'name': name,
        'quantity': quantity,
        'unit_price': unitPrice,
        'subtotal': subtotal,
      };
}

class OrderModel extends OrderEntity {
  OrderModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tag = json['tag']?.toString();
    companyId = json['company_id'];
    clientId = json['client_id'];
    clientName = json['client_name'];
    clientPhone = json['client_phone'];
    status = json['status'];
    total = _toDouble(json['total']);
    notes = json['notes'];
    deliveryAddress = json['delivery_address'];
    // delivery_type é BOOLEAN no DB (TRUE = entrega, FALSE = retirada).
    final dt = json['delivery_type'];
    if (dt is bool) {
      deliveryType = dt ? 'delivery' : 'pickup';
    } else if (dt is String) {
      final s = dt.toLowerCase();
      deliveryType = (s == 'pickup' || s == 'false' || s == 'f' || s == '0')
          ? 'pickup'
          : 'delivery';
    } else {
      deliveryType = null;
    }
    cancelReason = json['cancel_reason'];
    unreadMessages = _toInt(json['unread_messages_count']) ?? 0;
    createdAt = json['created_at'] != null
        ? DateTime.tryParse(json['created_at'])
        : null;
    updatedAt = json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'])
        : null;
    final rawItems = json['items'];
    if (rawItems is List) {
      items = rawItems
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      items = [];
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tag': tag,
        'company_id': companyId,
        'client_id': clientId,
        'status': status,
        'total': total,
        'notes': notes,
        'delivery_address': deliveryAddress,
        'cancel_reason': cancelReason,
      };
}

class OrderSummaryModel extends OrderSummaryEntity {
  OrderSummaryModel.fromJson(Map<String, dynamic> json)
      : super(
          today: int.tryParse(json['today']?.toString() ?? '0') ?? 0,
          total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
          inProgress: int.tryParse(json['in_progress']?.toString() ?? '0') ?? 0,
          completed: int.tryParse(json['completed']?.toString() ?? '0') ?? 0,
          cancelled: int.tryParse(json['cancelled']?.toString() ?? '0') ?? 0,
          todayValue: _toDouble(json['today_value']) ?? 0,
          totalValue: _toDouble(json['total_value']) ?? 0,
          inProgressValue: _toDouble(json['in_progress_value']) ?? 0,
          completedValue: _toDouble(json['completed_value']) ?? 0,
          cancelledValue: _toDouble(json['cancelled_value']) ?? 0,
        );
}
