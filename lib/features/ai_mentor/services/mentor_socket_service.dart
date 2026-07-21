import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Pure transport: owns the raw WebSocket connection, the ping keepalive,
/// and JSON encode/decode. Knows nothing about mentor state, audio, or
/// Gemini — just "send this map, tell me when a map arrives, tell me if
/// the connection died".
///
/// Disconnection is detected ONLY from the socket's own `onDone`/`onError`
/// events — matching the behavior of the earlier, proven-reliable client
/// implementation this was modeled after. An earlier version of this
/// class also declared "disconnected" after a few missed pong replies,
/// but that turned out to be a real regression: a brief server-side delay
/// relaying audio (or ordinary network jitter) could delay a pong past
/// the timeout on a connection that was actually still perfectly healthy,
/// causing spurious "No Internet Connection" flashes and reconnect
/// churn — exactly what made the live conversation feel less real-time.
/// The ping is now purely a NAT/firewall keepalive with no bearing on the
/// disconnect decision.
class MentorSocketService {
  final void Function(Map<String, dynamic> message) onMessage;
  final void Function() onDisconnected;

  MentorSocketService({required this.onMessage, required this.onDisconnected});

  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  Timer? _pingTimer;

  bool get isOpen => _channel != null && _channel!.closeCode == null;

  Future<void> connect(Uri uri) async {
    _channel = IOWebSocketChannel.connect(uri);
    await _channel!.ready.timeout(const Duration(seconds: 10));

    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!isOpen) return;
      send({'type': 'ping'});
    });

    await _wsSub?.cancel();
    _wsSub = _channel!.stream.listen(
      (raw) {
        try {
          final decoded = jsonDecode(raw.toString());
          if (decoded is! Map<String, dynamic>) return;
          if (decoded['type'] == 'pong') return; // acknowledged, nothing to do
          onMessage(decoded);
        } catch (_) {}
      },
      onDone: onDisconnected,
      onError: (_) => onDisconnected(),
    );
  }

  void send(Map<String, dynamic> message) {
    if (!isOpen) return;
    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (_) {}
  }

  /// The only thing the client ever sends about "who is this" — the server
  /// verifies this token itself and fetches the user's full context. No
  /// raw userId, no client-supplied profile data to trust.
  void sendSetup(String accessToken) {
    send({'type': 'setup', 'accessToken': accessToken});
  }

  void sendAudioChunk(String base64Pcm) {
    send({'type': 'audio', 'data': base64Pcm});
  }

  Future<void> dispose() async {
    _pingTimer?.cancel();
    await _wsSub?.cancel();
    await _channel?.sink.close();
  }
}
