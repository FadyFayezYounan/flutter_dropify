<goal>
Build `flutter_dropify` into a production-ready Flutter package for app developers who need reusable, typed, highly customizable dropdown components.

The package must let developers add static, async, and paginated dropdowns without rebuilding search, loading, retry, pagination, selection, validation, theming, overlay, keyboard, and accessibility behavior in every app.

The v0.1 release must be complete and polished: the placeholder package API must be replaced, the example app must become a real demo, and README/CHANGELOG must describe the implemented public API.
</goal>

<background>
This repository is a Flutter package, not a full app.

Current repo state to account for:
- `./lib/flutter_dropify.dart` is effectively empty and must become the package export entrypoint.
- `./test/flutter_dropify_test.dart` is effectively empty and must be replaced with meaningful package tests.
- `./example/lib/main.dart` is the generated counter app and must be replaced with a complete Dropify demo.
- `./README.md` and `./CHANGELOG.md` are generated placeholders and must be replaced.
- `./pubspec.yaml` currently uses `description: "A new Flutter package project."` and `flutter: ">=1.17.0"`; the Flutter lower bound must be raised to support the selected modern menu/overlay primitives.
- `./example/pubspec.yaml` currently does not depend on `flutter_dropify`; it must depend on the root package by path.
- `./analysis_options.yaml` uses `package:flutter_lints/flutter.yaml`; keep this lint baseline unless a concrete implementation need requires more.

Files to examine before implementation:
- `./ai_specs/001-flutter_dropify.md`
- `./pubspec.yaml`
- `./analysis_options.yaml`
- `./lib/flutter_dropify.dart`
- `./test/flutter_dropify_test.dart`
- `./example/pubspec.yaml`
- `./example/lib/main.dart`
- `./README.md`
- `./CHANGELOG.md`
- `./refrences/flutter_raw_menu_anchor.dart`
- `./refrences/flutter_menu_anchor.dart`
- `./refrences/flutter_dropdown_menu.dart`
- `./refrences/flutter_dropdown_button.dart`

The `./refrences/` directory is intentionally misspelled in this repo. Treat those files as commented framework references only. Do not import them or copy them wholesale.
</background>

<discovery>
Before changing package code, examine thoroughly and document implementation decisions in code comments only where needed.

Discovery requirements:
1. Verify the local Flutter SDK version and the framework availability of `RawMenuAnchor`, `MenuController`, `TapRegion`, focus traversal APIs, and semantics APIs needed for this package.
2. Raise the root package Flutter lower bound in `./pubspec.yaml` to the minimum Flutter version that supports the selected implementation primitives.
3. Prefer `RawMenuAnchor` and `MenuController` as the overlay foundation when available.
4. Use `TapRegion` behavior so outside taps close the menu correctly.
5. Use lazy scrollable lists for rows; avoid custom virtualization beyond Flutter lazy lists and `infinite_scroll_pagination`.
6. If `RawMenuAnchor` cannot satisfy a required behavior, evaluate `OverlayPortal` or `OverlayEntry` with `CompositedTransformTarget` and `CompositedTransformFollower` as a fallback.
7. Do not use Flutter `DropdownMenu` as the core implementation because its fixed entry model is too restrictive for async loading, pagination, retry, custom row builders, and multi-select.
8. Check the latest compatible `infinite_scroll_pagination` API before implementing the paginated adapter.
9. Keep public Dropify pagination constructors independent from `PagingController`, `PagingState`, and other package-specific paging types.
10. Identify whether any existing generated files or tests should be deleted, replaced, or renamed as part of implementation.
</discovery>

<user_flows>
Primary developer flow:
1. An app developer adds `flutter_dropify` to an app and imports `package:flutter_dropify/flutter_dropify.dart`.
2. The developer creates a typed `DropifyDropdown<T>` with `List<DropifyItem<T>>`, `value`, and `onChanged`.
3. The app user taps or focuses the field.
4. The dropdown opens anchored to the field.
5. The search input appears above the item list by default.
6. The app user types a search query.
7. Static items are filtered locally by case-insensitive label matching unless a custom filter is supplied.
8. The app user selects an enabled item.
9. `onChanged` receives the selected value.
10. The menu closes by default for single-select.
11. The closed field displays the selected value through default UI or `selectedBuilder`.

Static multi-select flow:
1. The developer creates `DropifyDropdown<T>.multi` with `items`, `values`, and `onChanged`.
2. The app user opens the dropdown.
3. The app user selects or deselects enabled rows.
4. `onChanged` receives a new immutable `List<T>` on every selection change.
5. The menu remains open by default after each row toggle.
6. The app user can clear all selections.
7. The app user can select all currently loaded and filter-visible enabled items.
8. Selected values remain selected even if later filtered out.

