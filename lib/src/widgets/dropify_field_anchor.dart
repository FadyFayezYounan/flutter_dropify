import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The tappable field that anchors a Dropify menu.
class DropifyFieldAnchor extends StatelessWidget {
  /// Creates a Dropify field anchor.
  const DropifyFieldAnchor({
    super.key,
    required this.enabled,
    required this.isOpen,
    required this.onTap,
    this.label,
    this.hintText,
  });

  /// Whether the field can be opened.
  final bool enabled;

  /// Whether the menu is currently open.
  final bool isOpen;

  /// Called when the field is tapped.
  final VoidCallback? onTap;

  /// Selected label displayed by the field.
  final String? label;

  /// Placeholder text displayed when no value is selected.
  final String? hintText;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty('enabled', value: enabled, ifFalse: 'disabled'),
    );
    properties.add(FlagProperty('isOpen', value: isOpen, ifTrue: 'open'));
    properties.add(ObjectFlagProperty<VoidCallback?>.has('onTap', onTap));
    properties.add(StringProperty('label', label, defaultValue: null));
    properties.add(StringProperty('hintText', hintText, defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      expanded: isOpen,
      label: label ?? hintText,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: InputDecorator(
          isEmpty: label == null,
          decoration: InputDecoration(
            enabled: enabled,
            hintText: hintText,
            suffixIcon: Icon(
              isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            ),
          ),
          child: label == null ? const SizedBox.shrink() : Text(label!),
        ),
      ),
    );
  }
}
