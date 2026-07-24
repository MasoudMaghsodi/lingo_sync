// Exporting modular constants
export 'business_constants.dart';
export 'network_constants.dart';
export 'storage_constants.dart';
export 'ui_constants.dart';

/// Deprecated: Use specific constant classes instead (UIConstants, NetworkConstants, etc.)
@Deprecated(
  'Use specific constant classes instead. This will be removed in future versions.',
)
abstract final class AppConstants {
  // Empty class just to prevent immediate build failure if directly referenced.
  // The goal is to migrate all AppConstants.* calls to their modular counterparts.
}
