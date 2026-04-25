import 'package:flutter/foundation.dart';

/// Search query data passed through Dropify data sources.
@immutable
class DropifyQuery {
  /// Creates a [DropifyQuery].
  const DropifyQuery({required this.rawText, required this.normalizedText});

  /// Creates a [DropifyQuery] from raw user input.
  factory DropifyQuery.fromRaw(String rawText) {
    return DropifyQuery(
      rawText: rawText,
      normalizedText: rawText.trim().toLowerCase(),
    );
  }

  /// The text exactly as entered by the user.
  final String rawText;

  /// The normalized text used by default filtering.
  final String normalizedText;

  /// Whether the query has no searchable text.
  bool get isEmpty => normalizedText.isEmpty;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DropifyQuery &&
            other.rawText == rawText &&
            other.normalizedText == normalizedText;
  }

  @override
  int get hashCode => Object.hash(rawText, normalizedText);

  @override
  String toString() {
    return 'DropifyQuery(rawText: $rawText, normalizedText: $normalizedText)';
  }
}