Async single-select flow:
1. The developer creates `DropifyAsyncDropdown<T>` with a typed loader callback.
2. The app user opens the dropdown.
3. The dropdown shows first-load loading UI.
4. The loader receives `DropifyQuery`.
5. Loaded items appear when the latest request completes.
6. The app user searches.
7. Search input is debounced by the configured debounce duration, defaulting to 300 milliseconds.
8. Stale responses are ignored.
9. The app user selects an enabled item.
10. `onChanged` receives the selected value and the menu closes by default.

Async multi-select flow:
1. The developer creates `DropifyAsyncDropdown<T>.multi` with `values` and a typed loader callback.
2. The app user opens, searches, selects, and deselects items.
3. Selected values persist across async result changes, searches, retries, and refreshes.
4. If a selected value is not present in the current result set, it remains selected and can still be displayed through selected item display data supplied by the host or preserved from previous loaded items.

Paginated single-select flow:
1. The developer creates `DropifyPaginatedDropdown<T, PageKey>` with a typed page loader callback and optional `firstPageKey`.
2. The app user opens the dropdown.
3. The first page loads when the menu opens unless cached state is still valid.
4. The list loads the next page when scroll approaches the end.
5. Duplicate load-more triggers are coalesced.
6. The app user selects an enabled item from any loaded page.
7. `onChanged` receives the selected value and the menu closes by default.

Paginated multi-select flow:
1. The developer creates `DropifyPaginatedDropdown<T, PageKey>.multi`.
2. The app user selects items from page one.
3. The app user scrolls to load more pages.
4. The app user selects items from later pages.
5. The app user searches, causing loaded pages and scroll position to reset.
6. Previously selected values remain selected even when their items are no longer loaded or visible.

Form validation flow:
1. The developer places a Dropify widget inside a Flutter `Form`.
2. The developer supplies optional validator, `autovalidateMode`, `onSaved`, and reset-related configuration directly on the Dropify widget.
3. The app calls `FormState.validate()`.
4. Required single-select validation fails when the value is `null`.
5. Required multi-select validation fails when the values list is empty.
6. Error text appears on the field and is exposed to accessibility semantics.
7. The app calls `FormState.save()` and Dropify invokes `onSaved` with the current controlled value.
8. The app calls `FormState.reset()` and Dropify resets through the configured initial value behavior, notifying `onChanged` so the host remains the source of truth.

Custom builder flow:
1. The developer supplies builders for field, search, item, selected display, loading, data, empty, error, overlay, menu header/footer, and pagination rows.
2. Dropify passes state objects and callbacks to builders.
3. Custom UI preserves Dropify semantics, keyboard behavior, stable keys, focus/highlight state, tap-region behavior, and close behavior.

Error and recovery flows:
- Initial async load error: show visible error UI, call optional `onError`, keep the menu open, and provide retry for the same query.
- Search load error: show visible error UI for the current query and retry that query.
- Next-page error: preserve already loaded items, show an inline pagination error row, and retry only the failed page.
- Stale async result: ignore stale results from older query, source, refresh, page, or disposed state.
- Disabled state while open: close the menu, prevent selection, and update semantics.
- Outside tap: close the menu without changing selection.
- Escape key: close the menu without changing selection.
- Route pop: close and dispose safely without calling `setState` after dispose.
- Duplicate visible identity: assert in debug mode with a clear message.
- Invalid pagination result: assert in debug mode with a clear message.
</user_flows>

