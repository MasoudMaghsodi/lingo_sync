import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  @override
  AiMentorSessionState build() {
    _socket = MentorSocketService(
      onMessage: _handleServerMessage,
      onDisconnected: _handleDisconnect,
    );
    _audio = MentorAudioService();
    _audio.onPlaybackCompleted(_onPlaybackCompleted);

    ref.onDispose(() {
      _autoReconnectTimer?.cancel();
      _autoRestartTimer?.cancel();
      _audio.dispose();
      _socket.dispose();
    });

    _initSession();

    return const AiMentorSessionState.initial();
  }

  Future<void> _initSession() async {
    await _audio.startMicStream(
      onAmplitude: _onAmplitude,
      onPcmChunk: _onPcmChunk,
    );
    await _connect();
  }

  Future<void> _connect() async {
    state = state.copyWith(phase: MentorPhase.connecting);
    try {
      await _socket.connect(Uri.parse(AppConfig.mentorSocketUrl));
      _sendSetup();
    } on Exception catch (e) {
      logger.warning(
        'Mentor socket connection failed',
        error: e,
        context: 'AiMentorController',
      );
      _handleDisconnect();
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _sendSetup() {
    // در آینده بهتر است این توکن از طریق authRepository تامین شود
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      _handleDisconnect();
      return;
    }
    state = state.copyWith(phase: MentorPhase.settingUp);
    _socket.sendSetup(token);
  }

  void restartAiSession() {
    HapticFeedback.mediumImpact();
    _sendSetup();
  }

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
      case MentorPhase.receivingAudio:
        // 🚀 قابلیت قطع کردن حرف استاد با زدن روی گوی (Interrupt)
        HapticFeedback.heavyImpact();
        _interruptMentor();
        break;
      default:
        break;
    }
  }

  Future<void> _interruptMentor() async {
    _pcmBuffer.clear();
    _isWaitingForTurnComplete = false;
    await _audio.stopPlayback();
    // ارسال سیگنال به سرور که کاربر حرفت را قطع کرد (باید در سرور هندل شود)
    if (_socket.isOpen) {
      _socket.send({'type': 'client_interrupt'});
    }
    _enterReadyState();
  }

  void _handleDisconnect() {
    state = state.copyWith(phase: MentorPhase.disconnected, isMicMuted: true);
    _scheduleAutoReconnect();
  }

  void _scheduleAutoReconnect() {
    _autoReconnectTimer?.cancel();
    _autoReconnectAttempts++;
    final delay = Duration(seconds: _autoReconnectAttempts.clamp(1, 8));
    _autoReconnectTimer = Timer(delay, () {
      if (state.phase == MentorPhase.disconnected) {
        _connect();
      }
    });
  }

  void _scheduleAutoRestart() {
    _autoRestartTimer?.cancel();
    _autoRestartAttempts++;
    final delay = Duration(seconds: _autoRestartAttempts.clamp(1, 5));
    _autoRestartTimer = Timer(delay, () {
      if (state.phase == MentorPhase.aiDisconnected) {
        restartAiSession();
      }
    });
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

        // 🚀 انتقال دیکد کردن به پس‌زمینه (Isolate) برای جلوگیری از لگ زدن UI و قطع سوکت
        final String base64Data = data['data'] as String;
        if (base64Data.isNotEmpty) {
          final decodedBytes = await compute(base64Decode, base64Data);
          _pcmBuffer.addAll(decodedBytes);
        }
        break;

      case 'interrupt':
        _pcmBuffer.clear();
        _isWaitingForTurnComplete = false;
        await _audio.stopPlayback();
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

    // 🚀 اگر هنوز پیام turn_complete نیامده (مثلا وسط حرف مکث کرده)، میکروفون را باز نکن!
    if (_isWaitingForTurnComplete) return;

    await Future.delayed(const Duration(milliseconds: 500));
    _enterReadyState();
  }

  void _enterReadyState() {
    _autoReconnectAttempts = 0;
    _autoRestartAttempts = 0;
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

    // 🚀 تبدیل اینکد به پس‌زمینه برای روان شدن UI هنگام حرف زدن کاربر
    compute(base64Encode, chunk).then((encoded) {
      _socket.sendAudioChunk(encoded);
    });
  }
}
