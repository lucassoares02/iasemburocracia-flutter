class EvolutionSettingsEntity {
  bool? rejectCall;
  String? msgCall;
  bool? groupsIgnore;
  bool? alwaysOnline;
  bool? readMessages;
  bool? readStatus;
  bool? syncFullHistory;
  String? wavoipToken;

  EvolutionSettingsEntity({
    this.rejectCall,
    this.msgCall,
    this.groupsIgnore,
    this.alwaysOnline,
    this.readMessages,
    this.readStatus,
    this.syncFullHistory,
    this.wavoipToken,
  });
}
