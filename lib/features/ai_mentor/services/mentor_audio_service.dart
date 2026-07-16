import 'dart:async';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

/// Pure audio I/O: microphone streaming + amplitude readings, and playing
/// raw PCM back as WAV. No idea what a "turn" or "mentor phase" is — the
/// controller decides when to start/stop listening and what to play.
class MentorAudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<Amplitude>? _ampSub;
  StreamSubscription<List<int>>? _pcmSub;
  StreamSubscription<PlayerState>? _playerSub;

  /// Starts the mic stream once for the whole session. Kept running even
  /// while muted — restarting hardware recording on every conversation
  /// turn is slow and can glitch; muting/unmuting is just a matter of
  /// whether the caller chooses to act on the callbacks below.
  Future<bool> startMicStream({
    required void Function(double amplitude) onAmplitude,
    required void Function(List<int> pcmChunk) onPcmChunk,
  }) async {
    if (!await _recorder.hasPermission()) return false;
    if (await _recorder.isRecording()) await _recorder.stop();

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _ampSub?.cancel();
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
          final normalized = (amp.current + 50).clamp(0.0, 50.0) / 50.0;
          onAmplitude(normalized);
        });

    _pcmSub?.cancel();
    _pcmSub = stream.listen((data) {
      if (data.isNotEmpty) onPcmChunk(data);
    });

    return true;
  }

  Future<void> stopMic() async {
    await _ampSub?.cancel();
    _ampSub = null;
    await _pcmSub?.cancel();
    _pcmSub = null;
    try {
      if (await _recorder.isRecording()) await _recorder.stop();
    } catch (_) {}
  }

  void onPlaybackCompleted(void Function() callback) {
    _playerSub?.cancel();
    _playerSub = _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) callback();
    });
  }

  Future<void> playPcm(List<int> pcmBytes, {int sampleRate = 24000}) async {
    final wav = _buildWav(pcmBytes, sampleRate);
    await _player.setAudioSource(_InMemoryWavSource(wav));
    _player.play();
  }

  Future<void> stopPlayback() => _player.stop();

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

  Future<void> dispose() async {
    await stopMic();
    await _playerSub?.cancel();
    await _player.dispose();
  }
}

// ignore: experimental_member_use
class _InMemoryWavSource extends StreamAudioSource {
  final Uint8List _bytes;
  _InMemoryWavSource(this._bytes);

  @override
  // ignore: experimental_member_use
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    // ignore: experimental_member_use
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}
