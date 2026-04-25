import 'package:flutter/material.dart';

/// Material shell for the anchored Dropify menu.
class DropifyOverlayPanel extends StatelessWidget {
  /// Creates a menu panel.
  const DropifyOverlayPanel({
    super.key,
    required this.elevation,
    required this.borderRadius,
    required this.padding,
    required this.child,
  });

  /// Menu material elevation.
  final double elevation;

  /// Menu border radius.
  final BorderRadius borderRadius;

  /// Inner menu padding.
  final EdgeInsetsGeometry padding;

  /// Panel contents.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}
