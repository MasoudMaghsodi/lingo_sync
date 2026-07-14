import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart'; // 🚀 بازگشت مقتدرانه به just_audio
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/settings_provider.dart';

enum MentorState {
  fetchingData,
  connecting,
  settingUp,
  ready,
  waitingModel,
  receivingAudio,
  aiDisconnected,
  disconnected,
}

// 🚀 سورس فایل کاملاً امن در مموری بدون باگ ContentLength
// ignore: experimental_member_use
class ExactStreamAudioSource extends StreamAudioSource {
  final Uint8List _bytes;
  ExactStreamAudioSource(this._bytes);

  @override
  // ignore: experimental_member_use
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    // ignore: experimental_member_use
    return StreamAudioResponse(
      sourceLength: _bytes.length, // طول دقیق و واقعی
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}

class AiMentorSheet extends ConsumerStatefulWidget {
  const AiMentorSheet({super.key});
  @override
  ConsumerState<AiMentorSheet> createState() => _AiMentorSheetState();
}

class _AiMentorSheetState extends ConsumerState<AiMentorSheet>
    with SingleTickerProviderStateMixin {
  WebSocketChannel? _channel;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription<Amplitude>? _amplitudeSub;
  StreamSubscription<List<int>>? _audioStreamSub;
  StreamSubscription? _wsSubscription;
  StreamSubscription? _playerStateSub;

  MentorState _currentState = MentorState.fetchingData;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  double _currentAmplitude = 0.0;
  bool _isMicMuted = true;
  bool _isUserSpeaking = false;

  Timer? _pingTimer;
  Timer? _pongTimeoutTimer;
  Timer? _silenceTimer; // 🚀 تایمر VAD لوکال ۲ ثانیه‌ای

  final List<int> _pcmBuffer = [];
  Map<String, dynamic> _userData = {};

  void _changeState(MentorState newState) {
    if (!mounted || _currentState == newState) return;
    setState(() => _currentState = newState);
  }

  void _safeSend(String message) {
    if (_channel != null && _channel!.closeCode == null) {
      try {
        _channel!.sink.add(message);
      } catch (_) {}
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 🚀 کنترل دقیق پایان صحبت هوش مصنوعی
    _playerStateSub = _audioPlayer.playerStateStream.listen((state) async {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        if (_currentState == MentorState.receivingAudio) {
          _changeState(MentorState.ready);
          // 🚀 500 میلی‌ثانیه تاخیر حیاتی برای جلوگیری از اکو شدن آخرین کلمه استاد
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) setState(() => _isMicMuted = false);
        }
      }
    });

    _initSession();
  }

  Future<void> _initSession() async {
    await _fetchFreshUserData();
    await _startRecordingHardware();
    await _connectWebSocket();
  }

