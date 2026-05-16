import 'package:portal_assoc/features/connections/entities/evolution_settings_entity.dart';

class EvolutionSettingsModel extends EvolutionSettingsEntity {
  EvolutionSettingsModel.fromJson(Map<String, dynamic> json) {
    rejectCall = json['rejectCall'];
    msgCall = json['msgCall'];
    groupsIgnore = json['groupsIgnore'];
    alwaysOnline = json['alwaysOnline'];
    readMessages = json['readMessages'];
    readStatus = json['readStatus'];
    syncFullHistory = json['syncFullHistory'];
    wavoipToken = json['wavoipToken'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rejectCall'] = rejectCall;
    data['msgCall'] = msgCall;
    data['groupsIgnore'] = groupsIgnore;
    data['alwaysOnline'] = alwaysOnline;
    data['readMessages'] = readMessages;
    data['readStatus'] = readStatus;
    data['syncFullHistory'] = syncFullHistory;
    data['wavoipToken'] = wavoipToken;
    return data;
  }
}