<requirements>
**Functional:**
1. Replace the placeholder package with a real public API exported from `./lib/flutter_dropify.dart`.
2. Implement `DropifyBuilder<T>` as the low-level universal dropdown composition widget.
3. Implement `DropifyDropdown<T>` for static single-select dropdowns.
4. Implement `DropifyDropdown<T>.multi` for static multi-select dropdowns.
5. Implement `DropifyAsyncDropdown<T>` for async non-paginated single-select dropdowns.
6. Implement `DropifyAsyncDropdown<T>.multi` for async non-paginated multi-select dropdowns.
7. Implement `DropifyPaginatedDropdown<T, PageKey>` for paginated async single-select dropdowns.
8. Implement `DropifyPaginatedDropdown<T, PageKey>.multi` for paginated async multi-select dropdowns.
9. Do not create a separate public `DropifyMultiSelect<T>` widget.
10. Do not create separate public form wrapper widgets such as `DropifyDropdownFormField<T>`.
11. Add optional form integration parameters directly to each Dropify widget family, including validator, `autovalidateMode`, `onSaved`, and reset/initial value behavior.
12. Keep public API names mostly fixed to the names in this spec; allow only small naming improvements that are documented in README and do not weaken behavior.
13. Implement `DropifyItem<T>` with `value`, `label`, `enabled`, and an optional stable identity field such as `id`.
14. Implement `DropifySource<T>` abstractions for static, async, and paginated data sources.
15. Implement `DropifyQuery` with raw search text, normalized search text, and future-safe query metadata.
16. Implement `DropifyPageRequest<PageKey>` with current `DropifyQuery` and current page key.
17. Implement `DropifyPageResult<T, PageKey>` with loaded items, `nextPageKey`, and `hasMore`.
18. Implement `DropifyController` for interaction only: open, close, toggle, clear search, refresh, and retry.
19. Ensure `DropifyController` never owns selected value state.
20. Implement `DropifyTheme` as an inherited theme widget.
21. Implement `DropifyThemeData` with defaults, `copyWith`, merge/resolve behavior, equality where appropriate, and diagnostics.
22. Implement `DropifyKeys` as the stable selector contract for package tests, example tests, and robot journeys.
23. Use `infinite_scroll_pagination` internally for paginated dropdowns.
24. Do not expose `PagingController`, `PagingState`, or package-specific paging types in primary public constructors.
25. Raise the Flutter lower bound in `./pubspec.yaml` to the minimum version required by the selected overlay primitives.
26. Update package metadata in `./pubspec.yaml`, including a meaningful description.
27. Add `infinite_scroll_pagination` to root dependencies only when implementing the paginated phase.
28. Update `./example/pubspec.yaml` to depend on the root package by path.

**Selection:**
29. Treat selection as controlled by the host app.
30. Single-select constructors must accept `T? value` and `ValueChanged<T?>? onChanged`.
31. Multi-select constructors must accept `List<T> values` and `ValueChanged<List<T>>? onChanged`.
32. A null `onChanged` disables selection and must update enabled state semantics.
33. Single-select must close the menu after selecting an enabled item by default.
34. Multi-select must keep the menu open after selecting or deselecting by default.
35. Multi-select must emit a new immutable list on every selection change.
36. Multi-select must support clear all.
37. Multi-select must support select all for current loaded and filter-visible enabled items.
38. Multi-select must preserve selected values even when items are not loaded, filtered out, or hidden by pagination.
39. Typing in search must never change selection by itself.
40. Disabled items must remain visible, cannot be selected, and must be skipped by keyboard activation.
41. Prefer item identity for selection, stable keys, and duplicate checks.
42. Fall back to `value` identity when no explicit item identity is supplied.
43. Duplicate visible identities must assert in debug mode with a clear message.

**Builder API:**
44. Implement a builder-first core that supports custom field shape, overlay shell, item row, selected display, loading UI, error UI, empty UI, search UI, header/footer, and pagination row UI.
45. Support `fieldBuilder` with open state, enabled state, selected display data, validation error text, and callbacks such as open, toggle, close, and clear.
46. Support `searchBuilder` with search controller/focus handling or a safe interaction object.
47. Support `itemBuilder` with item, selected state, highlighted state, disabled state, and selection callback.
48. Support `selectedBuilder` for single-select selected display.
49. Support `selectedItemsBuilder` for multi-select selected display.
50. Support `loadingBuilder` for first-load loading state.
51. Support `dataBuilder` as an advanced full content override when data is available.
52. Support `emptyBuilder` for empty and search-empty states.
53. Support `errorBuilder` for first-load and search-load error states with error details and retry callback.
54. Support `overlayBuilder` for an optional full overlay shell override.
55. Ensure `overlayBuilder` still allows Dropify to provide tap-region, constraints, keyboard, semantics, and close behavior.
56. Support `menuHeaderBuilder` above the list and below search.
57. Support `menuFooterBuilder` below the list.
58. Support paginated `loadMoreBuilder`, `loadMoreErrorBuilder`, `noMoreItemsBuilder`, and optional `pagedItemBuilder`.
59. If `pagedItemBuilder` is null, reuse `itemBuilder`.
60. Custom builders must not break semantics, keyboard behavior, hover/focus state, tap-region behavior, close behavior, or stable selectors.

**Search:**
61. Every dropdown mode must show a search field above the list by default.
62. Static search must use local filtering.
63. Static default filtering must be case-insensitive `label.contains(query)` against normalized query text.
64. Static dropdowns must allow a custom filter callback.
65. Clearing static search must restore the original item list.
66. Async loaders must receive `DropifyQuery`.
67. Async search debounce must default to 300 milliseconds.
68. Async search debounce must be configurable for tests and custom UX.
69. Latest response wins for async search and initial loading.
70. Stale responses must not overwrite newer visible state.
71. Loader errors must produce visible error UI and call optional `onError(Object error, StackTrace stackTrace)`.
72. Paginated search must reset loaded pages and scroll position.
73. Paginated search must reload the first page for the new query.
74. Stale first-page and next-page responses must be ignored.
75. Multi-selected values must survive query changes.

