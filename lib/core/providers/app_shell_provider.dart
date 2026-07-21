import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_shell_provider.g.dart';

/// A single, app-lifetime `GlobalKey` for the outer `Scaffold` owned by
/// `MainNavigation`. Every top-level tab page (Daily Tasks, Dictionary,
/// Flashcards, Leaderboard) lives inside its OWN nested `Scaffold` (for
/// its own AppBar/FAB), so `Scaffold.of(context)` called from within one
/// of those pages resolves to that page's own Scaffold — not the outer
/// one that owns the settings drawer. Sharing this key through a provider
/// is what lets any tab page's AppBar open the outer drawer without
/// restructuring the whole navigation shell into a single Scaffold.
@Riverpod(keepAlive: true)
GlobalKey<ScaffoldState> appShellScaffoldKey(Ref ref) {
  return GlobalKey<ScaffoldState>();
}
