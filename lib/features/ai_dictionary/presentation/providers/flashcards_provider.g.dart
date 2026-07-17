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
    extends $AsyncNotifierProvider<Flashcards, List<Map<String, dynamic>>> {
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

String _$flashcardsHash() => r'a04ec5ce2011fd018b62a47985904daea594c14e';

abstract class _$Flashcards extends $AsyncNotifier<List<Map<String, dynamic>>> {
  FutureOr<List<Map<String, dynamic>>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<Map<String, dynamic>>>,
              List<Map<String, dynamic>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<Map<String, dynamic>>>,
                List<Map<String, dynamic>>
              >,
              AsyncValue<List<Map<String, dynamic>>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
