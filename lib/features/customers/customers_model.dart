import 'customers_entity.dart';

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

class CustomerOrderItemModel extends CustomerOrderItemEntity {
  CustomerOrderItemModel.fromJson(Map<String, dynamic> j) {
    id = _toInt(j['id']);
    name = j['name'];
    quantity = _toInt(j['quantity']);
    unitPrice = _toDouble(j['unit_price']);
    subtotal = _toDouble(j['subtotal']);
  }
}

class CustomerOrderModel extends CustomerOrderEntity {
  CustomerOrderModel.fromJson(Map<String, dynamic> j) {
    id = _toInt(j['id']);
    status = _toInt(j['status']);
    total = _toDouble(j['total']);
    notes = j['notes'];
    createdAt = j['created_at'] != null ? DateTime.tryParse(j['created_at'].toString()) : null;
    final rawItems = j['items'];
    if (rawItems is List) {
      items = rawItems
          .map((e) => CustomerOrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      items = [];
    }
  }
}

class CustomerModel extends CustomerEntity {
  CustomerModel.fromJson(Map<String, dynamic> j) {
    id = _toInt(j['id']);
    companyId = _toInt(j['company_id']);
    name = j['name'];
    phone = j['phone'];
    street = j['street'];
    number = j['number'];
    complement = j['complement'];
    neighborhood = j['neighborhood'];
    city = j['city'];
    state = j['state'];
    zipCode = j['zip_code'];
    createdAt =
        j['created_at'] != null ? DateTime.tryParse(j['created_at'].toString()) : null;
    updatedAt =
        j['updated_at'] != null ? DateTime.tryParse(j['updated_at'].toString()) : null;
    totalOrders = _toInt(j['total_orders']);
    totalSpent = _toDouble(j['total_spent']);
    avgTicket = _toDouble(j['avg_ticket']);
    maxOrder = _toDouble(j['max_order']);
    lastOrderAt =
        j['last_order_at'] != null ? DateTime.tryParse(j['last_order_at'].toString()) : null;
    firstOrderAt =
        j['first_order_at'] != null ? DateTime.tryParse(j['first_order_at'].toString()) : null;
    cancelledOrders = _toInt(j['cancelled_orders']);
    final rawOrders = j['orders'];
    if (rawOrders is List) {
      orders = rawOrders
          .map((e) => CustomerOrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Map<String, dynamic> toJson() => {
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

class CustomerSummaryModel extends CustomerSummaryEntity {
  CustomerSummaryModel.fromJson(Map<String, dynamic> j)
      : super(
          totalClients: _toInt(j['total_clients']) ?? 0,
          activeClients: _toInt(j['active_clients']) ?? 0,
          newThisMonth: _toInt(j['new_this_month']) ?? 0,
          recurringClients: _toInt(j['recurring_clients']) ?? 0,
          avgSpentPerClient: _toDouble(j['avg_spent_per_client']) ?? 0.0,
        );
}
