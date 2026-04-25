import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Search input displayed at the top of a Dropify menu.
class DropifySearchInput extends StatelessWidget {
  /// Creates a search input.
  const DropifySearchInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.inputKey,
    required this.hintText,
  });

  /// Controller for the search text.
  final TextEditingController controller;

  /// Focus node for the search field.
  final FocusNode focusNode;

  /// Stable key assigned to the editable search field.
  final Key inputKey;

  /// Placeholder text.
  final String hintText;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<TextEditingController>('controller', controller),
    );
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode));
    properties.add(DiagnosticsProperty<Key>('inputKey', inputKey));
    properties.add(StringProperty('hintText', hintText));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: inputKey,
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
      ),
    );
  }
}