**Pagination:**
76. `DropifyPageResult<T, PageKey>` must be the standardized public page result type.
77. `DropifyPageResult.items` must contain the loaded items for the request.
78. `DropifyPageResult.nextPageKey` must contain the key for the next page when `hasMore` is true.
79. `DropifyPageResult.hasMore` must indicate whether more pages are available.
80. A result with `hasMore == true` and `nextPageKey == null` must assert in debug mode unless the implementation explicitly supports null page keys for subsequent pages.
81. A result with `hasMore == false` must not trigger more page requests.
82. The first page must load when the menu opens unless cached state is still valid.
83. Load more when scroll approaches the end of loaded items.
84. Coalesce duplicate load-more triggers.
85. Preserve already loaded items when a next-page request fails.
86. Render next-page loading through `loadMoreBuilder`.
87. Render next-page failure through `loadMoreErrorBuilder`.
88. Render optional end-of-list UI through `noMoreItemsBuilder`.
89. Retry next-page errors without reloading successful pages.
90. Reset pagination when search query changes.
91. Never clear multi-select values because their items are absent from the current loaded page.

**Overlay and interaction:**
92. Overlay width must match the field by default.
93. Overlay must support min width, max width, and max height through theme or widget configuration.
94. Overlay must stay within visible screen bounds and safe areas.
95. Overlay must handle small screens, rotation/resizing, text scale, and keyboard insets.
96. Overlay must dismiss on outside tap, Escape, route pop, and disabled-state changes.
97. Overlay must not dismiss after each multi-select item tap unless configured.
98. Menu open/close state must be exposed to builders.
99. Programmatic controller actions must remain safe after widget disposal.

**Keyboard and accessibility:**
100. Support Tab focus traversal.
101. Support Enter and Space to open and select.
102. Support ArrowUp and ArrowDown to move highlight.
103. Support Escape to close.
104. Focus the search input when the menu opens according to platform-appropriate behavior.
105. Skip disabled rows during keyboard activation.
106. Expose field expanded/collapsed state through semantics.
107. Expose enabled/disabled state through semantics.
108. Expose selected item state through semantics.
109. Expose multi-select checked state through semantics.
110. Expose loading state through semantics.
111. Expose empty state through semantics.
112. Expose error state and retry action through semantics.
113. Expose clear all and select all actions through semantics.

**Theme:**
114. Provide practical defaults that look correct in Material apps without custom configuration.
115. Support inherited `DropifyTheme`.
116. Support per-widget theme overrides.
117. Merge inherited, default, and per-widget theme values predictably.
118. Cover field shape, padding, color, border, text style, and icon style.
119. Cover overlay shape, elevation, padding, color, border, and constraints.
120. Cover search input decoration and text style.
121. Cover item row height, padding, text style, hover, highlighted, selected, disabled, and focus styles.
122. Cover multi-select chip or summary display styles.
123. Cover loading, error, empty, retry, load-more, load-more-error, and no-more rows.
124. Cover spacing and animation durations/curves if animations are implemented.

**Form integration:**
125. Add form support directly to the Dropify widget families.
126. Do not expose separate public form wrapper widgets.
127. Support single-select validators that receive `T?`.
128. Support multi-select validators that receive `List<T>`.
129. Support `AutovalidateMode`.
130. Support `onSaved` for single and multi values.
131. Support reset behavior that keeps the host-controlled value synchronized through `onChanged`.
132. Support enabled/disabled behavior inside a form.
133. Display validation error text on the field.
134. Expose validation errors to accessibility semantics.
135. Never treat search text as a selected value.

**Error handling:**
136. Initial async load errors must show visible error UI.
137. Initial async load errors must provide retry.
138. Initial async load errors must call optional `onError(Object error, StackTrace stackTrace)`.
139. Initial async load errors must keep the menu open unless the user dismisses it.
140. Search load errors must show visible error UI for the current query.
141. Search load retry must retry the same query.
142. Next-page errors must preserve loaded items.
143. Next-page errors must show inline pagination error UI.
144. Next-page error retry must retry only the failed page.
145. Ignore results after dispose.
146. Ignore results after menu close when no longer relevant.
147. Ignore stale results after query, source, refresh, or page changes.
148. Never call `setState` after dispose.
149. Assert invalid configuration in debug mode with clear messages.
150. Invalid configuration includes negative debounce duration, duplicate visible item identities, missing loaders, invalid pagination results, and contradictory sizing constraints.

