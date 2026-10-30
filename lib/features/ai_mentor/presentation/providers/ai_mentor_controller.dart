import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:lingo_sync/core/config/app_config.dart';
import 'package:lingo_sync/core/logging/app_logger.dart';
import 'package:lingo_sync/features/ai_mentor/data/models/mentor_state.dart';
import 'package:lingo_sync/features/ai_mentor/services/mentor_audio_service.dart';
import 'package:lingo_sync/features/ai_mentor/services/mentor_socket_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'ai_mentor_controller.g.dart';

@riverpod
class AiMentorController extends _$AiMentorController {
  late final MentorSocketService _socket;
  late final MentorAudioService _audio;

  Timer? _autoReconnectTimer;
  Timer? _autoRestartTimer;
  int _autoReconnectAttempts = 0;
  int _autoRestartAttempts = 0;

  // 🚀 فلگ امنیتی برای جلوگیری از باز شدن زودهنگام میکروفون
  bool _isWaitingForTurnComplete = false;
  bool _isDisposed = false;

  @override
  AiMentorSessionState build() {
    _isDisposed = false;
    _socket = MentorSocketService(
      onMessage: _handleServerMessage,
      onDisconnected: _handleDisconnect,
    );
    _audio = MentorAudioService();
    _audio.onPlaybackCompleted(_onPlaybackCompleted);

    ref.onDispose(() {
      _isDisposed = true;
      _autoReconnectTimer?.cancel();
      _autoRestartTimer?.cancel();
      _audio.dispose();
      _socket.dispose();
    });

    _initSession();

    return const AiMentorSessionState.initial();
  }

  Future<void> _initSession() async {
    if (_isDisposed) return;
    await _audio.startMicStream(
      onAmplitude: _onAmplitude,
      onPcmChunk: _onPcmChunk,
    );
    if (_isDisposed) return;
    await _connect();
  }

  Future<void> _connect() async {
    if (_isDisposed || !ref.mounted) return;
    state = state.copyWith(phase: MentorPhase.connecting);
    try {
      await _socket.connect(Uri.parse(AppConfig.mentorSocketUrl));
      if (_isDisposed || !ref.mounted) return;
      _sendSetup();
    } on Exception catch (e) {
      if (_isDisposed || !ref.mounted) return;
      logger.warning(
        'Mentor socket connection failed',
        error: e,
        context: 'AiMentorController',
      );
      _handleDisconnect();
    } catch (_) {
      if (_isDisposed || !ref.mounted) return;
      _handleDisconnect();
    }
  }

