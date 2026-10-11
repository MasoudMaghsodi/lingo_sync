// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard_sync_repository_impl.dart';

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
          IFlashcardSyncRepository,
          IFlashcardSyncRepository,
          IFlashcardSyncRepository
        >
    with $Provider<IFlashcardSyncRepository> {
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
  $ProviderElement<IFlashcardSyncRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IFlashcardSyncRepository create(Ref ref) {
    return flashcardSyncRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IFlashcardSyncRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IFlashcardSyncRepository>(value),
    );
  }
}

String _$flashcardSyncRepositoryHash() =>
    r'a9293b5fbc0a929803120e1926d7457cd7be34fe';
