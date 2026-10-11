// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_analysis_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(videoAnalysisRepository)
final videoAnalysisRepositoryProvider = VideoAnalysisRepositoryProvider._();

final class VideoAnalysisRepositoryProvider
    extends
        $FunctionalProvider<
          IVideoAnalysisRepository,
          IVideoAnalysisRepository,
          IVideoAnalysisRepository
        >
    with $Provider<IVideoAnalysisRepository> {
  VideoAnalysisRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoAnalysisRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoAnalysisRepositoryHash();

  @$internal
  @override
  $ProviderElement<IVideoAnalysisRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IVideoAnalysisRepository create(Ref ref) {
    return videoAnalysisRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IVideoAnalysisRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IVideoAnalysisRepository>(value),
    );
  }
}

String _$videoAnalysisRepositoryHash() =>
    r'de391776002f27ca23aaea4c516304c5861a2591';
