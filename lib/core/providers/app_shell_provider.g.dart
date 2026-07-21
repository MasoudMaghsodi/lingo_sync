// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_shell_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A single, app-lifetime `GlobalKey` for the outer `Scaffold` owned by
/// `MainNavigation`. Every top-level tab page (Daily Tasks, Dictionary,
/// Flashcards, Leaderboard) lives inside its OWN nested `Scaffold` (for
/// its own AppBar/FAB), so `Scaffold.of(context)` called from within one
/// of those pages resolves to that page's own Scaffold — not the outer
/// one that owns the settings drawer. Sharing this key through a provider
/// is what lets any tab page's AppBar open the outer drawer without
/// restructuring the whole navigation shell into a single Scaffold.

@ProviderFor(appShellScaffoldKey)
final appShellScaffoldKeyProvider = AppShellScaffoldKeyProvider._();

/// A single, app-lifetime `GlobalKey` for the outer `Scaffold` owned by
/// `MainNavigation`. Every top-level tab page (Daily Tasks, Dictionary,
/// Flashcards, Leaderboard) lives inside its OWN nested `Scaffold` (for
/// its own AppBar/FAB), so `Scaffold.of(context)` called from within one
/// of those pages resolves to that page's own Scaffold — not the outer
/// one that owns the settings drawer. Sharing this key through a provider
/// is what lets any tab page's AppBar open the outer drawer without
/// restructuring the whole navigation shell into a single Scaffold.

final class AppShellScaffoldKeyProvider
    extends
        $FunctionalProvider<
          GlobalKey<ScaffoldState>,
          GlobalKey<ScaffoldState>,
          GlobalKey<ScaffoldState>
        >
    with $Provider<GlobalKey<ScaffoldState>> {
  /// A single, app-lifetime `GlobalKey` for the outer `Scaffold` owned by
  /// `MainNavigation`. Every top-level tab page (Daily Tasks, Dictionary,
  /// Flashcards, Leaderboard) lives inside its OWN nested `Scaffold` (for
  /// its own AppBar/FAB), so `Scaffold.of(context)` called from within one
  /// of those pages resolves to that page's own Scaffold — not the outer
  /// one that owns the settings drawer. Sharing this key through a provider
  /// is what lets any tab page's AppBar open the outer drawer without
  /// restructuring the whole navigation shell into a single Scaffold.
  AppShellScaffoldKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appShellScaffoldKeyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appShellScaffoldKeyHash();

  @$internal
  @override
  $ProviderElement<GlobalKey<ScaffoldState>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GlobalKey<ScaffoldState> create(Ref ref) {
    return appShellScaffoldKey(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlobalKey<ScaffoldState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlobalKey<ScaffoldState>>(value),
    );
  }
}

String _$appShellScaffoldKeyHash() =>
    r'd03f2b66ca6c3fd84e4a2011113c75d93b66c49e';
