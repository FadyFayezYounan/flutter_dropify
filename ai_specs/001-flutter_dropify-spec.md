<goal>
Build `flutter_dropify` into a production-ready Flutter package for app developers who need reusable, typed, customizable dropdown components without rebuilding search, async loading, pagination, selection, validation, and theming logic in every app.

The first implementation should deliver a staged v0.1 that replaces the generated `Calculator` placeholder with a coherent dropdown API, reusable internals, package tests, an example app, and documentation. The API must be simple for common cases while supporting advanced combinations such as a multi-select paginated dropdown.
</goal>

<background>
This repository is a Flutter package, not a full app. The package entrypoint is `./lib/flutter_dropify.dart`. The generated example app lives under `./example/` and currently does not demonstrate the package.

Current state:
1. `./lib/flutter_dropify.dart` exports only a placeholder `Calculator` class and has an unused `package:flutter/material.dart` import.
2. `./test/flutter_dropify_test.dart` tests only the placeholder `Calculator` API.
3. `./example/lib/main.dart` is the stock Flutter counter app and uses Dart 3.10 dot shorthand.
4. `./README.md` and `./CHANGELOG.md` are generated placeholders.
5. `./refrences/` is intentionally misspelled and contains commented Flutter framework reference source.

Relevant reference files to examine before implementation:
1. `./ai_specs/001-flutter_dropify.md` for the original product intent.
2. `./pubspec.yaml` for package metadata, SDK constraints, and dependency policy.
3. `./lib/flutter_dropify.dart` for the package entrypoint to replace.
4. `./test/flutter_dropify_test.dart` for the placeholder tests to replace.
5. `./example/pubspec.yaml`, `./example/lib/main.dart`, and `./example/test/widget_test.dart` when wiring the demo app.
6. `./refrences/flutter_raw_menu_anchor.dart` for the modern anchored overlay primitive and `MenuController` behavior.
7. `./refrences/flutter_menu_anchor.dart` for Material menu anchoring, tap regions, focus traversal, and menu style ideas.
8. `./refrences/flutter_dropdown_menu.dart` for `TextField` anchor, filtering/search naming, and input decoration ideas.
9. `./refrences/flutter_dropdown_button.dart` for route sizing, menu limits, initial scroll offset, and selected item alignment ideas.

Modern presentation direction:
Use a custom anchored overlay built around Flutter's modern menu/overlay primitives, especially `RawMenuAnchor` plus `MenuController`, because it allows a custom overlay body with search input, loading/error/empty rows, a scrollable paginated list, and multi-select controls. Treat `DropdownMenu` and `MenuAnchor` as design references, not as the primary implementation, because fixed `dropdownMenuEntries` APIs are too restrictive for async pagination and combined selection modes.

Constraints:
1. Do not add an HTTP client dependency for v0.1. Apps own HTTP, auth, headers, and API response mapping through typed async callbacks.
2. Keep the package compatible with the existing Dart SDK constraint `^3.10.3` and Flutter package shape.
3. Prefer Material-compatible defaults but keep the package broadly usable in Flutter apps through builders and theme data.
4. Do not copy uncommented Flutter framework source into the package. Use framework references to guide behavior and naming only.
</background>

<discovery>
Before writing production code, examine thoroughly and decide:
1. Whether the local Flutter SDK available to this project includes the public `RawMenuAnchor` APIs needed for custom overlay construction. If unavailable or unstable, use `OverlayPortal` or `OverlayEntry` with `CompositedTransformTarget`/`CompositedTransformFollower` as the fallback, while preserving the same public package API.
2. How the root package should be organized. Prefer a small feature-first structure under `./lib/src/` with the public barrel in `./lib/flutter_dropify.dart`.
3. Whether any example app analyzer/test assumptions need to change after `example/` imports the package by path.
4. Which keys/selectors are needed for robust widget and robot-style journey tests.
</discovery>

