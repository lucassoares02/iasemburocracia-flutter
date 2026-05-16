import 'package:portal_assoc/features/connections/models/evolution_instance_model.dart';
import 'package:portal_assoc/features/connections/models/evolution_qrcode_model.dart';
import 'package:portal_assoc/features/connections/models/evolution_settings.model.dart';

class EvolutionEntity {
  String? hash;
  Map<String, dynamic>? webhook;
  Map<String, dynamic>? websocket;
  Map<String, dynamic>? rabbitmq;
  Map<String, dynamic>? nats;
  Map<String, dynamic>? sqs;
  EvolutionInstanceModel? instance;
  EvolutionSettingsModel? settings;
  EvolutionQrcodeModel? qrcode;
}
