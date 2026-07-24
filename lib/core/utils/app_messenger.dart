import 'package:flutter/material.dart';

/// Lets layers without a Scaffold ancestor (like AuthGate, which sits
/// directly under MaterialApp) still surface a SnackBar. Wire this into
/// MaterialApp(scaffoldMessengerKey: rootScaffoldMessengerKey).
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
