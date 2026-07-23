import 'package:flutter/material.dart';

/// Extension methods on BuildContext for convenient access to common utilities.
///
/// This provides shortcuts to theme, size, and navigator information
/// without needing to call Theme.of(), MediaQuery.of() repeatedly.
extension BuildContextExtensions on BuildContext {
  // ========================
  // Theme Access
  // ========================

  /// Get the current theme data
  ThemeData get theme => Theme.of(this);

  /// Get the current text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get the current color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Get primary color from theme
  Color get primaryColor => Theme.of(this).primaryColor;

  /// Get surface color from theme
  Color get surfaceColor => Theme.of(this).colorScheme.surface;

  /// Get error color from theme
  Color get errorColor => Theme.of(this).colorScheme.error;

  /// Check if dark mode is enabled
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // ========================
  // Media Query Access
  // ========================

  /// Get device size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get device width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get device height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get device padding (for notches, etc.)
  EdgeInsets get devicePadding => MediaQuery.of(this).padding;

  /// Get device view insets (for keyboards, etc.)
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  /// Get device pixel ratio
  double get devicePixelRatio => MediaQuery.of(this).devicePixelRatio;

  /// Check if device is in landscape mode
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;

  /// Check if device is in portrait mode
  bool get isPortrait =>
      MediaQuery.of(this).orientation == Orientation.portrait;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => viewInsets.bottom > 0;

  /// Get keyboard height
  double get keyboardHeight => viewInsets.bottom;

  /// Check if device is small screen (< 600px width)
  bool get isSmallScreen => screenWidth < 600;

  /// Check if device is medium screen (600-900px width)
  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 900;

  /// Check if device is large screen (>= 900px width)
  bool get isLargeScreen => screenWidth >= 900;

  // ========================
  // Navigator Access
  // ========================

  /// Get current navigator state
  NavigatorState get navigator => Navigator.of(this);

  /// Push a new route
  Future<dynamic> pushRoute(Route route) => navigator.push(route);

  /// Push named route
  Future<dynamic> pushNamed(String routeName, {Object? arguments}) =>
      navigator.pushNamed(routeName, arguments: arguments);

  /// Replace current route
  void replaceRoute(Route newRoute) {
    final current = currentRoute;
    if (current != null) {
      navigator.replace(oldRoute: current, newRoute: newRoute);
    }
  }

  /// Replace named route
  Future<dynamic> replaceNamed(String routeName, {Object? arguments}) =>
      navigator.pushReplacementNamed(routeName, arguments: arguments);

  /// Get current route
  Route? get currentRoute {
    Route? currentRoute;
    navigator.popUntil((route) {
      currentRoute = route;
      return true;
    });
    return currentRoute;
  }

  /// Pop current route
  void pop<T extends Object?>([T? result]) => navigator.pop(result);

  /// Check if navigator can pop
  bool canPop() => navigator.canPop();

  /// Pop until named route
  void popUntilNamed(String routeName) =>
      navigator.popUntil(ModalRoute.withName(routeName));

  // ========================
  // Focus & Keyboard
  // ========================

  /// Unfocus any focused widget
  void unfocusKeyboard() {
    FocusScope.of(this).unfocus();
  }

  /// Request focus for a node
  void requestFocus(FocusNode node) {
    FocusScope.of(this).requestFocus(node);
  }

  // ========================
  // Snackbar & Dialog
  // ========================

  /// Show a snackbar
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    return ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), duration: duration, action: action),
    );
  }

  /// Show error snackbar
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showErrorSnackBar(
    String message,
  ) {
    return ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorColor,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Show success snackbar
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSuccessSnackBar(
    String message,
  ) {
    return ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show confirmation dialog
  Future<bool?> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'تایید',
    String cancelText = 'انصراف',
  }) {
    return showDialog<bool>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Show info dialog
  Future<void> showInfoDialog({
    required String title,
    required String message,
    String buttonText = 'باشه',
  }) {
    return showDialog(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