**Example and documentation:**
151. Replace the generated counter app in `./example/lib/main.dart`.
152. Build a complete navigable demo app.
153. Demonstrate static single-select.
154. Demonstrate static multi-select.
155. Demonstrate async single-select.
156. Demonstrate async multi-select.
157. Demonstrate paginated single-select.
158. Demonstrate paginated multi-select.
159. Demonstrate form validation directly on Dropify widgets.
160. Demonstrate custom builders.
161. Demonstrate theme overrides.
162. Demonstrate loading, empty, error, retry, load-more, load-more-error, and no-more states.
163. Update `./README.md` with real package description, installation, basic usage, async usage, paginated usage, multi-select usage, form validation usage, customization guidance, and testing selector notes.
164. Update `./CHANGELOG.md` for the implemented release.
165. Ensure README examples compile against the implemented API.
</requirements>

<boundaries>
In scope for v0.1:
- Static dropdowns.
- Async dropdowns.
- Paginated dropdowns.
- Single-select and multi-select.
- Search in every mode.
- Controlled selection.
- Direct form integration on Dropify widgets.
- Custom builders.
- Loading, data, error, empty, load-more, load-more-error, and no-more states.
- Theme and per-widget theme overrides.
- Keyboard support.
- Accessibility semantics.
- Stable selectors through `DropifyKeys`.
- Complete example app.
- README and CHANGELOG updates.
- Root and example analyzer/test verification.

Out of scope for v0.1:
- Built-in HTTP client configuration.
- URL/header/JSON-path based remote API setup.
- Remote caching beyond current widget state.
- Grouped sections.
- Cascading submenus.
- Modal bottom-sheet presentation.
- Full custom virtualization beyond Flutter lazy lists and the paging package.
- Public exposure of `PagingController`, `PagingState`, or other paging-package controller/state types.
- Separate public form wrapper widgets.

Edge cases:
- Empty item list: show empty UI and keep search available unless disabled by configuration.
- Search with no results: show search-empty UI and allow clearing search.
- Duplicate visible identities: assert in debug with a message naming the duplicate identity.
- Disabled row: visible, non-selectable, skipped by keyboard activation, and announced as disabled.
- Null single value: display placeholder/empty selected state and validate according to supplied validator.
- Empty multi values: display empty multi selected state and validate according to supplied validator.
- Selected value no longer loaded: keep controlled value and display preserved/host-provided selected display data where possible.
- Host changes value while menu is open: update selected/highlighted state without closing unless disabled state changes.
- Host disables widget while menu is open: close the menu and prevent further actions.
- App route changes while menu is open: close/dispose safely.
- Text scale increases: field and overlay remain usable and do not overflow avoidably.
- Screen rotates/resizes: overlay recomputes position and stays within safe bounds.
- Keyboard appears on mobile: overlay respects view insets or remains recoverable.
- Rapid search input: debounce requests and ignore stale completions.
- Concurrent load-more triggers: coalesce into one in-flight request.
- Retry while request is in flight: avoid duplicate requests or define deterministic coalescing.

Error scenarios:
- Async first-load failure: show `errorBuilder` or default error row with retry.
- Async search failure: show error UI for current query and retry current query.
- Paginated next-page failure: preserve previous pages and show inline retry row.
- Loader throws synchronously: treat as async error with stack trace.
- Loader completes after dispose: ignore without `setState`.
- Loader completes after newer search: ignore stale result.
- Invalid page result: assert in debug and avoid undefined paging behavior.
- Custom builder throws: allow Flutter error handling to surface the build exception; do not swallow it silently.

Limits:
- Debounce duration must not be negative.
- Overlay max height must be positive when supplied.
- Overlay min width must not exceed max width when both are supplied.
- Page result `hasMore == true` must provide a usable `nextPageKey` unless null next keys are explicitly supported.
- Row keys must be stable for visible items.
- The package must not require network permissions or HTTP dependencies.
</boundaries>

<implementation>
Expected output paths:
- Modify `./pubspec.yaml`.
- Modify `./lib/flutter_dropify.dart`.
- Create implementation files under `./lib/src/`.
- Replace or create tests under `./test/`.
- Modify `./example/pubspec.yaml`.
- Replace `./example/lib/main.dart`.
- Replace or create example tests under `./example/test/`.
- Modify `./README.md`.
- Modify `./CHANGELOG.md`.

