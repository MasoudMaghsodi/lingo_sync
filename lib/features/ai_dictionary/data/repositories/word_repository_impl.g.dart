// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(wordRepository)
final wordRepositoryProvider = WordRepositoryProvider._();

final class WordRepositoryProvider
    extends
        $FunctionalProvider<IWordRepository, IWordRepository, IWordRepository>
    with $Provider<IWordRepository> {
  WordRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wordRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wordRepositoryHash();

  @$internal
  @override
  $ProviderElement<IWordRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IWordRepository create(Ref ref) {
    return wordRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IWordRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IWordRepository>(value),
    );
  }
}

String _$wordRepositoryHash() => r'f1434254548a3dbe751069df6204e9416bde3aa4';
