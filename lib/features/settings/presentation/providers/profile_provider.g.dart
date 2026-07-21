// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live view of the current user's profile + stats, merged. Used by the
/// settings drawer to show name/email/avatar/level/stats, and kept alive
/// so it doesn't rebuild the stream subscription every time the drawer is
/// opened and closed.

@ProviderFor(currentUserProfile)
final currentUserProfileProvider = CurrentUserProfileProvider._();

/// Live view of the current user's profile + stats, merged. Used by the
/// settings drawer to show name/email/avatar/level/stats, and kept alive
/// so it doesn't rebuild the stream subscription every time the drawer is
/// opened and closed.

final class CurrentUserProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfile>,
          UserProfile,
          Stream<UserProfile>
        >
    with $FutureModifier<UserProfile>, $StreamProvider<UserProfile> {
  /// Live view of the current user's profile + stats, merged. Used by the
  /// settings drawer to show name/email/avatar/level/stats, and kept alive
  /// so it doesn't rebuild the stream subscription every time the drawer is
  /// opened and closed.
  CurrentUserProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProfileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserProfileHash();

  @$internal
  @override
  $StreamProviderElement<UserProfile> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<UserProfile> create(Ref ref) {
    return currentUserProfile(ref);
  }
}

String _$currentUserProfileHash() =>
    r'b8e911fb6ea8f65414748d86071d21863589b1e7';
