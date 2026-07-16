import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:lingo_sync/features/ai_mentor/data/mentor_state.dart';
import 'package:lingo_sync/features/ai_mentor/services/mentor_audio_service.dart';
import 'package:lingo_sync/features/ai_mentor/services/mentor_socket_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'ai_mentor_controller.g.dart';

const _mentorSocketUrl = 'wss://safer.privatepath.ir/ws';

// Deliberately NOT keepAlive — this controller (and the socket + mic it
// owns) should only exist while the mentor sheet is open. The moment the
// sheet is popped and nothing watches this provider anymore, Riverpod
// disposes it, which tears down the socket and stops the microphone.
@riverpod
class AiMentorController extends _$AiMentorController {
  late final MentorSocketService _socket;
  late final MentorAudioService _audio;

  @override
  AiMentorSessionState build() {
    _socket = MentorSocketService(
      onMessage: _handleServerMessage,
      onDisconnected: _handleDisconnect,
    );
    _audio = MentorAudioService();
    _audio.onPlaybackCompleted(_onPlaybackCompleted);

    ref.onDispose(() {
      _audio.dispose();
      _socket.dispose();
    });

    _initSession();

    return const AiMentorSessionState.initial();
  }

  Future<void> _initSession() async {
    // Mic hardware starts once for the whole session; muting is handled by
    // gating inside _onAmplitude/_onPcmChunk, not by stopping/restarting
    // the recorder every turn.
    await _audio.startMicStream(
      onAmplitude: _onAmplitude,
      onPcmChunk: _onPcmChunk,
    );
    await _connect();
  }

  Future<void> _connect() async {
    state = state.copyWith(phase: MentorPhase.connecting);
    try {
      await _socket.connect(Uri.parse(_mentorSocketUrl));
      _sendSetup();
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _sendSetup() {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      _handleDisconnect();
      return;
    }
    state = state.copyWith(phase: MentorPhase.settingUp);
    _socket.sendSetup(token);
  }

  /// AI's turn on the *server's* Gemini connection died (mentor-server.js
  /// still has our socket open) — just ask it to set up again.
  void restartAiSession() {
    HapticFeedback.mediumImpact();
    _sendSetup();
  }

  /// Our own socket to mentor-server.js died — full reconnect.
  void reconnect() {
    HapticFeedback.lightImpact();
    _connect();
  }

  void onOrbTap() {
    switch (state.phase) {
      case MentorPhase.aiDisconnected:
        restartAiSession();
        break;
      case MentorPhase.disconnected:
        reconnect();
        break;
      default:
        break;
    }
  }

  void _handleDisconnect() {
    state = state.copyWith(phase: MentorPhase.disconnected, isMicMuted: true);
  }

  void _handleServerMessage(Map<String, dynamic> data) async {
    switch (data['type']) {
      case 'ready':
        _enterReadyState();
        break;

      case 'ai_disconnected':
        state = state.copyWith(
          phase: MentorPhase.aiDisconnected,
          isMicMuted: true,
        );
        break;

      case 'audio':
        if (state.phase != MentorPhase.receivingAudio) {
          state = state.copyWith(
            phase: MentorPhase.receivingAudio,
            isMicMuted: true,
          );
        }
        _pcmBuffer.addAll(base64Decode(data['data'] as String));
        break;

      case 'interrupt':
        _pcmBuffer.clear();
        await _audio.stopPlayback();
        _enterReadyState();
        break;

      case 'turn_complete':
        if (_pcmBuffer.isNotEmpty) {
          state = state.copyWith(
            phase: MentorPhase.receivingAudio,
            isMicMuted: true,
          );
          final chunk = List<int>.from(_pcmBuffer);
          _pcmBuffer.clear();
          await _audio.playPcm(chunk);
        } else {
          _enterReadyState();
        }
        break;

      default:
        break;
    }
  }

  final List<int> _pcmBuffer = [];

  Future<void> _onPlaybackCompleted() async {
    if (state.phase != MentorPhase.receivingAudio) return;
    // Small delay to avoid the mentor's own last word echoing into the mic.
    await Future.delayed(const Duration(milliseconds: 500));
    _enterReadyState();
  }

  void _enterReadyState() {
    state = state.copyWith(
      phase: MentorPhase.ready,
      isMicMuted: false,
      amplitude: 0,
    );
  }

  void _onAmplitude(double amplitude) {
    if (state.isMicMuted || state.phase != MentorPhase.ready) return;
    state = state.copyWith(amplitude: amplitude);
  }

  void _onPcmChunk(List<int> chunk) {
    if (state.isMicMuted || state.phase != MentorPhase.ready) return;
    _socket.sendAudioChunk(base64Encode(chunk));
  }
}
