import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Displays the loading state inside the Dropify menu.
class DropifyLoadingRow extends StatelessWidget {
  /// Creates a loading-state row.
  const DropifyLoadingRow({
    super.key,
    required this.text,
    required this.height,
  });

  /// Text displayed for the loading state.
  final String text;

  /// Row height.
  final double height;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text));
    properties.add(DoubleProperty('height', height));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      liveRegion: true,
      child: SizedBox(
        height: height,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12.0,
            children: <Widget>[
              const SizedBox.square(
                dimension: 18.0,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              ),
              Text(text),
            ],
          ),
        ),
      ),
    );
  }
}
