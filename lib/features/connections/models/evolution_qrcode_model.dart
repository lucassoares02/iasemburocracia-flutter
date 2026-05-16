import 'package:portal_assoc/features/connections/entities/evolution_qrcode_entity.dart';

class EvolutionQrcodeModel extends EvolutionQrcodeEntity {
  EvolutionQrcodeModel.fromJson(Map<String, dynamic> json) {
    pairingCode = json['pairingCode'];
    code = json['code'];
    count = json['count'];
    base64 = json['base64'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['pairingCode'] = pairingCode;
    data['code'] = code;
    data['base64'] = base64;
    data['count'] = count;
    return data;
  }
}
