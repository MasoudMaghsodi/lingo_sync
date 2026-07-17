// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard_sync_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(flashcardSyncRepository)
final flashcardSyncRepositoryProvider = FlashcardSyncRepositoryProvider._();

final class FlashcardSyncRepositoryProvider
    extends
        $FunctionalProvider<
          FlashcardSyncRepository,
          FlashcardSyncRepository,
          FlashcardSyncRepository
        >
    with $Provider<FlashcardSyncRepository> {
  FlashcardSyncRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flashcardSyncRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flashcardSyncRepositoryHash();

  @$internal
  @override
  $ProviderElement<FlashcardSyncRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlashcardSyncRepository create(Ref ref) {
    return flashcardSyncRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlashcardSyncRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlashcardSyncRepository>(value),
    );
  }
}

String _$flashcardSyncRepositoryHash() =>
    r'cddc649c38a107a1401d81ea85e8831202e3799a';
