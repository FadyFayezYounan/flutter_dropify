## Overview

Production `flutter_dropify` package. Builder-first core, typed convenience widgets, complete demo/docs.

**Spec**: `ai_specs/001-flutter_dropify-spec.md` (read this file for full requirements)

## Context

- **Structure**: flat generated package; add feature-first `lib/src/` API files
- **State management**: no app state library; local widget state + controlled selection callbacks
- **Reference implementations**: `refrences/flutter_raw_menu_anchor.dart`, `refrences/flutter_menu_anchor.dart`, `refrences/flutter_dropdown_menu.dart`
- **Assumptions/Gaps**: local Flutter 3.38.4/Dart 3.10.3; `infinite_scroll_pagination` latest 5.1.1; set Flutter lower bound after RawMenuAnchor API check
- **Convention note**: no repo patterns to preserve; follow Flutter package conventions + existing `flutter_lints`

## Plan

### Phase 1: Static Slice (Complete)

- **Goal**: static single/multi critical path, end-to-end
- [x] `pubspec.yaml` - description, Flutter lower bound after `RawMenuAnchor`/`MenuController`/`TapRegion` verification
- [x] `lib/flutter_dropify.dart` - export real public API; remove placeholder surface
- [x] `lib/src/dropify_item.dart` - immutable `DropifyItem<T>`, identity fallback, duplicate-visible assert helper
- [x] `lib/src/dropify_query.dart` - raw/normalized query model
- [x] `lib/src/dropify_controller.dart` - interaction-only open/close/toggle/search/refresh/retry contract
- [x] `lib/src/dropify_keys.dart` - stable selector contract
- [x] `lib/src/dropify_source.dart` - static source + filter callback types
- [x] `lib/src/dropify_builders.dart` - public builder typedefs/state objects needed for static UI
- [x] `lib/src/dropify_builder.dart` - RawMenuAnchor core, search, lazy list, outside tap, empty state, disabled state
- [x] `lib/src/dropify_dropdown.dart` - `DropifyDropdown<T>` and `.multi`; controlled selection only
- [x] `test/flutter_dropify_test.dart` - replace placeholder; package static behavior tests
- [x] TDD: static single opens, filters, selects enabled item, calls `onChanged`, closes
- [x] TDD: static multi toggles values, emits immutable lists, clear all, select visible, stays open
- [x] TDD: empty/search-empty, disabled widget/row, custom filter, duplicate visible identity assert
- [x] TDD: builder callbacks receive open/search/selected/disabled/highlight state without losing keys
- [x] Robot journey tests + selectors/seams: static select and static multi using `DropifyKeys.field`, `.searchInput`, item rows, clear/select-all
- [x] Verify: `flutter analyze` && `flutter test`

### Phase 2: Async Slice (Complete)

- **Goal**: async loading, search, errors, stale-response safety
- [x] `lib/src/dropify_source.dart` - async source/loader typedefs, `DropifyQuery` plumbing
- [x] `lib/src/dropify_async_dropdown.dart` - `DropifyAsyncDropdown<T>` and `.multi`
- [x] `lib/src/dropify_builder.dart` - loading, error, retry, debounce, latest-response-wins, dispose guards
- [x] `lib/src/dropify_controller.dart` - refresh/retry wiring to current source/query
- [x] `lib/src/dropify_builders.dart` - loading/error builder state + retry callback
- [x] `test/flutter_dropify_test.dart` - async widget tests with fake loaders/completers
- [x] TDD: first open shows loading, renders latest loaded items, selects enabled item
- [x] TDD: first-load error shows error UI, calls `onError`, retry succeeds, menu stays open
- [x] TDD: debounced search reloads query, stale completions ignored, sync throws treated as loader errors
- [x] TDD: async multi selections persist across reload/search/error/retry
- [x] Robot journey tests + selectors/seams: async fail, retry, search, select; fake loader + controllable completers
- [x] Verify: `flutter analyze` && `flutter test`

### Phase 3: Paginated Slice (Complete)