  void _sendSetup() {
    if (_isDisposed || !ref.mounted) return;
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      _handleDisconnect();
      return;
    }
    state = state.copyWith(phase: MentorPhase.settingUp);
    _socket.sendSetup(token);
  }

  void restartAiSession() {
    if (_isDisposed || !ref.mounted) return;
    HapticFeedback.mediumImpact();
    _sendSetup();
  }

  void reconnect() {
    if (_isDisposed || !ref.mounted) return;
    HapticFeedback.lightImpact();
    _connect();
  }

  void onOrbTap() {
    if (_isDisposed || !ref.mounted) return;
    switch (state.phase) {
      case MentorPhase.aiDisconnected:
        restartAiSession();
        break;
      case MentorPhase.disconnected:
        reconnect();
        break;
      case MentorPhase.receivingAudio:
        HapticFeedback.heavyImpact();
        _interruptMentor();
        break;
      case MentorPhase.ready:
        HapticFeedback.selectionClick();
        state = state.copyWith(
          statusMessage: '💡 دکمه را فشار دهید و نگه دارید تا صحبت کنید',
        );
        break;
      default:
        break;
    }
  }

  Future<void> startTalking() async {
    if (_isDisposed || !ref.mounted) return;
    if (state.phase == MentorPhase.receivingAudio) {
      await _interruptMentor();
    }
    if (state.phase != MentorPhase.ready &&
        state.phase != MentorPhase.receivingAudio) {
      return;
    }

    await HapticFeedback.mediumImpact();
    state = state.copyWith(
      isUserTalking: true,
      isMicMuted: false,
      phase: MentorPhase.ready,
      statusMessage: '🎙️ در حال ضبط... رها کنید تا ارسال شود',
    );
  }

  Future<void> stopTalking() async {
    if (_isDisposed || !ref.mounted) return;
    if (!state.isUserTalking) return;

    await HapticFeedback.lightImpact();
    state = state.copyWith(
      isUserTalking: false,
      isMicMuted: true,
      amplitude: 0,
      statusMessage: '⚡ در حال دریافت پاسخ منتور...',
    );

    if (_socket.isOpen) {
      _socket.send({'type': 'client_turn_complete'});
    }
  }

  Future<void> _interruptMentor() async {
    if (_isDisposed) return;
    _pcmBuffer.clear();
    _isWaitingForTurnComplete = false;
    await _audio.stopPlayback();
    if (_socket.isOpen) {
      _socket.send({'type': 'client_interrupt'});
    }
    _enterReadyState();
  }

  void _handleDisconnect() {
    if (_isDisposed || !ref.mounted) return;
    state = state.copyWith(phase: MentorPhase.disconnected, isMicMuted: true);
    _scheduleAutoReconnect();
  }

  void _scheduleAutoReconnect() {
    if (_isDisposed || !ref.mounted) return;
    _autoReconnectTimer?.cancel();
    _autoReconnectAttempts++;
    final delay = Duration(seconds: _autoReconnectAttempts.clamp(1, 8));
    _autoReconnectTimer = Timer(delay, () {
      if (_isDisposed || !ref.mounted) return;
      if (state.phase == MentorPhase.disconnected) {
        _connect();
      }
    });
  }

  void _scheduleAutoRestart() {
    if (_isDisposed || !ref.mounted) return;
    _autoRestartTimer?.cancel();
    _autoRestartAttempts++;
    final delay = Duration(seconds: _autoRestartAttempts.clamp(1, 5));
    _autoRestartTimer = Timer(delay, () {
      if (_isDisposed || !ref.mounted) return;
      if (state.phase == MentorPhase.aiDisconnected) {
        restartAiSession();
      }
    });
  }

  void _handleServerMessage(Map<String, dynamic> data) {
    if (_isDisposed || !ref.mounted) return;
    switch (data['type']) {
      case 'ready':
        _enterReadyState();
        break;

      case 'ai_disconnected':
        state = state.copyWith(
          phase: MentorPhase.aiDisconnected,
          isMicMuted: true,
        );
        _scheduleAutoRestart();
        break;

      case 'audio':
        _isWaitingForTurnComplete = true; // قفل کردن میکروفون
        if (state.phase != MentorPhase.receivingAudio) {
          state = state.copyWith(
            phase: MentorPhase.receivingAudio,
            isMicMuted: true,
          );
        }

        final String base64Data = data['data'] as String;
        if (base64Data.isNotEmpty) {
          final decodedBytes = base64Decode(base64Data);
          _pcmBuffer.addAll(decodedBytes);
        }
        break;

      case 'interrupt':
        _pcmBuffer.clear();
        _isWaitingForTurnComplete = false;
        _audio.stopPlayback();
        _enterReadyState();
        break;

      case 'turn_complete':
        _isWaitingForTurnComplete = false; // باز کردن قفل
        if (_pcmBuffer.isNotEmpty) {
          state = state.copyWith(
            phase: MentorPhase.receivingAudio,
            isMicMuted: true,
          );
          final chunk = List<int>.from(_pcmBuffer);
          _pcmBuffer.clear();
          _audio.playPcm(chunk);
        } else {
          _enterReadyState();
        }
        break;

      case 'session_warning':
        state = state.copyWith(
          statusMessage:
              data['message'] as String? ??
              'یک دقیقه از جلسه مکالمه باقی مانده است.',
        );
        HapticFeedback.mediumImpact();
        break;

      case 'admission_redirect':
        state = state.copyWith(
          phase: MentorPhase.aiDisconnected,
          isMicMuted: true,
          statusMessage:
              data['message'] as String? ??
              'ظرفیت خطوط صوتی زنده تکمیل است؛ انتقال موقت به حالت صوتی نوبتی',
        );
        HapticFeedback.heavyImpact();
        break;

      case 'handshake_ack':
        break;

      case 'session_ended':
        state = state.copyWith(
          phase: MentorPhase.aiDisconnected,
          isMicMuted: true,
          statusMessage:
              data['message'] as String? ?? 'جلسه مکالمه به پایان رسید.',
        );
        HapticFeedback.heavyImpact();
        break;

      case 'vad_pause':
        state = state.copyWith(
          statusMessage:
              data['message'] as String? ??
              'مکالمه به دلیل سکوت موقتاً متوقف شد.',
        );
        break;

      case 'vad_disconnect':
        state = state.copyWith(
          phase: MentorPhase.aiDisconnected,
          isMicMuted: true,
          statusMessage:
              data['message'] as String? ?? 'اتصال به دلیل عدم فعالیت قطع شد.',
        );
        break;

      default:
        break;
    }
  }

  final List<int> _pcmBuffer = [];

  Future<void> _onPlaybackCompleted() async {
    if (_isDisposed || !ref.mounted) return;
    if (state.phase != MentorPhase.receivingAudio) return;

    if (_isWaitingForTurnComplete) return;

    await Future.delayed(const Duration(milliseconds: 300));
    if (_isDisposed || !ref.mounted) return;
    _enterReadyState();
  }

  void _enterReadyState() {
    if (_isDisposed || !ref.mounted) return;
    _autoReconnectAttempts = 0;
    _autoRestartAttempts = 0;
    state = state.copyWith(
      phase: MentorPhase.ready,
      isMicMuted: false,
      amplitude: 0,
      clearStatusMessage: true,
    );
  }

  void _onAmplitude(double amplitude) {
    if (_isDisposed || !ref.mounted) return;
    if (state.isMicMuted ||
        !state.isUserTalking ||
        state.phase != MentorPhase.ready) {
      return;
    }
    state = state.copyWith(amplitude: amplitude);
  }

  void _onPcmChunk(List<int> chunk) {
    if (_isDisposed || !ref.mounted) return;
    if (state.isMicMuted ||
        !state.isUserTalking ||
        state.phase != MentorPhase.ready) {
      return;
    }
    _socket.sendAudioChunk(base64Encode(chunk));
  }
}