<user_flows>
Primary static single-select flow:
1. An app developer imports `package:flutter_dropify/flutter_dropify.dart`.
2. The developer renders `DropifyDropdown<T>` with a static list of `DropifyItem<T>`, a controlled `value`, and `onChanged`.
3. The app user taps or focuses the field.
4. The menu opens as an anchored overlay aligned to the field.
5. The user optionally types into search.
6. The list filters locally.
7. The user selects an enabled item.
8. The menu closes, the field displays the selected item, and `onChanged` receives the selected value.

Primary async single-select flow:
1. The developer renders `DropifyAsyncDropdown<T>` with an async loader callback.
2. The user opens the field.
3. The widget shows a loading state while requesting items.
4. The widget displays returned items, an empty state, or an error state.
5. The user retries after an error or selects an item after success.
6. Selection updates through `onChanged`; network details remain owned by the host app.

Primary paginated flow:
1. The developer renders `DropifyPaginatedDropdown<T>` or the core composable field with a paginated source.
2. The first page loads on open unless preloaded items were supplied.
3. The user scrolls near the end of the menu list.
4. The widget requests the next page once, appends returned items, and shows an inline loading-more row.
5. When the source reports no more data, the widget stops requesting pages and can show an optional end-of-list affordance.

Primary multi-select flow:
1. The developer renders `DropifyMultiSelect<T>` with controlled `values` and `onChanged`.
2. The user opens the menu.
3. The user selects or deselects multiple items without closing the menu after each item.
4. Selected values appear in the field as chips, a summary label, or a custom selected builder.
5. The user taps clear all, select all for currently loaded/filter-visible items, outside the overlay, or a done action depending on configuration.
6. `onChanged` receives the updated value list after each explicit selection change.

Combined multi-select paginated flow:
1. The developer renders the core composable field or a `DropifyMultiSelect.paginated` factory with `selectionMode: multi` and a paginated async source.
2. The user searches and scrolls through pages.
3. Selected values remain selected even when their items are not on the currently loaded page or are filtered out.
4. Loading more pages must never clear existing selections.
5. Select all applies only to the current loaded/filter-visible item set unless the developer explicitly supplies a custom bulk-selection action.

Alternative flows:
- Initial selected value: the field displays an initial selected item even before async data loads when the developer supplies selected item metadata or a selected builder.
- Disabled field: the field renders disabled, cannot open, and does not call loaders or callbacks.
- Read-only display: the field can display a value without allowing edits when configured as read-only.
- Custom item rendering: the developer provides item builders for rows and selected value display while keeping keyboard, semantics, and selection behavior intact.
- Form validation: the developer uses dropdowns inside `Form` widgets and receives validation error display consistent with Flutter form fields.

Error and recovery flows:
- Initial async load fails: show an error message and retry action inside the overlay; keep the field open unless the user dismisses it.
- Search request fails: show search-specific error feedback and allow retry using the same query.
- Next page fails: preserve already loaded items, show an inline pagination error row, and retry only the failed page.
- Stale response arrives after a newer query: ignore the stale response and keep the latest query state visible.
- User closes overlay during a request: do not call `setState` after dispose; ignore late results if the widget is disposed or the request is no longer current.
</user_flows>

