class CustomerOrderItemEntity {
  int? id;
  String? name;
  int? quantity;
  double? unitPrice;
  double? subtotal;

  CustomerOrderItemEntity({this.id, this.name, this.quantity, this.unitPrice, this.subtotal});
}

class CustomerOrderEntity {
  int? id;
  int? status;
  double? total;
  String? notes;
  DateTime? createdAt;
  List<CustomerOrderItemEntity>? items;

  CustomerOrderEntity({this.id, this.status, this.total, this.notes, this.createdAt, this.items});
}

class CustomerEntity {
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
  DateTime? updatedAt;
  int? totalOrders;
  double? totalSpent;
  double? avgTicket;
  double? maxOrder;
  DateTime? lastOrderAt;
  DateTime? firstOrderAt;
  int? cancelledOrders;
  List<CustomerOrderEntity>? orders;

  CustomerEntity({
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
    this.updatedAt,
    this.totalOrders,
    this.totalSpent,
    this.avgTicket,
    this.maxOrder,
    this.lastOrderAt,
    this.firstOrderAt,
    this.cancelledOrders,
    this.orders,
  });

  bool get hasAddress => street != null && street!.isNotEmpty;
  bool get hasOrders => (totalOrders ?? 0) > 0;
  bool get isRecurring => (totalOrders ?? 0) > 1;

  int get daysSinceCreated =>
      createdAt != null ? DateTime.now().difference(createdAt!).inDays : 999;

  int get daysSinceLastOrder =>
      lastOrderAt != null ? DateTime.now().difference(lastOrderAt!).inDays : 9999;
}

class CustomerSummaryEntity {
  final int totalClients;
  final int activeClients;
  final int newThisMonth;
  final int recurringClients;
  final double avgSpentPerClient;

  const CustomerSummaryEntity({
    required this.totalClients,
    required this.activeClients,
    required this.newThisMonth,
    required this.recurringClients,
    required this.avgSpentPerClient,
  });
}
