import 'package:flutter/material.dart';

/// Responsive utility class for dynamic sizing based on screen dimensions
class Responsive {
  final BuildContext context;

  Responsive(this.context);

  /// Get screen width
  double get width => MediaQuery.of(context).size.width;

  /// Get screen height
  double get height => MediaQuery.of(context).size.height;

  /// Get responsive width percentage (0.0 - 1.0)
  double wp(double percentage) => width * percentage / 100;

  /// Get responsive height percentage (0.0 - 1.0)
  double hp(double percentage) => height * percentage / 100;

  /// Get responsive font size based on screen width
  /// Base size is for 375px width (iPhone SE)
  double sp(double baseSize) {
    final scale = width / 375.0;
    return baseSize * scale.clamp(0.8, 1.3);
  }

  /// Get responsive padding/margin
  double spacing(double baseSize) {
    final scale = width / 375.0;
    return baseSize * scale.clamp(0.85, 1.2);
  }

  /// Check if device is a tablet (width > 600)
  bool get isTablet => width > 600;

  /// Check if device is a phone
  bool get isPhone => width <= 600;

  /// Get responsive icon size
  double iconSize(double baseSize) {
    final scale = width / 375.0;
    return baseSize * scale.clamp(0.8, 1.4);
  }

  /// Get responsive border radius
  double radius(double baseSize) {
    final scale = width / 375.0;
    return baseSize * scale.clamp(0.9, 1.2);
  }

  /// Get responsive circular size (for buttons, avatars, etc.)
  double circularSize(double baseSize, {double min = 30, double max = 80}) {
    final scale = width / 375.0;
    return (baseSize * scale).clamp(min, max);
  }

  /// Get responsive card elevation
  double elevation(double baseElevation) {
    return isTablet ? baseElevation * 1.2 : baseElevation;
  }
}

/// Extension on BuildContext for easy access to Responsive utilities
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
}

/// Responsive text styles
class ResponsiveText {
  final BuildContext context;

  ResponsiveText(this.context);

  Responsive get _r => Responsive(context);

  /// Heading 1 - Large titles
  double get h1 => _r.sp(28);

  /// Heading 2 - Section headers
  double get h2 => _r.sp(24);

  /// Heading 3 - Card titles
  double get h3 => _r.sp(20);

  /// Heading 4 - Subheadings
  double get h4 => _r.sp(18);

  /// Body text - Regular content
  double get body => _r.sp(15);

  /// Body small - Secondary text
  double get bodySmall => _r.sp(13);

  /// Caption - Labels and hints
  double get caption => _r.sp(12);

  /// Tiny - Very small text
  double get tiny => _r.sp(10);
}

extension ResponsiveTextExtension on BuildContext {
  ResponsiveText get text => ResponsiveText(this);
}

/// Responsive spacing
class ResponsiveSpacing {
  final BuildContext context;

  ResponsiveSpacing(this.context);

  Responsive get _r => Responsive(context);

  /// Tiny spacing - 4px base
  double get xs => _r.spacing(4);

  /// Small spacing - 8px base
  double get sm => _r.spacing(8);

  /// Medium spacing - 16px base
  double get md => _r.spacing(16);

  /// Large spacing - 24px base
  double get lg => _r.spacing(24);

  /// Extra large spacing - 32px base
  double get xl => _r.spacing(32);

  /// Extra extra large spacing - 48px base
  double get xxl => _r.spacing(48);

  /// Horizontal padding for screen edges
  double get screenPadding => _r.spacing(24);

  /// Vertical spacing between sections
  double get sectionSpacing => _r.spacing(32);
}

extension ResponsiveSpacingExtension on BuildContext {
  ResponsiveSpacing get spacing => ResponsiveSpacing(this);
}
