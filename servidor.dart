import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main() async {
  final server = await ServerSocket.bind('127.0.0.1', 9349);
  print('Servidor iniciado em ${server.address}:${server.port}');

  final sockets = <Socket>[];

  await for (final socket in server) {
    print(
        'Cliente conectado: ${socket.remoteAddress.address}:${socket.remotePort}');
    sockets.add(socket);

    // Inicia uma thread para receber as mensagens do cliente
    final receiveThread = ReceiveThread(socket, sockets);
    runInThread(receiveThread);

    // Envia uma mensagem de boas-vindas para o cliente
    socket.write('Bem-vindo ao servidor!\r\n');
  }
}

class ReceiveThread {
  final Socket socket;
  final List<Socket> sockets;

  ReceiveThread(this.socket, this.sockets);

  void start() async {
    try {
      await for (final data in socket) {
        final message = String.fromCharCodes(data).trim();
        print('Mensagem recebida do cliente ${socket.remoteAddress.address}:${socket.remotePort}: $message');

        // Encaminha a mensagem recebida para todos os outros clientes conectados
        for (final s in sockets) {
          if (s != socket) {
            s.write(
                'Cliente ${socket.remoteAddress.address}:${socket.remotePort} disse: $message\r\n');
          }
        }
      }
    } catch (e) {
      print('Erro ao receber mensagens do cliente ${socket.remoteAddress.address}:${socket.remotePort}: $e');

      // Remove o socket desconectado da lista de sockets
      sockets.remove(socket);
    }
  }
}

void runInThread(dynamic runnable) {
  runZoned(() {
    runnable.start();
  }, onError: (error, stackTrace) {
    print('Erro na thread: $error\n$stackTrace');
  });
}