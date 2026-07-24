// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_mentor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AiMentorController)
final aiMentorControllerProvider = AiMentorControllerProvider._();

final class AiMentorControllerProvider
    extends $NotifierProvider<AiMentorController, AiMentorSessionState> {
  AiMentorControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiMentorControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiMentorControllerHash();

  @$internal
  @override
  AiMentorController create() => AiMentorController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiMentorSessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiMentorSessionState>(value),
    );
  }
}

String _$aiMentorControllerHash() =>
    r'c57e10a0e3867e3c1941bcb4e93d9a099b8396bc';

abstract class _$AiMentorController extends $Notifier<AiMentorSessionState> {
  AiMentorSessionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AiMentorSessionState, AiMentorSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AiMentorSessionState, AiMentorSessionState>,
              AiMentorSessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
