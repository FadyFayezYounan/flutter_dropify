import 'package:flutter/material.dart';

/// Displays the empty state inside the Dropify menu.
class DropifyEmptyRow extends StatelessWidget {
  /// Creates an empty-state row.
  const DropifyEmptyRow({super.key, required this.text, required this.height});

  /// Text displayed for the empty state.
  final String text;

  /// Row height.
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: text,
      child: SizedBox(
        height: height,
        child: Center(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
