import 'package:portal_assoc/features/connections/entities/evolution_instance_entity.dart';

class EvolutionInstanceModel extends EvolutionInstanceEntity {
  EvolutionInstanceModel.fromJson(Map<String, dynamic> json) {
    instanceName = json['instanceName'];
    instanceId = json['instanceId'];
    integration = json['integration'];
    webhookWaBusiness = json['webhookWaBusiness'];
    accessTokenWaBusiness = json['accessTokenWaBusiness'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['instanceName'] = instanceName;
    data['instanceId'] = instanceId;
    data['integration'] = integration;
    data['webhookWaBusiness'] = webhookWaBusiness;
    data['accessTokenWaBusiness'] = accessTokenWaBusiness;
    data['status'] = status;
    return data;
  }
}
