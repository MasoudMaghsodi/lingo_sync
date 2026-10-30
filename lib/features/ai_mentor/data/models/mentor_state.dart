/// The phase of a live mentor session. `fetchingData` and `waitingModel`
/// from the old version are gone: context fetching now happens entirely
/// server-side (see mentor-server.js), and the manual "force end turn"
/// feature that used `waitingModel` was disabled dead code that never
/// actually ran.
enum MentorPhase {
  connecting,
  settingUp,
  ready,
  receivingAudio,
  aiDisconnected,
  disconnected,
}

class AiMentorSessionState {
  final MentorPhase phase;
  final double amplitude;
  final bool isMicMuted;
  final String? statusMessage;

  const AiMentorSessionState({
    required this.phase,
    required this.amplitude,
    required this.isMicMuted,
    this.statusMessage,
  });

  const AiMentorSessionState.initial()
    : phase = MentorPhase.connecting,
      amplitude = 0,
      isMicMuted = true,
      statusMessage = null;

  AiMentorSessionState copyWith({
    MentorPhase? phase,
    double? amplitude,
    bool? isMicMuted,
    String? statusMessage,
    bool clearStatusMessage = false,
  }) {
    return AiMentorSessionState(
      phase: phase ?? this.phase,
      amplitude: amplitude ?? this.amplitude,
      isMicMuted: isMicMuted ?? this.isMicMuted,
      statusMessage: clearStatusMessage
          ? null
          : (statusMessage ?? this.statusMessage),
    );
  }
}