<requirements>
**Functional:**
1. Replace the placeholder `Calculator` API with a public dropdown package API exported from `./lib/flutter_dropify.dart`.
2. Provide a core composable widget, named `DropifyField<T>` or equivalent, that accepts independent source, selection mode, search, pagination, validation, presentation, and theme configuration.
3. Provide convenience APIs for common cases: `DropifyDropdown<T>`, `DropifyAsyncDropdown<T>`, `DropifyPaginatedDropdown<T>`, and `DropifyMultiSelect<T>`.
4. Support combined modes without creating a separate widget for every permutation. At minimum, expose a clear API for multi-select plus paginated async data, such as `DropifyMultiSelect.paginated(...)` or `DropifyField<T>(selectionMode: DropifySelectionMode.multi, source: DropifySource.paginated(...))`.
5. Define a typed item model, such as `DropifyItem<T>`, with value, label, enabled state, optional leading/trailing widgets or builder metadata, and enough identity information to compare selected values reliably.
6. Support custom item labels through `String Function(T)` or item model labels.
7. Support custom item row rendering without breaking selection, hover, focus, semantics, disabled state, or test selectors.
8. Support custom selected display for single selection and multi-selection.
9. Use controlled selection first. Single-select widgets accept `T? value` and `ValueChanged<T?> onChanged`. Multi-select widgets accept `List<T> values` and `ValueChanged<List<T>> onChanged` or equivalent immutable list semantics.
10. Provide an optional controller only for interaction state that benefits from imperative control, such as open, close, clear search, refresh, and retry. Selection must still be controllable by the host app.
11. Support local static sources with optional local filtering.
12. Support async non-paginated sources through typed callbacks that receive at least the current query and return items.
13. Support paginated async sources through typed callbacks that receive query and page request information and return items plus `hasMore` or `nextPageKey` metadata.
14. Support search across static, async, paginated, single-select, and multi-select modes.
15. For local search, provide a default case-insensitive label contains filter and allow a custom filter callback.
16. For async search, debounce input with a configurable default of 300 ms, reset pagination when the query changes, and use latest-response-wins semantics.
17. Open the menu as an anchored overlay that can contain search input, list content, loading rows, empty rows, error rows, pagination rows, multi-select actions, and custom builders.
18. Size the overlay responsively. Default width should match the field width, with configurable min/max width and max height. The overlay must stay within visible screen bounds and safe areas.
19. Dismiss the overlay on outside tap, Escape, route pop, and disabled-state changes. Do not dismiss after each item tap in multi-select mode unless explicitly configured.
20. Support keyboard interaction: Tab focus traversal, Enter/Space to open/select, ArrowUp/ArrowDown to move highlight, Escape to close, and text input focus for searchable fields.
21. Support accessibility semantics for field state, expanded/collapsed state, selected items, disabled items, loading state, error state, retry actions, and multi-select checked state.
22. Support Flutter form usage through a form-field API or wrapper with validator, autovalidate mode, error text, enabled state, and reset/save behavior.
23. Provide a practical theme system, such as `DropifyThemeData` plus inherited/default resolution, covering field, menu container, search input, item rows, highlighted row, selected row, chips, loading state, error state, empty state, icons, spacing, shape, colors, and text styles.
24. Allow per-widget theme overrides that merge with inherited/default theme values.
25. Update the example app in `./example/lib/main.dart` to demonstrate static single-select, async search, paginated loading, multi-select, multi-select paginated, validation, and theming.
26. Update `./README.md` with package description, install instructions, API examples, feature list, and limitations.
27. Update `./CHANGELOG.md` for the initial real package implementation.
28. Keep public API names clear, typed, and documented with dartdoc for all exported widgets, models, callbacks, controllers, and theme classes.

**Error Handling:**
29. Initial async load errors must render a visible error state with a retry action and must not silently fail.
30. Pagination errors must preserve already loaded items and show an inline retry for the failed page.
31. Empty results must be distinct from errors and loading. Static empty, async empty, search empty, and paginated end-of-list states must be representable.
32. Loader callbacks that throw must be caught by the widget state, converted to visible error UI, and optionally reported through an `onError(Object error, StackTrace stackTrace)` callback.
33. Late async results after disposal, overlay close, query change, or refresh must not crash and must not overwrite newer state.
34. Duplicate pagination triggers caused by rapid scrolling must coalesce so only one request per page is in flight.
35. If the developer provides invalid configuration, fail early with assertions in debug mode and clear error messages. Examples: both static items and async loader supplied to the same source constructor, negative debounce duration, or missing `onChanged` for enabled controlled selection.

**Edge Cases:**
36. Selected values not present in the current loaded item list must still render using supplied selected item metadata or selected builders.
37. Duplicate item values must either be disallowed with a debug assertion or handled through an explicit identity/equality callback. The chosen behavior must be documented.
38. Disabled items must be visible but not selectable, skipped by keyboard activation, and announced as disabled.
39. Clearing a search query must restore the unfiltered static list or reload the first async page for an empty query.
40. Changing widget inputs from the parent while the overlay is open must update visible state without losing controlled selections.
41. Changing the source or query must reset pagination state and scroll position for the new result set.
42. Multi-select clear all must only clear selected values controlled by the widget and must call `onChanged` with a new list.
43. Multi-select select all must default to loaded/filter-visible enabled items only, including currently loaded pages for paginated sources.
44. Very long labels must ellipsize or wrap according to theme/configuration without breaking row height constraints.
45. Very large static lists should render through lazy list widgets, not eager construction of all row widgets.
46. The overlay must handle small screens, screen rotation/resizing, text scale changes, and on-screen keyboard insets.
47. Nested scrollables must not cause pagination to trigger incorrectly before the menu list nears its end.
48. Rapid open/close/open cycles must not leak controllers, timers, focus nodes, scroll controllers, or pending subscriptions.

