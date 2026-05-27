import 'package:portal_assoc/features/connections/models/websocket_model.dart';

import 'connections_entity.dart';

class ConnectionsModel extends ConnectionsEntity {
  ConnectionsModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    instanceId = json['instanceId'];
    instanceName = json['instanceName'];
    description = json['description'];
    integration = json['integration'];
    status = json['status'];
    createdAt = json['createdAt'];
    qrcode = json['qrcode'];
    company = json['company'];
    websocket = json['websocket'] != null ? WebsocketModel.fromJson(json['websocket']) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instanceId': instanceId,
      'instanceName': instanceName,
      'description': description,
      'integration': integration,
      'status': status,
      'createdAt': createdAt,
      'qrcode': qrcode,
      'company': company,
      'websocket': websocket?.toJson(),
    };
  }
}
