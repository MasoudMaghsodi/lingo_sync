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

  const AiMentorSessionState({
    required this.phase,
    required this.amplitude,
    required this.isMicMuted,
  });

  const AiMentorSessionState.initial()
    : phase = MentorPhase.connecting,
      amplitude = 0,
      isMicMuted = true;

  AiMentorSessionState copyWith({
    MentorPhase? phase,
    double? amplitude,
    bool? isMicMuted,
  }) {
    return AiMentorSessionState(
      phase: phase ?? this.phase,
      amplitude: amplitude ?? this.amplitude,
      isMicMuted: isMicMuted ?? this.isMicMuted,
    );
  }
}