Recommended package file organization:
- `./lib/flutter_dropify.dart` exports all public API files.
- `./lib/src/dropify_builder.dart` contains `DropifyBuilder<T>` and core coordination.
- `./lib/src/dropify_dropdown.dart` contains static convenience widgets.
- `./lib/src/dropify_async_dropdown.dart` contains async convenience widgets.
- `./lib/src/dropify_paginated_dropdown.dart` contains paginated convenience widgets.
- `./lib/src/dropify_item.dart` contains `DropifyItem<T>`.
- `./lib/src/dropify_source.dart` contains source abstractions and loader typedefs.
- `./lib/src/dropify_query.dart` contains `DropifyQuery`.
- `./lib/src/dropify_pagination.dart` contains `DropifyPageRequest<PageKey>` and `DropifyPageResult<T, PageKey>`.
- `./lib/src/dropify_controller.dart` contains `DropifyController`.
- `./lib/src/dropify_theme.dart` contains `DropifyTheme` and `DropifyThemeData`.
- `./lib/src/dropify_keys.dart` contains `DropifyKeys`.
- `./lib/src/dropify_builders.dart` contains public builder typedefs and state objects if needed.
- `./lib/src/dropify_form.dart` contains internal form integration helpers if useful, but no separate public form wrapper widgets.

Implementation rules:
- Keep the public API typed and generic.
- Prefer immutable public models with `const` constructors where possible.
- Use Flutter framework naming conventions for widgets, theme data, diagnostics, and builders.
- Keep the implementation minimal per phase but do not postpone any v0.1 scope listed in this spec.
- Avoid backward-compatibility code for placeholder `Calculator` APIs; remove placeholders.
- Avoid exposing implementation internals through public constructors.
- Avoid hidden global state.
- Prefer constructor injection and callbacks for deterministic tests.
- Prefer fakes in tests; mock only true external boundaries.
- Keep async request sequencing explicit so stale responses can be tested deterministically.
- Add stable keys through `DropifyKeys` only where required for tests and user journeys; do not over-instrument every internal widget.
- Use `debugFillProperties` for public widgets/theme data where useful.
- Preserve accessibility when builders customize visual UI.
</implementation>

<stages>
Phase 0: Discovery and project setup.
Verify Flutter SDK/framework APIs, update SDK lower bound, update metadata, confirm `infinite_scroll_pagination` version, and establish file structure.
Verify by running dependency resolution and analyzer after setup changes.

Phase 1: Static core and static dropdowns.
Implement `DropifyItem<T>`, `DropifyQuery`, static `DropifySource<T>`, `DropifyController`, `DropifyBuilder<T>` static path, `DropifyDropdown<T>`, `DropifyDropdown<T>.multi`, local search, empty state, disabled state, default UI, stable keys, and core builders.
Verify static single open/search/select/close, static multi select/deselect/clear/select-visible, empty state, disabled state, duplicate identity assertions, and custom builder invocation.

Phase 2: Async dropdowns.
Implement async source callbacks, `DropifyAsyncDropdown<T>`, `DropifyAsyncDropdown<T>.multi`, first-load loading, error state, retry, debounced search, latest-response-wins protection, `onError`, controller refresh, and controller retry.
Verify initial load success, initial load error and retry, search reload, stale response ignoring, disposal safety, and multi-selection persistence across async results.

Phase 3: Paginated dropdowns.
Add `infinite_scroll_pagination`, implement internal pagination adapter, `DropifyPageRequest<PageKey>`, `DropifyPageResult<T, PageKey>`, `DropifyPaginatedDropdown<T, PageKey>`, `DropifyPaginatedDropdown<T, PageKey>.multi`, first-page states, next-page rows, end-of-list row, query reset, scroll-position reset, and retry failed next page.
Verify first page loads on open, scroll loads next page once, duplicate load-more triggers coalesce, next-page failure preserves loaded items, retry next page works, search resets pages, invalid page result asserts, and multi-select persists across pages/searches.

Phase 4: Theme, direct form integration, keyboard, and accessibility.
Implement `DropifyTheme`, `DropifyThemeData`, per-widget theme resolution, form parameters directly on widgets, keyboard traversal/activation, semantics, responsive overlay sizing, and safe-area behavior.
Verify theme inheritance/overrides, validation, save/reset behavior, keyboard open/select/highlight/close, and semantics for selected, disabled, loading, empty, error, retry, checked, select-all, and clear-all states.

Phase 5: Example app and documentation.
Replace the counter example with a complete navigable demo, add path dependency to root package, demonstrate all flows, update README, update CHANGELOG, and ensure README examples match the implemented API.
Verify root analyzer/tests, example analyzer/tests, and manual/robot-style journeys.
</stages>

<illustrations>
Desired static single usage:
```dart
DropifyDropdown<String>(
  value: selectedCountry,
  items: const [
    DropifyItem(value: 'eg', label: 'Egypt'),
    DropifyItem(value: 'fr', label: 'France'),
  ],
  onChanged: (value) => setState(() => selectedCountry = value),
)
```