**Validation:**
49. Required single-select validation must fail when `value == null`.
50. Required multi-select validation must fail when `values.isEmpty`.
51. Custom validators must receive the selected value or selected values and return an error string compatible with Flutter form conventions.
52. Validation errors must be visible on the field and accessible to screen readers.
53. Search input should not be treated as the selected value; typing without selecting must not change controlled selection.
</requirements>

<boundaries>
Edge cases:
- Multi-select paginated selection across pages: preserve selections even when selected items are outside the current page, filtered out, or loaded later.
- Async initial value with unloaded label: require a selected display builder or selected item metadata; otherwise show a documented fallback label such as the value's `toString()` only if explicitly chosen.
- Disabled while loading: close the overlay or prevent interaction, ignore late results if they no longer apply, and keep controlled selection unchanged.
- Parent rebuild with new values: treat parent values as source of truth and derive field display from them.
- Repeated equivalent queries: avoid unnecessary reloads when the normalized query has not changed unless the developer calls refresh.

Error scenarios:
- Loader throws: show error state, call optional `onError`, and keep retry available.
- Loader returns malformed page metadata: assert in debug if metadata violates the page contract, such as `hasMore == true` with no way to request another page.
- Network timeout in host app loader: surface the thrown error through the same error UI; package must not assume a specific timeout type.
- Stale search/page result: ignore it and do not flash older results.
- Pagination retry fails repeatedly: keep existing items visible and keep retry available without duplicating rows.

Limits:
- Do not implement built-in HTTP endpoint configuration in v0.1.
- Do not implement remote caching beyond preserving currently loaded pages in widget state while the source/query is unchanged.
- Do not implement virtualization beyond Flutter lazy scrollable lists in v0.1.
- Do not implement grouped sections, nested menus, or cascading submenus unless they naturally fall out of builders without extra API.
- Do not implement a modal bottom-sheet presentation in v0.1 unless later explicitly requested. The default v0.1 presentation is an anchored overlay designed to work on mobile, tablet, desktop, and web.
</boundaries>

<implementation>
Create or modify these paths:
1. `./lib/flutter_dropify.dart`: public barrel export for the package API. Remove placeholder `Calculator`.
2. `./lib/src/dropify_item.dart`: typed item/value model and equality guidance.
3. `./lib/src/dropify_source.dart`: static, async, and paginated source abstractions plus query/page request/result types.
4. `./lib/src/dropify_selection.dart`: single/multi selection mode types and controlled selection helpers.
5. `./lib/src/dropify_controller.dart`: optional controller for open/close, refresh, retry, and search clearing.
6. `./lib/src/dropify_theme.dart`: theme data, defaults, and merge/copy behavior.
7. `./lib/src/dropify_field.dart`: core composable field widget.
8. `./lib/src/dropify_dropdown.dart`: static single-select convenience widget.
9. `./lib/src/dropify_async_dropdown.dart`: async single-select convenience widget.
10. `./lib/src/dropify_paginated_dropdown.dart`: paginated single-select convenience widget.
11. `./lib/src/dropify_multi_select.dart`: multi-select convenience widget, including a clear path for paginated multi-select.
12. `./lib/src/widgets/`: private/internal widgets for anchor field, overlay, search box, list rows, state rows, chips, and semantics wrappers as needed.
13. `./test/`: replace placeholder tests with unit and widget tests for models, state transitions, and public widgets.
14. `./example/lib/main.dart`: replace counter app with a focused Dropify demo app.
15. `./example/test/widget_test.dart`: update to test the demo app smoke path.
16. `./README.md`: package documentation and examples.
17. `./CHANGELOG.md`: initial real implementation entry.
18. `./pubspec.yaml`: update description/homepage only if appropriate; avoid adding runtime dependencies unless implementation proves they are necessary.

