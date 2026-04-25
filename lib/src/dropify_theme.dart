import 'package:flutter/material.dart';

/// Visual defaults for Dropify widgets.
class DropifyThemeData {
  /// Creates Dropify theme data.
  const DropifyThemeData({
    this.maxMenuHeight,
    this.menuElevation,
    this.menuBorderRadius,
    this.itemHeight,
    this.menuPadding,
    this.searchHintText,
    this.emptyText,
  });

  /// Practical defaults used when no override is provided.
  static const DropifyThemeData fallback = DropifyThemeData(
    maxMenuHeight: 280.0,
    menuElevation: 8.0,
    menuBorderRadius: BorderRadius.all(Radius.circular(12.0)),
    itemHeight: 48.0,
    menuPadding: EdgeInsets.all(8.0),
    searchHintText: 'Search',
    emptyText: 'No results',
  );

  /// Maximum height for the anchored menu.
  final double? maxMenuHeight;

  /// Elevation for the menu material.
  final double? menuElevation;

  /// Border radius for the menu material.
  final BorderRadius? menuBorderRadius;

  /// Height for each item row.
  final double? itemHeight;

  /// Padding inside the menu material.
  final EdgeInsetsGeometry? menuPadding;

  /// Hint text for the search input.
  final String? searchHintText;

  /// Default text for empty results.
  final String? emptyText;

  /// Returns a copy with selected fields replaced.
  DropifyThemeData copyWith({
    double? maxMenuHeight,
    double? menuElevation,
    BorderRadius? menuBorderRadius,
    double? itemHeight,
    EdgeInsetsGeometry? menuPadding,
    String? searchHintText,
    String? emptyText,
  }) {
    return DropifyThemeData(
      maxMenuHeight: maxMenuHeight ?? this.maxMenuHeight,
      menuElevation: menuElevation ?? this.menuElevation,
      menuBorderRadius: menuBorderRadius ?? this.menuBorderRadius,
      itemHeight: itemHeight ?? this.itemHeight,
      menuPadding: menuPadding ?? this.menuPadding,
      searchHintText: searchHintText ?? this.searchHintText,
      emptyText: emptyText ?? this.emptyText,
    );
  }

  /// Merges [other] over this theme data.
  DropifyThemeData merge(DropifyThemeData? other) {
    if (other == null) {
      return this;
    }
    return copyWith(
      maxMenuHeight: other.maxMenuHeight,
      menuElevation: other.menuElevation,
      menuBorderRadius: other.menuBorderRadius,
      itemHeight: other.itemHeight,
      menuPadding: other.menuPadding,
      searchHintText: other.searchHintText,
      emptyText: other.emptyText,
    );
  }
}
