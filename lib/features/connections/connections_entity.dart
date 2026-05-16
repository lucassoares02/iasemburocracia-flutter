import 'package:portal_assoc/features/connections/models/websocket_model.dart';

class ConnectionsEntity {
  int? id;
  String? description;
  String? instanceName;
  String? integration;
  bool? qrcode;
  int? company;
  WebsocketModel? websocket;

  ConnectionsEntity({
    this.id,
    this.description,
    this.instanceName,
    this.integration,
    this.qrcode,
    this.company,
    this.websocket,
  });
}
