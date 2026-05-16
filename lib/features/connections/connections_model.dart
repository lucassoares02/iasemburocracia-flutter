import 'package:portal_assoc/features/connections/models/websocket_model.dart';

import 'connections_entity.dart';

class ConnectionsModel extends ConnectionsEntity {
  ConnectionsModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    description = json['description'];
    instanceName = json['instanceName'];
    integration = json['integration'];
    qrcode = json['qrcode'];
    company = json['company'];
    websocket = json['websocket'] != null ? WebsocketModel.fromJson(json['websocket']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['description'] = description;
    data['instanceName'] = instanceName;
    data['integration'] = integration;
    data['qrcode'] = qrcode;
    data['company'] = company;
    data['websocket'] = websocket?.toJson();
    return data;
  }
}
