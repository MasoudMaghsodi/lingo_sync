// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcards_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Flashcards)
final flashcardsProvider = FlashcardsProvider._();

final class FlashcardsProvider
    extends $AsyncNotifierProvider<Flashcards, List<FlashcardEntry>> {
  FlashcardsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flashcardsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flashcardsHash();

  @$internal
  @override
  Flashcards create() => Flashcards();
}

String _$flashcardsHash() => r'97fab876e74a689916069d2e366548ce420718c2';

abstract class _$Flashcards extends $AsyncNotifier<List<FlashcardEntry>> {
  FutureOr<List<FlashcardEntry>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<FlashcardEntry>>, List<FlashcardEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<FlashcardEntry>>,
                List<FlashcardEntry>
              >,
              AsyncValue<List<FlashcardEntry>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
