// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_server_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(aiServerClient)
final aiServerClientProvider = AiServerClientProvider._();

final class AiServerClientProvider
    extends $FunctionalProvider<AiServerClient, AiServerClient, AiServerClient>
    with $Provider<AiServerClient> {
  AiServerClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiServerClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiServerClientHash();

  @$internal
  @override
  $ProviderElement<AiServerClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AiServerClient create(Ref ref) {
    return aiServerClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiServerClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiServerClient>(value),
    );
  }
}

String _$aiServerClientHash() => r'062bcaa77e0fbed7c5a6c995d9bef6f120a91c54';
