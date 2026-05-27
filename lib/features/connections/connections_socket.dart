import 'package:portal_assoc/core/services/websocket_service.dart';

class ConnectionsSocket {
  final ws = SocketService();
  Function(String)? onQrCodeUpdated;
  Function(String)? onConnectionSuccess; // Novo callback

  void connect(String instance) {
    ws.connect(instance);

    ws.socket.on('connection.update', (payload) {
      if (payload != null && payload['data'] != null) {
        final state = payload['data']['state'];
        if (state == 'open') {
          onConnectionSuccess?.call('open');
        }
      }
    });
    ws.socket.on('qrcode.updated', (payload) {
      final qrCode = payload["qrcode"];
      if (onQrCodeUpdated != null && qrCode != null) {
        onQrCodeUpdated!(qrCode);
      }
    });
  }
}
