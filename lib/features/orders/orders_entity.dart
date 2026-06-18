class OrderItemOptionEntity {
  int? groupId;
  String? groupName;
  int? optionId;
  String? optionName;
  double? additionalPrice;
  int? quantity;

  OrderItemOptionEntity({
    this.groupId,
    this.groupName,
    this.optionId,
    this.optionName,
    this.additionalPrice,
    this.quantity,
  });
}

class OrderItemEntity {
  int? id;
  int? orderId;
  int? menuItemId;
  String? name;
  int? quantity;
  double? unitPrice;
  double? subtotal;
  List<OrderItemOptionEntity>? options;

  OrderItemEntity({
    this.id,
    this.orderId,
    this.menuItemId,
    this.name,
    this.quantity,
    this.unitPrice,
    this.subtotal,
    this.options,
  });
}

class ClientEntity {
  int? id;
  int? companyId;
  String? name;
  String? phone;
  String? street;
  String? number;
  String? complement;
  String? neighborhood;
  String? city;
  String? state;
  String? zipCode;
  DateTime? createdAt;

  bool get hasAddress => street != null && street!.isNotEmpty;

  ClientEntity({
    this.id,
    this.companyId,
    this.name,
    this.phone,
    this.street,
    this.number,
    this.complement,
    this.neighborhood,
    this.city,
    this.state,
    this.zipCode,
    this.createdAt,
  });
}

class OrderEntity {
  int? id;
  String? tag;
  int? companyId;
  int? clientId;
  String? clientName;
  String? clientPhone;
  int? status;
  double? total;
  String? notes;
  String? deliveryAddress;
  String? deliveryType; // 'delivery' | 'pickup'
  String? cancelReason;
  int unreadMessages;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<OrderItemEntity>? items;

  OrderEntity({
    this.id,
    this.tag,
    this.companyId,
    this.clientId,
    this.clientName,
    this.clientPhone,
    this.status,
    this.total,
    this.notes,
    this.deliveryAddress,
    this.cancelReason,
    this.unreadMessages = 0,
    this.createdAt,
    this.updatedAt,
    this.items,
  });
}

class OrderSummaryEntity {
  int today;
  int total;
  int inProgress;
  int completed;
  int cancelled;
  double todayValue;
  double totalValue;
  double inProgressValue;
  double completedValue;
  double cancelledValue;

  OrderSummaryEntity({
    required this.today,
    required this.total,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
    this.todayValue = 0,
    this.totalValue = 0,
    this.inProgressValue = 0,
    this.completedValue = 0,
    this.cancelledValue = 0,
  });
}
