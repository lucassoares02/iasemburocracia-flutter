class OrderMessageModel {
  final int id;
  final int orderId;
  final int companyId;
  final String senderType;
  final String? senderName;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  const OrderMessageModel({
    required this.id,
    required this.orderId,
    required this.companyId,
    required this.senderType,
    this.senderName,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  factory OrderMessageModel.fromJson(Map<String, dynamic> json) {
    return OrderMessageModel(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      companyId: json['company_id'] as int,
      senderType: json['sender_type'] as String,
      senderName: json['sender_name'] as String?,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