Implementation principles:
1. Prefer a callback-first API over package-owned networking.
2. Prefer small typed models over maps/dynamic response handling.
3. Keep state derived from controlled values where possible.
4. Use one overlay architecture consistently. Prefer `RawMenuAnchor` if available and suitable; otherwise use `OverlayPortal` or `OverlayEntry` plus composited transforms. Do not mix multiple overlay strategies without a specific reason.
5. Keep convenience widgets thin. They should configure the core composable field rather than duplicating menu/search/pagination logic.
6. Use lazy lists for menu rows and pagination sentinels.
7. Dispose every owned `TextEditingController`, `FocusNode`, `ScrollController`, debounce timer, and animation/controller resource.
8. Use stable keys for important interactive elements, especially field, search input, item rows, retry button, clear-all action, select-all action, loading row, empty row, and pagination row.
9. Keep public API dartdoc concise but complete enough for generated docs and IDE help.
10. Avoid exposing private implementation details through tests or public API.
</implementation>

<stages>
Phase 1: Static single-select foundation
- Replace placeholder API with `DropifyItem<T>`, static source support, controlled single selection, anchored overlay, local search, empty state, disabled state, and basic theme defaults.
- Verify with unit tests for item/source behavior and widget tests for open, search, select, close, disabled, and empty flows.

Phase 2: Async source and search
- Add callback-based async source, loading/error/retry states, debounced latest-wins search, stale response protection, refresh/retry controller seams, and visible error handling.
- Verify with fake async loaders that can resolve, throw, delay, and complete out of order.

Phase 3: Pagination
- Add paginated source contracts, first-page load, scroll-near-end next-page loading, end-of-list behavior, inline pagination errors, and duplicate-trigger coalescing.
- Verify with deterministic fake page loaders and scroll-driven widget tests.

Phase 4: Multi-select and combined modes
- Add controlled multi-selection, selected chip/summary display, select all, clear all, validation support, and multi-select paginated behavior through the composable core API.
- Verify that selections persist across search changes and page loads.

Phase 5: Theme, accessibility, and polish
- Add practical theme coverage, keyboard navigation, semantics labels/states, responsive overlay sizing, and form-field integration.
- Verify with widget tests for keyboard, semantics, validation, and theme overrides.

Phase 6: Example and docs
- Replace the example counter app with Dropify demos for every supported feature, update README, update CHANGELOG, and ensure package consumers can copy minimal examples.
- Verify root and example analyzers/tests pass.
</stages>

<illustrations>
Desired API direction:

```dart
DropifyDropdown<Country>(
  items: countries.map((country) => DropifyItem(value: country, label: country.name)).toList(),
  value: selectedCountry,
  onChanged: (country) => setState(() => selectedCountry = country),
  searchable: true,
)
```

Desired async direction:

```dart
DropifyAsyncDropdown<User>(
  value: selectedUser,
  onChanged: (user) => setState(() => selectedUser = user),
  loader: (query) => usersRepository.searchUsers(query.text),
)
```

Desired multi-select paginated direction:

```dart
DropifyMultiSelect<User>.paginated(
  values: selectedUsers,
  onChanged: (users) => setState(() => selectedUsers = users),
  pageLoader: (request) => usersRepository.searchUsersPage(
    query: request.query,
    pageKey: request.pageKey,
  ),
)
```

Counter-examples to avoid:
- Do not require package users to pass a URL string, headers, or JSON path to the dropdown package for v0.1.
- Do not create only `DropifyPaginatedDropdown` and then make multi-select pagination impossible.
- Do not clear multi-select values just because their page is not loaded.
- Do not use `DropdownMenu` directly if it prevents custom loading, pagination, retry, or multi-select behavior.
- Do not write tests against private classes when the same behavior can be verified through public widgets/models.
</illustrations>

