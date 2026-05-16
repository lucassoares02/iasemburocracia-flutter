import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect(String instance) {
    print(instance);
    // Note que usamos https:// e apontamos para a raiz da API (ou namespace da instância)
    // Se a Evolution exigir o /ws/nome_instancia como namespace, usamos no final da URL
    final url = "https://evolution.iasemburocracia.com.br/$instance";

    socket = IO.io(
        url,
        IO.OptionBuilder()
            .setTransports(['websocket']) // Força o uso do protocolo websocket
            .disableAutoConnect()
            .setQuery({'apikey': 'c688726355ffaf2b4fab231493ad5c89d0717'}) // Passa a API Key corretamente
            .build());

    // Callbacks de status da conexão
    socket.onConnect((_) {
      print('🔌 Conectado ao Socket.IO da Evolution API!');
    });

    socket.onConnectError((err) {
      print('❌ Erro de conexão no Socket.IO: $err');
    });

    socket.onDisconnect((_) {
      print('🔌 Desconectado do WebSocket');
    });

    socket.connect();
  }

  void disconnect() {
    socket.disconnect();
    socket.dispose();
  }
}