  Future<void> _fetchFreshUserData() async {
    _changeState(MentorState.fetchingData);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final profile = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle();
        _userData = {"name": profile?['full_name'] ?? "کاربر"};
      }
    } catch (_) {}
  }

  Future<void> _connectWebSocket() async {
    _changeState(MentorState.connecting);
    _clearTimers();

    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse('wss://safer.privatepath.ir/ws'),
      );
      await _channel!.ready.timeout(const Duration(seconds: 10));

      _sendSetupRequest();

      // 🚀 پینگ هر ۱۵ ثانیه و تایم اوت ۱۰ ثانیه (بسیار پایدار برای اینترنت موبایل)
      _pingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        if (!mounted || _currentState == MentorState.disconnected) {
          timer.cancel();
          return;
        }
        _safeSend(jsonEncode({"type": "ping"}));

        _pongTimeoutTimer?.cancel();
        _pongTimeoutTimer = Timer(
          const Duration(seconds: 10),
          () => _handleDisconnect(),
        );
      });

      _wsSubscription?.cancel();
      _wsSubscription = _channel!.stream.listen(
        (message) {
          if (mounted) _handleServerMessage(message);
        },
        onDone: () => _handleDisconnect(),
        onError: (_) => _handleDisconnect(),
      );
    } catch (e) {
      _handleDisconnect();
    }
  }

  void _sendSetupRequest() {
    _changeState(MentorState.settingUp);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    _safeSend(
      jsonEncode({"type": "setup", "userId": userId, "context": _userData}),
    );
  }

  void _restartAiSession() {
    HapticFeedback.mediumImpact();
    _sendSetupRequest();
  }

  void _handleDisconnect() {
    if (!mounted) return;
    _changeState(MentorState.disconnected);
    setState(() => _isMicMuted = true);
    _clearTimers();
  }

  Future<void> _startRecordingHardware() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        if (await _audioRecorder.isRecording()) await _audioRecorder.stop();

        final stream = await _audioRecorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          ),
        );

        _amplitudeSub?.cancel();
        _amplitudeSub = _audioRecorder
            .onAmplitudeChanged(const Duration(milliseconds: 100))
            .listen((amp) {
              if (!mounted ||
                  _isMicMuted ||
                  _currentState != MentorState.ready) {
                return;
              }

              final amplitude = (amp.current + 50).clamp(0.0, 50.0) / 50.0;
              setState(() => _currentAmplitude = amplitude);

              // 🚀 VAD محلی: 2 ثانیه سکوت = پایان صحبت
              if (amplitude > 0.15) {
                _silenceTimer?.cancel();
                _isUserSpeaking = true;
              } else {
                if (_isUserSpeaking &&
                    (_silenceTimer == null || !_silenceTimer!.isActive)) {
                  _silenceTimer = Timer(const Duration(milliseconds: 2000), () {
                    // _forceSendTurnComplete();
                    _isUserSpeaking = false;
                  });
                }
              }
            });

        _audioStreamSub?.cancel();
        _audioStreamSub = stream.listen((data) {
          if (!mounted ||
              data.isEmpty ||
              _isMicMuted ||
              _currentState != MentorState.ready) {
            return;
          }
          _safeSend(jsonEncode({"type": "audio", "data": base64Encode(data)}));
        });
      }
    } catch (_) {}
  }

  void _clearTimers() {
    _pingTimer?.cancel();
    _pongTimeoutTimer?.cancel();
    _silenceTimer?.cancel();
  }

  Future<void> _stopHardware() async {
    _clearTimers();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    await _audioStreamSub?.cancel();
    _audioStreamSub = null;
    try {
      if (await _audioRecorder.isRecording()) await _audioRecorder.stop();
    } catch (_) {}
  }

  // void _forceSendTurnComplete() {
  //   if (_currentState == MentorState.ready) {
  //     _silenceTimer?.cancel();
  //     _changeState(MentorState.waitingModel);
  //     setState(() => _isMicMuted = true);
  //     _safeSend(jsonEncode({"type": "force_end_turn"}));
  //   }
  // }

  void _transitionToReady() {
    if (mounted &&
        (_currentState == MentorState.receivingAudio ||
            _currentState == MentorState.waitingModel ||
            _currentState == MentorState.settingUp)) {
      _changeState(MentorState.ready);
      setState(() {
        _isMicMuted = false;
        _currentAmplitude = 0.0;
      });
    }
  }

  // 🚀 سازنده دقیق فایل WAV برای جلوگیری از ارور just_audio
  Uint8List _buildWav(List<int> pcmBytes, int sampleRate) {
    final pcmLen = pcmBytes.length;
    final byteRate = sampleRate * 2;
    final header = Uint8List(44);
    final bData = ByteData.view(header.buffer);

    bData.setUint32(0, 0x52494646, Endian.big);
    bData.setUint32(4, pcmLen + 36, Endian.little);
    bData.setUint32(8, 0x57415645, Endian.big);
    bData.setUint32(12, 0x666D7420, Endian.big);
    bData.setUint32(16, 16, Endian.little);
    bData.setUint16(20, 1, Endian.little);
    bData.setUint16(22, 1, Endian.little);
    bData.setUint32(24, sampleRate, Endian.little);
    bData.setUint32(28, byteRate, Endian.little);
    bData.setUint16(32, 2, Endian.little);
    bData.setUint16(34, 16, Endian.little);
    bData.setUint32(36, 0x64617461, Endian.big);
    bData.setUint32(40, pcmLen, Endian.little);

    final result = Uint8List(44 + pcmLen);
    result.setAll(0, header);
    result.setAll(44, pcmBytes);
    return result;
  }

  void _handleServerMessage(dynamic message) async {
    try {
      final data = jsonDecode(message.toString());

      switch (data['type']) {
        case 'pong':
          _pongTimeoutTimer?.cancel();
          break;

        case 'ready':
          _transitionToReady();
          break;

        case 'ai_disconnected':
          _changeState(MentorState.aiDisconnected);
          setState(() => _isMicMuted = true);
          break;

        case 'audio':
          if (_currentState != MentorState.receivingAudio) {
            _changeState(MentorState.receivingAudio);
            setState(() => _isMicMuted = true);
          }
          // فقط بایت‌ها را جمع می‌کنیم
          _pcmBuffer.addAll(base64Decode(data['data']));
          break;

        case 'interrupt':
          _pcmBuffer.clear();
          await _audioPlayer.stop();
          _transitionToReady();
          break;

        case 'turn_complete':
          // 🚀 به محض پایانِ کامل کلمات مدل، فایل ساخته و پخش می‌شود
          if (_pcmBuffer.isNotEmpty) {
            _changeState(MentorState.receivingAudio);
            setState(() => _isMicMuted = true);

            final wavData = _buildWav(_pcmBuffer, 24000);
            _pcmBuffer.clear();

            await _audioPlayer.setAudioSource(ExactStreamAudioSource(wavData));
            _audioPlayer.play();
          } else {
            _transitionToReady();
          }
          break;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _stopHardware();
    _playerStateSub?.cancel();
    _wsSubscription?.cancel();
    _channel?.sink.close();
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPersian = ref.watch(isPersianProvider);

    final speakingScale =
        (_currentState == MentorState.ready ||
            _currentState == MentorState.receivingAudio)
        ? 1.0 + (_currentAmplitude * 0.4)
        : _pulseAnimation.value;

    String statusText = _currentState == MentorState.fetchingData
        ? (isPersian ? 'در حال دریافت اطلاعات...' : 'Fetching Data...')
        : _currentState == MentorState.connecting
        ? (isPersian ? 'در حال اتصال...' : 'Connecting...')
        : _currentState == MentorState.settingUp
        ? (isPersian ? 'در حال آماده‌سازی...' : 'Initializing...')
        : _currentState == MentorState.waitingModel
        ? (isPersian ? 'در حال پردازش...' : 'Thinking...')
        : _currentState == MentorState.receivingAudio
        ? (isPersian ? 'استاد صحبت می‌کند' : 'Mentor is speaking')
        : _currentState == MentorState.aiDisconnected
        ? (isPersian
              ? 'سشن پایان یافت (لمس برای شروع مجدد)'
              : 'Session Ended (Tap to restart)')
        : _currentState == MentorState.disconnected
        ? (isPersian ? 'اینترنت قطع شد!' : 'No Internet Connection!')
        : (isPersian ? 'استاد می‌شنود...' : 'Mentor is listening...');

    Color orbColor =
        (_currentState == MentorState.fetchingData ||
            _currentState == MentorState.connecting ||
            _currentState == MentorState.settingUp)
        ? Colors.blueAccent
        : _currentState == MentorState.waitingModel
        ? Colors.orangeAccent
        : _currentState == MentorState.receivingAudio
        ? Colors.tealAccent.shade400
        : (_currentState == MentorState.aiDisconnected ||
              _currentState == MentorState.disconnected)
        ? Colors.redAccent
        : Colors.deepPurpleAccent.shade200;

    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: theme.colorScheme.surface.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: orbColor,
                    ),
                  ),
                  const SizedBox(height: 50),
                  GestureDetector(
                    onTap: () {
                      if (_currentState == MentorState.aiDisconnected) {
                        _restartAiSession();
                      } else if (_currentState == MentorState.disconnected)
                        // ignore: curly_braces_in_flow_control_structures
                        _initSession();
                      else if (_currentState == MentorState.ready) {
                        HapticFeedback.lightImpact();
                        // _forceSendTurnComplete();
                      }
                    },
                    child: AnimatedScale(
                      scale: speakingScale,
                      duration: const Duration(milliseconds: 100),
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              orbColor.withValues(alpha: 0.5),
                              orbColor.withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: orbColor.withValues(alpha: 0.4),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _currentState == MentorState.aiDisconnected ||
                                    _currentState == MentorState.disconnected
                                ? Icons.refresh_rounded
                                : Icons.mic_none_rounded,
                            color: theme.colorScheme.surface,
                            size: 45,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
