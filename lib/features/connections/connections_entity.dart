import 'package:portal_assoc/features/connections/models/websocket_model.dart';

class ConnectionsEntity {
  int? id;
  String? instanceId;
  String? instanceName;
  String? description;
  String? integration;
  String? status;
  String? createdAt;
  bool? qrcode;
  int? company;
  WebsocketModel? websocket;

  ConnectionsEntity({
    this.id,
    this.instanceId,
    this.instanceName,
    this.description,
    this.integration,
    this.status,
    this.createdAt,
    this.qrcode,
    this.company,
    this.websocket,
  });
}