Desired static multi usage:
```dart
DropifyDropdown<String>.multi(
  values: selectedTags,
  items: tagItems,
  onChanged: (values) => setState(() => selectedTags = values),
)
```

Desired async usage:
```dart
DropifyAsyncDropdown<User>(
  value: selectedUser,
  loader: (query) => userRepository.searchUsers(query.normalizedText),
  onChanged: (value) => setState(() => selectedUser = value),
  onError: (error, stackTrace) => reportError(error, stackTrace),
)
```

Desired paginated usage:
```dart
DropifyPaginatedDropdown<User, String>(
  value: selectedUser,
  firstPageKey: null,
  pageLoader: (request) async {
    final page = await userRepository.searchUsersPage(
      query: request.query.normalizedText,
      cursor: request.pageKey,
    );

    return DropifyPageResult(
      items: page.users,
      nextPageKey: page.nextCursor,
      hasMore: page.nextCursor != null,
    );
  },
  onChanged: (value) => setState(() => selectedUser = value),
)
```

Desired direct form validation usage:
```dart
DropifyDropdown<String>(
  value: selectedCountry,
  items: countryItems,
  validator: (value) => value == null ? 'Choose a country' : null,
  autovalidateMode: AutovalidateMode.onUserInteraction,
  onSaved: (value) => savedCountry = value,
  onChanged: (value) => setState(() => selectedCountry = value),
)
```

Counter-examples to avoid:
- Do not expose `PagingController` in the public paginated constructor.
- Do not make multi-select a separate `DropifyMultiSelect<T>` widget.
- Do not create public `DropifyDropdownFormField<T>` wrappers for v0.1.
- Do not make search text part of selected value.
- Do not clear multi-selection just because selected items are not visible in the current query/page.
- Do not silently ignore duplicate visible identities.
- Do not swallow loader errors without visible UI and retry.
</illustrations>

<validation>
Use behavior-first vertical-slice TDD for implementation.

TDD expectations:
1. Write one failing test at a time.
2. Confirm the test fails for the expected reason before implementation.
3. Implement the smallest production change that makes the test pass.
4. Refactor only after tests are green.
5. Each red-green-refactor cycle should be committable.
6. Tests must exercise public interfaces, not private methods.
7. Prefer fakes and deterministic async controls over mocks.
8. Mock only true external boundaries.
9. Use constructor injection, callbacks, configurable debounce durations, fake loaders, and fake page loaders as test seams.
10. Avoid `runAsync` unless no deterministic alternative exists.

Behavior-first test slice order:
1. Static single happy path: open, search, select, close, `onChanged` receives value.
2. Static multi happy path: open, select multiple, deselect, clear all, select visible, immutable emitted lists.
3. Static edge cases: empty state, disabled rows, disabled widget, duplicate identity assertions, custom filter.
4. Builder invocation: field, search, item, selected, empty, loading/error placeholders, overlay, header/footer.
5. Async happy path: first-load loading, data display, select.
6. Async error path: first-load error, visible retry, `onError`, retry success.
7. Async search path: debounce, latest response wins, stale response ignored.
8. Async multi persistence: selections survive result changes and searches.
9. Pagination happy path: first page loads on open, load more on scroll, select.
10. Pagination error path: next-page error preserves loaded items, inline retry loads failed page only.
11. Pagination search path: query resets pages and scroll, stale page responses ignored.
12. Pagination multi persistence: selections survive pages and searches.
13. Theme: defaults, inherited theme, per-widget overrides, merge/copyWith/diagnostics.
14. Form integration: validator, autovalidate, error display, save, reset, disabled state.
15. Keyboard: Tab traversal, Enter/Space open/select, arrows highlight, Escape closes, disabled rows skipped.
16. Accessibility: semantics for expanded, selected, checked, disabled, loading, empty, error, retry, select all, clear all.
17. Responsive overlay: width matching, constraints, safe areas, text scale, keyboard insets.
18. Example app: critical journeys through demo screens.

Required unit tests:
- `DropifyItem` identity behavior.
- Duplicate identity detection helpers if separated from widget code.
- Static filtering and custom filtering.
- Query normalization.
- Page request/result contracts.
- Invalid page result assertions.
- Selection helper behavior.
- Theme `copyWith`, merge, defaults, and diagnostics.
- Controller interaction state where testable without widget internals.

