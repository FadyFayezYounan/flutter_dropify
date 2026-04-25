import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Displays an async error state inside the Dropify menu.
class DropifyErrorRow extends StatelessWidget {
  /// Creates an error-state row.
  const DropifyErrorRow({
    super.key,
    required this.text,
    required this.height,
    required this.retryKey,
    required this.onRetry,
  });

  /// Text displayed for the error state.
  final String text;

  /// Row height.
  final double height;

  /// Stable key assigned to the retry button.
  final Key retryKey;

  /// Called when retry is tapped.
  final VoidCallback onRetry;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text));
    properties.add(DoubleProperty('height', height));
    properties.add(DiagnosticsProperty<Key>('retryKey', retryKey));
    properties.add(ObjectFlagProperty<VoidCallback>.has('onRetry', onRetry));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: text,
      liveRegion: true,
      child: SizedBox(
        height: height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12.0,
          children: <Widget>[
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            TextButton(
              key: retryKey,
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