- **Goal**: paged loading without public paging-package leakage
- [x] `pubspec.yaml` - add `infinite_scroll_pagination: ^5.1.1`
- [x] `lib/src/dropify_pagination.dart` - `DropifyPageRequest<PageKey>`, `DropifyPageResult<T, PageKey>`, invalid-result asserts
- [x] `lib/src/dropify_paginated_dropdown.dart` - `DropifyPaginatedDropdown<T, PageKey>` and `.multi`
- [x] `lib/src/dropify_source.dart` - paginated source/loader typedefs
- [x] `lib/src/dropify_builder.dart` - internal paging adapter, first page, next page, reset on search, scroll reset
- [x] `lib/src/dropify_builders.dart` - load-more/loading-error/no-more builder states
- [x] `test/flutter_dropify_test.dart` - paginated widget/model tests; no public `PagingController`/`PagingState`
- [x] TDD: first page loads on open, scroll loads next page once, single select closes
- [x] TDD: duplicate load-more coalesced, next-page error preserves prior items, retry failed page only
- [x] TDD: search resets pages/scroll and ignores stale page responses
- [x] TDD: paginated multi selections persist across pages/searches
- [x] TDD: invalid page result asserts clearly
- [x] Robot journey tests + selectors/seams: paginated select; paginated multi page-one + page-two + search persistence
- [x] Verify: `flutter pub get` && `flutter analyze` && `flutter test`

### Phase 4: Theme, Form, Keyboard, A11y

- **Goal**: production interaction polish
- [ ] `lib/src/dropify_theme.dart` - `DropifyTheme`, `DropifyThemeData`, defaults, `copyWith`, merge/resolve, equality, diagnostics
- [ ] `lib/src/dropify_form.dart` - internal form helpers; no public form wrapper widgets
- [ ] `lib/src/dropify_dropdown.dart` - validator/autovalidate/onSaved/reset/initial value parameters
- [ ] `lib/src/dropify_async_dropdown.dart` - same direct form parameters
- [ ] `lib/src/dropify_paginated_dropdown.dart` - same direct form parameters
- [ ] `lib/src/dropify_builder.dart` - keyboard traversal/activation/highlight, Escape close, semantics, safe-area/constraint sizing
- [ ] `lib/src/dropify_builders.dart` - theme-aware default UI state contracts
- [ ] `test/flutter_dropify_test.dart` - theme/form/keyboard/semantics/responsive overlay tests
- [ ] TDD: theme defaults, inherited theme, per-widget overrides, diagnostics
- [ ] TDD: form validate/save/reset syncs controlled host value and exposes error text
- [ ] TDD: Tab, Enter/Space, arrows, Escape; disabled rows skipped
- [ ] TDD: semantics expanded/selected/checked/disabled/loading/empty/error/retry/select-all/clear-all
- [ ] TDD: overlay width/default constraints, screen bounds, text scale, view insets
- [ ] Robot journey tests + selectors/seams: form validate/select/validate success/reset; stable validation-error key
- [ ] Verify: `flutter analyze` && `flutter test`

### Phase 5: Demo And Docs

- **Goal**: usable example app and publishable docs
- [ ] `example/pubspec.yaml` - add path dependency on root package; keep generated lint baseline
- [ ] `example/lib/main.dart` - replace counter app with navigable Dropify demo
- [ ] `example/test/widget_test.dart` - replace counter test with robot-style demo journeys
- [ ] `README.md` - install, static, multi, async, paginated, form, builders, theming, selector notes
- [ ] `CHANGELOG.md` - v0.1 implemented release notes
- [ ] TDD: example static/async/paginated/form/custom-theme journeys through public app UI
- [ ] TDD: README snippets compile against implemented API where practical
- [ ] Robot journey tests + selectors/seams: demo screen entries, fake repositories for success/empty/error/retry/pagination
- [ ] Verify: `flutter analyze` && `flutter test` && `(cd example && flutter pub get && flutter analyze && flutter test)`

## Risks / Out of scope

- **Risks**: RawMenuAnchor lower-bound accuracy; paging 5.1.1 adapter complexity; keyboard/a11y regressions across platforms
- **Out of scope**: HTTP config, remote caching, grouped sections, cascading menus, bottom-sheet mode, custom virtualization, public paging-package types, separate form wrappers
