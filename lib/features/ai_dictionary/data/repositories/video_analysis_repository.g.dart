// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_analysis_repository.dart';

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
          VideoAnalysisRepository,
          VideoAnalysisRepository,
          VideoAnalysisRepository
        >
    with $Provider<VideoAnalysisRepository> {
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
  $ProviderElement<VideoAnalysisRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VideoAnalysisRepository create(Ref ref) {
    return videoAnalysisRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoAnalysisRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoAnalysisRepository>(value),
    );
  }
}

String _$videoAnalysisRepositoryHash() =>
    r'e217bd1be75e4f3faa28ccab9d6ebedea5d14f86';
