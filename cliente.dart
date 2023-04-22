import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main() async {
  final socket = await Socket.connect('127.0.0.1', 9349);
  print(
      'Conectado ao servidor ${socket.remoteAddress.address}:${socket.remotePort}');

  final receiveThread = ReceiveThread(socket);
  runInThread(receiveThread);

  final input = stdin.transform(utf8.decoder);
  await for (final line in input) {
    final message = line.trim();
    socket.write('$message\r\n');
    await socket.flush();
  }
}

class ReceiveThread {
  final Socket socket;

  ReceiveThread(this.socket);

  void start() async {
    try {
      await for (final data in socket) {
        final message = String.fromCharCodes(data).trim();
        print('Mensagem recebida: $message');
      }
    } catch (e) {
      print('Erro ao receber mensagens: $e');
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
