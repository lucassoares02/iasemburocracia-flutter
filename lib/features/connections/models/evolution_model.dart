import 'package:portal_assoc/features/connections/entities/evolution_entity.dart';
import 'package:portal_assoc/features/connections/models/evolution_instance_model.dart';
import 'package:portal_assoc/features/connections/models/evolution_qrcode_model.dart';
import 'package:portal_assoc/features/connections/models/evolution_settings.model.dart';

class EvolutionModel extends EvolutionEntity {
  EvolutionModel.fromJson(Map<String, dynamic> json) {
    hash = json['hash'];
    webhook = json['webhook'];
    websocket = json['websocket'];
    rabbitmq = json['rabbitmq'];
    nats = json['nats'];
    sqs = json['sqs'];
    instance = EvolutionInstanceModel.fromJson(json['instance']);
    settings = EvolutionSettingsModel.fromJson(json['settings']);
    qrcode = EvolutionQrcodeModel.fromJson(json['qrcode']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['hash'] = hash;
    data['webhook'] = webhook;
    data['websocket'] = websocket;
    data['rabbitmq'] = rabbitmq;
    data['nats'] = nats;
    data['sqs'] = sqs;
    if (instance != null) {
      data['instance'] = instance!.toJson();
    }
    if (settings != null) {
      data['settings'] = settings!.toJson();
    }
    if (qrcode != null) {
      data['qrcode'] = qrcode!.toJson();
    }
    return data;
  }
}
