// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pomodoro_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Pomodoro)
final pomodoroProvider = PomodoroProvider._();

final class PomodoroProvider
    extends $NotifierProvider<Pomodoro, PomodoroState> {
  PomodoroProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pomodoroProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pomodoroHash();

  @$internal
  @override
  Pomodoro create() => Pomodoro();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PomodoroState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PomodoroState>(value),
    );
  }
}

String _$pomodoroHash() => r'dc34ee8ed0519157d66a395701d38545288f777c';

abstract class _$Pomodoro extends $Notifier<PomodoroState> {
  PomodoroState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PomodoroState, PomodoroState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PomodoroState, PomodoroState>,
              PomodoroState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
