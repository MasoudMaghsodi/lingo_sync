// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dictionary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Dictionary)
final dictionaryProvider = DictionaryProvider._();

final class DictionaryProvider
    extends $NotifierProvider<Dictionary, AsyncValue<WordAnalysis?>> {
  DictionaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dictionaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dictionaryHash();

  @$internal
  @override
  Dictionary create() => Dictionary();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<WordAnalysis?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<WordAnalysis?>>(value),
    );
  }
}

String _$dictionaryHash() => r'84f994e6a7a96f715730b8e82101e5f891fa5654';

abstract class _$Dictionary extends $Notifier<AsyncValue<WordAnalysis?>> {
  AsyncValue<WordAnalysis?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<WordAnalysis?>, AsyncValue<WordAnalysis?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WordAnalysis?>, AsyncValue<WordAnalysis?>>,
              AsyncValue<WordAnalysis?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(VideoProcessing)
final videoProcessingProvider = VideoProcessingProvider._();

final class VideoProcessingProvider
    extends $NotifierProvider<VideoProcessing, AsyncValue<VideoAnalysis?>> {
  VideoProcessingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoProcessingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoProcessingHash();

  @$internal
  @override
  VideoProcessing create() => VideoProcessing();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<VideoAnalysis?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<VideoAnalysis?>>(value),
    );
  }
}

String _$videoProcessingHash() => r'e31dd7342c56f822c923e9a38ae14b46c6d3ef9b';

abstract class _$VideoProcessing extends $Notifier<AsyncValue<VideoAnalysis?>> {
  AsyncValue<VideoAnalysis?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<VideoAnalysis?>, AsyncValue<VideoAnalysis?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<VideoAnalysis?>,
                AsyncValue<VideoAnalysis?>
              >,
              AsyncValue<VideoAnalysis?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
