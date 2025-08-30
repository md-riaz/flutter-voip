import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

import '../logger.dart';
import '../sip_ua_helper.dart';

typedef OnMessageCallback = void Function(dynamic msg);
typedef OnCloseCallback = void Function(int? code, String? reason);
typedef OnOpenCallback = void Function();

class WebSocketImpl {
  WebSocketImpl(this._url);

  final String _url;
  WebSocket? _socket;
  OnOpenCallback? onOpen;
  OnMessageCallback? onMessage;
  OnCloseCallback? onClose;

  void connect(
      {Iterable<String>? protocols,
      required WebSocketSettings webSocketSettings}) async {
    logger.info('connect $_url, ${webSocketSettings.extraHeaders}, $protocols');
    try {
      _socket = WebSocket(_url, 'sip'.toJS);
      _socket!.onOpen.listen((Event e) {
        onOpen?.call();
      });

      _socket!.onMessage.listen((MessageEvent e) async {
        if (e.data is Blob) {
          final arrayBuffer = await (e.data as Blob).arrayBuffer().toDart;
          final byteBuffer = arrayBuffer as ByteBuffer;
          final uint8List = Uint8List.view(byteBuffer);
          String message = String.fromCharCodes(uint8List);
          onMessage?.call(message);
        } else {
          onMessage?.call(e.data);
        }
      });

      _socket!.onClose.listen((CloseEvent e) {
        onClose?.call(e.code, e.reason);
      });
    } catch (e) {
      onClose?.call(0, e.toString());
    }
  }

  void send(dynamic data) {
    if (_socket != null && _socket!.readyState == WebSocket.OPEN) {
      _socket!.send(data);
      logger.debug('send: \n\n$data');
    } else {
      logger.error('WebSocket not connected, message $data not sent');
    }
  }

  bool isConnecting() {
    return _socket != null && _socket!.readyState == WebSocket.CONNECTING;
  }

  void close() {
    _socket!.close();
  }
}
