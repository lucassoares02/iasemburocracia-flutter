import 'package:portal_assoc/features/connections/entities/websocket_entity.dart';

class WebsocketModel extends WebsocketEntity {
  WebsocketModel.fromJson(Map<String, dynamic> json) {
    enabled = json['enabled'];
    events = json['events'] != null ? List<String>.from(json['events']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['enabled'] = enabled;
    data['events'] = events;
    return data;
  }
}
