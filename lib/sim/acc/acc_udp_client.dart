import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class AccUdpClient {
  final int port;
  RawDatagramSocket? _socket;

  AccUdpClient({required this.port});

  Stream<Uint8List> bind() async* {
    _socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
      reuseAddress: true,
    );

    await for (final event in _socket!) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket!.receive();
        if (datagram != null) {
          yield datagram.data;
        }
      }
    }
  }

  void close() {
    _socket?.close();
  }
}