Required widget tests:
- `DropifyDropdown<T>` static single behavior.
- `DropifyDropdown<T>.multi` static multi behavior.
- `DropifyAsyncDropdown<T>` async single behavior.
- `DropifyAsyncDropdown<T>.multi` async multi behavior.
- `DropifyPaginatedDropdown<T, PageKey>` paginated single behavior.
- `DropifyPaginatedDropdown<T, PageKey>.multi` paginated multi behavior.
- Disabled widget and disabled row behavior.
- Empty state and search-empty state.
- Loading state.
- Error and retry state.
- Load-more state.
- Load-more error and retry state.
- No-more-items state.
- Custom builder invocation without losing selectors.
- Keyboard navigation.
- Form validation, save, reset, and error display.
- Theme overrides.
- Semantics for critical accessibility states.

Required robot-style journey tests:
- Static select: open, search, select, close.
- Static multi: open, select multiple, clear, select visible.
- Async: open, fail, retry, search, select.
- Paginated: open, scroll load more, select.
- Paginated multi: select from page one, load page two, select more, search, verify previous selections persist.
- Form demo: validate empty, select value, validate success, reset.
- Builder/theme demo: open a custom-themed dropdown and verify custom field/item/overlay are used through stable selectors.

Test-type mapping:
- Robot-style widget journey tests cover critical happy path journeys and cross-screen example app flows.
- Widget tests cover screen/widget-level edge cases, validation errors, cancellation, retry, disabled state, keyboard, semantics, and custom builders.
- Unit tests cover pure models, query normalization, selection logic, pagination contracts, theme merging, and deterministic helper behavior.

Required stable selectors through `DropifyKeys`:
- Field anchor.
- Search input.
- Menu overlay/container.
- Item row keyed by stable identity.
- Selected chip keyed by stable identity.
- Loading row.
- Empty row.
- Error row.
- Retry button.
- Pagination loading row.
- Pagination error row.
- Pagination retry button.
- No-more-items row.
- Select all action.
- Clear all action.
- Validation error text.
- Demo screen entries in the example app.

Deterministic seams required for tests:
- Configurable debounce duration.
- Fake async item loader.
- Fake paginated loader.
- Controllable completers for out-of-order response tests.
- Stable identities for items.
- Public keys from `DropifyKeys`.
- Test harness widgets that own controlled selected values.
- Example app fake repositories that simulate success, empty, error, retry, and pagination.

Verification commands:
```sh
flutter pub get
flutter analyze
flutter test
cd example && flutter pub get
cd example && flutter analyze
cd example && flutter test
```

Expected validation outcome:
- Root analyzer passes with no warnings.
- Root tests pass.
- Example analyzer passes with no warnings.
- Example tests pass.
- README code snippets match the implemented public API.
- The package exports no placeholder `Calculator` API.
- Any known testing gaps or residual risks are documented in implementation notes or final handoff.
</validation>

<done_when>
Implementation is complete when all of these are true:
1. `./lib/flutter_dropify.dart` exports the real Dropify public API.
2. No placeholder generated API remains.
3. `./pubspec.yaml` has a meaningful description and a Flutter lower bound compatible with the selected overlay primitives.
4. `DropifyBuilder<T>` exists and powers the convenience widgets.
5. `DropifyDropdown<T>` exists and supports static single-select.
6. `DropifyDropdown<T>.multi` exists and supports static multi-select.
7. `DropifyAsyncDropdown<T>` exists and supports async single-select.
8. `DropifyAsyncDropdown<T>.multi` exists and supports async multi-select.
9. `DropifyPaginatedDropdown<T, PageKey>` exists and supports paginated single-select.
10. `DropifyPaginatedDropdown<T, PageKey>.multi` exists and supports paginated multi-select.
11. `DropifyPageResult<T, PageKey>` is the public paginated result type.
12. Primary public paginated constructors do not expose `PagingController`, `PagingState`, or paging package state types.
13. Search works in every dropdown family.
14. Controlled selection works consistently.
15. Multi-select preserves selected values across filtering, async result changes, pages, and searches.
16. Loading, empty, error, retry, load-more, load-more-error, and no-more states work.
17. Builder customization works for field, search, item, selected display, loading, data, empty, error, overlay, menu header/footer, load-more, load-more-error, and no-more states.
18. `DropifyTheme` and `DropifyThemeData` work with defaults, inherited values, and per-widget overrides.
19. Form validation is available directly on Dropify widgets without separate public form wrapper widgets.
20. Keyboard navigation and activation work.
21. Accessibility semantics cover required states and actions.
22. `DropifyKeys` provides stable selectors for tests and robot journeys.
23. The example app is a complete navigable demo, not the generated counter app.
24. README documents installation, basic usage, async usage, paginated usage, multi-select, validation, builders, theming, and stable selectors.
25. CHANGELOG describes the implemented release.
26. Root analyzer and tests pass.
27. Example analyzer and tests pass.
28. README examples compile against the implemented public API.
</done_when>