<validation>
Use vertical-slice TDD for implementation. For each behavior slice, write one failing test first, implement the smallest production change that makes it pass, then refactor only after green. Do not write all tests in bulk before implementation. Tests must exercise public interfaces unless a private helper contains complex pure logic that cannot reasonably be observed through public APIs.

Required testability seams:
1. Loader callbacks must be injectable and controllable by tests.
2. Debounce duration must be configurable so tests can use zero or fake time where appropriate.
3. Pagination trigger threshold must be deterministic in widget tests.
4. Controllers for search, focus, scroll, and menu state must be injectable or observable where needed without exposing implementation internals unnecessarily.
5. Stable keys must exist for critical UI nodes used by robot-style tests.
6. Async tests should use fakes and completers instead of mocks except at true external boundaries.

Behavior-first TDD slice order:
1. Static item model and local filtering.
2. Static single-select open/select/close behavior.
3. Empty and disabled states.
4. Custom labels and selected display.
5. Async initial loading success.
6. Async error and retry.
7. Debounced async search with stale response ignored.
8. Paginated first page and next page load.
9. Pagination error preserving existing items.
10. Multi-select add/remove/clear behavior.
11. Multi-select paginated selection persistence across pages and searches.
12. Form validation and error display.
13. Keyboard navigation and semantics.
14. Theme override resolution.

Baseline automated coverage outcomes:
1. Unit tests cover source/query/page models, equality/identity behavior, theme merge/copy behavior, and any pure selection helpers.
2. Widget tests cover each public widget's primary flow and screen-level edge/error/cancel states.
3. Robot-style widget journey tests cover critical user journeys in the example or test harness: static select, async search retry then select, paginated scroll load then select, multi-select clear/select, and multi-select paginated selection across pages.
4. Example smoke tests verify the demo app imports and renders package widgets.

Default test split:
- Robot-style widget journey tests: critical happy paths that combine multiple actions, such as open, search, paginate, select, validate, and clear.
- Widget tests: screen/component edge cases such as cancel/outside tap, retry, validation errors, disabled state, keyboard traversal, empty state, and theme overrides.
- Unit tests: source contracts, page state transitions, debounce/latest-wins logic where factored into testable units, equality, and theme merging.

Required stable selectors:
- Dropdown field.
- Search input.
- Menu overlay/container.
- Item row keyed by stable value or index plus source identity.
- Selected chip keyed by selected value.
- Loading row.
- Empty row.
- Error row.
- Retry button.
- Pagination loading row.
- Pagination retry row.
- Select all action.
- Clear all action.

Commands to run during implementation verification:
1. From repo root: `flutter pub get`.
2. From repo root: `flutter analyze`.
3. From repo root: `flutter test test/flutter_dropify_test.dart` or the expanded root test suite paths.
4. From `./example/`: `flutter pub get` after adding the path dependency.
5. From `./example/`: `flutter analyze`.
6. From `./example/`: `flutter test test/widget_test.dart` or the expanded example test suite paths.

Known validation risk:
Some visual overlay placement behavior may be difficult to prove fully with unit/widget tests. Cover deterministic sizing and interaction behavior in widget tests, and document any residual visual risk if screenshot/manual verification is not performed.
</validation>

<done_when>
The implementation is complete when:
1. `./lib/flutter_dropify.dart` exports the real Dropify public API and no placeholder `Calculator` remains.
2. Static, async, paginated, multi-select, and multi-select paginated dropdown flows are implemented and demonstrated.
3. Search works for local, async, paginated, single-select, and multi-select modes.
4. Async loading, error, retry, empty, stale response, and pagination failure states are visible and tested.
5. Controlled selection works consistently for single and multi-select widgets.
6. The anchored overlay is responsive, dismissible, keyboard-accessible, and suitable for paginated content.
7. Practical theming and per-widget overrides are implemented and documented.
8. Form validation is supported and tested.
9. Root package tests replace placeholder tests and cover the required behavior slices.
10. The example app imports the package and demonstrates the primary features.
11. `./README.md` includes installation, quick start, static, async, paginated, multi-select, multi-select paginated, validation, theming, and limitation examples.
12. `./CHANGELOG.md` documents the initial real implementation.
13. Root analyzer and tests pass.
14. Example analyzer and tests pass.
</done_when>
