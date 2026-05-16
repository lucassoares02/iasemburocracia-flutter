import 'package:portal_assoc/features/connections/connections_socket.dart';
import 'package:portal_assoc/features/connections/connections_usecase.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import '../../core/state/base_controller.dart';
import 'package:flutter/material.dart';
import 'connections_model.dart';

class ConnectionsController extends BaseController<ConnectionsModel> {
  final ConnectionsUseCase connectionsUsecase;

  ConnectionsController(super.initialState, this.connectionsUsecase);

  final ConnectionsSocket socket = ConnectionsSocket();
  ValueNotifier<StateApp> stateFind = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateFindAll = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateCreate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateUpdate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateDelete = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateSocket = ValueNotifier(StartState());

  void initSocket(String instance) {
    stateSocket.value = LoadingState();
    socket.onConnectionSuccess = (status) {
      if (status == 'open') {
        stateSocket.value = SuccessState({});
      }
    };

    socket.connect(instance);
  }

  Future<void> find(int id) async => runWithState(() => connectionsUsecase.find(id), stateFind);
  Future<void> findAll() async => runWithState(() => connectionsUsecase.findAll(), stateFindAll);
  Future<void> create(ConnectionsModel data) async => runWithState(() => connectionsUsecase.create(data), stateCreate);
  Future<void> update(ConnectionsModel data) async => runWithState(() => connectionsUsecase.update(data), stateUpdate);
  Future<void> delete(int id, String instance) async => runWithState(() => connectionsUsecase.delete(id, instance), stateDelete);
}
