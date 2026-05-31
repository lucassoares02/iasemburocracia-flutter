import 'package:portal_assoc/features/connections/connections_socket.dart';
import 'package:portal_assoc/features/connections/connections_usecase.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import '../../core/services/response_model.dart';
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

  /// Emits the latest base64 QR code string (without the data:image prefix).
  ValueNotifier<String?> qrCodeNotifier = ValueNotifier(null);

  void initSocket(String instance) {
    stateSocket.value = LoadingState();
    socket.onConnectionSuccess = (status) {
      if (status == 'open') {
        stateSocket.value = SuccessState({});
      }
    };
    socket.onQrCodeUpdated = (rawQr) {
      qrCodeNotifier.value = rawQr.replaceAll('data:image/png;base64,', '');
    };
    socket.connect(instance);
  }

  Future<void> find(int id) async => runWithState(() => connectionsUsecase.find(id), stateFind);
  Future<void> findAll() async => runWithState(() => connectionsUsecase.findAll(), stateFindAll);
  Future<void> create(ConnectionsModel data) async => runWithState(() => connectionsUsecase.create(data), stateCreate);
  Future<void> update(ConnectionsModel data) async => runWithState(() => connectionsUsecase.update(data), stateUpdate);
  Future<void> delete(int id, String instance) async => runWithState(() => connectionsUsecase.delete(id, instance), stateDelete);

  /// Sentinel value returned by [getQrCode] when the instance is already connected.
  static const String kConnected = '__connected__';

  /// Fetches a fresh QR code from the Evolution API.
  /// Returns [kConnected] if the instance is already in 'open' state,
  /// a base64 string (without the data URI prefix) if a QR is available,
  /// or null on failure.
  Future<String?> getQrCode(String instance) async {
    try {
      final ResponseModel res = await connectionsUsecase.getQrCode(instance);
      if (!res.success) return null;
      final data = res.data;
      if (data is Map) {
        final dynamic instanceData = data['instance'];
        if (instanceData is Map && instanceData['state'] == 'open') return kConnected;
        if (data['state'] == 'open') return kConnected;
        final String? raw = data['base64'] as String?;
        if (raw != null && raw.isNotEmpty) {
          return raw.replaceAll('data:image/png;base64,', '');
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns true if the connection is live (status = 'open').
  Future<bool> testConnection(String instance) async {
    try {
      final ResponseModel res = await connectionsUsecase.testConnection(instance);
      if (!res.success) return false;
      final data = res.data as Map<String, dynamic>?;
      final state = data?['instance']?['state'] ?? data?['state'];
      return state == 'open';
    } catch (_) {
      return false;
    }
  }

  /// Atualiza o workflow do n8n vinculado à conexão (delete + recria).
  /// Retorna `true` em sucesso, `false` em falha.
  Future<bool> updateWorkflow(int id) async {
    try {
      final ResponseModel res = await connectionsUsecase.updateWorkflow(id);
      return res.success;
    } catch (_) {
      return false;
    }
  }

  /// Fast DB-based status check — used for polling after QR scan.
  /// Updated by Evolution's CONNECTION_UPDATE webhook via our backend.
  Future<bool> isConnected(String instance) async {
    try {
      final ResponseModel res = await connectionsUsecase.getConnectionStatus(instance);
      if (!res.success) return false;
      final data = res.data;
      if (data is Map) return data['status'] == 'open';
      return false;
    } catch (_) {
      return false;
    }
  }
}
