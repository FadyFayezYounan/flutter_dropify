## Overview

Production v0.1 Dropify package. Typed dropdown core, thin convenience widgets, example, docs.

**Spec**: `ai_specs/001-flutter_dropify-spec.md` (read this file for full requirements)

## Context

- **Structure**: generated package shell; move to feature-first `lib/src/` + public barrel
- **State management**: local `StatefulWidget` state/controllers; no Riverpod/Bloc/Provider
- **Reference implementations**: `refrences/flutter_raw_menu_anchor.dart`, `refrences/flutter_menu_anchor.dart`, `refrences/flutter_dropdown_menu.dart`
- **Assumptions/Gaps**: Flutter 3.38.4 exposes `RawMenuAnchor`; use it first, `OverlayPortal` fallback only if analyzer blocks required behavior
- **Convention note**: no runtime deps today; keep callback-first/local state for package consistency

## Plan

### Phase 1: Static Single Slice (Complete)

- **Goal**: import package, open static dropdown, search, select, close
- [x] `lib/flutter_dropify.dart` - replace `Calculator`; export public API
- [x] `lib/src/dropify_item.dart` - typed item model, label, enabled, stable key/equality guidance
- [x] `lib/src/dropify_source.dart` - static source, local filter, query model
- [x] `lib/src/dropify_selection.dart` - controlled single selection helpers
- [x] `lib/src/dropify_theme.dart` - minimal defaults, copy/merge shell
- [x] `lib/src/dropify_field.dart` - `RawMenuAnchor` field, local search, lazy list, empty/disabled states
- [x] `lib/src/dropify_dropdown.dart` - thin static single-select wrapper
- [x] `lib/src/widgets/` - field anchor, overlay panel, search input, item row, empty row, stable keys
- [x] `test/flutter_dropify_test.dart` - replace placeholder coverage through public API
- [x] TDD: item labels/filtering/disabled identity -> implement static source/model
- [x] TDD: open/search/select/close updates `onChanged` once -> implement field/wrapper
- [x] TDD: empty and disabled states visible; disabled never opens/calls callbacks -> implement states
- [x] Robot journey tests + selectors/seams for static select: field, search input, menu, item row, empty row
- [x] Verify: `flutter analyze` && `flutter test`

### Phase 2: Async Source

- **Goal**: async open/search/retry with latest-response-wins
- [ ] `lib/src/dropify_source.dart` - async source, loader/query callbacks, debounce config
- [ ] `lib/src/dropify_controller.dart` - open/close, clear search, refresh, retry interaction API
- [ ] `lib/src/dropify_field.dart` - loading/error/retry/empty async states, stale result guards, dispose guards
- [ ] `lib/src/dropify_async_dropdown.dart` - thin async single-select wrapper
- [ ] `lib/src/widgets/` - loading row, error row, retry button keys
- [ ] TDD: initial async success shows loading then items -> implement loader state
- [ ] TDD: loader throw shows error, calls `onError`, retry reloads same query -> implement error path
- [ ] TDD: debounced search ignores stale older completion -> implement request tokens/debounce seam
- [ ] Robot journey tests + selectors/seams for async retry then select: fake loader, zero debounce, retry key
- [ ] Verify: `flutter analyze` && `flutter test`

### Phase 3: Pagination

- **Goal**: first page, scroll load more, inline page errors
- [ ] `lib/src/dropify_source.dart` - page request/result contracts, page key/hasMore assertions
- [ ] `lib/src/dropify_field.dart` - first-page load, next-page coalescing, query reset, scroll reset
- [ ] `lib/src/dropify_paginated_dropdown.dart` - thin paginated single-select wrapper
- [ ] `lib/src/widgets/` - pagination loading/end/error rows, retry row keys
- [ ] TDD: open loads first page; near-end scroll loads next page once -> implement pagination trigger
- [ ] TDD: next-page failure preserves loaded items and retries failed page only -> implement inline error
- [ ] TDD: query change resets pages/scroll and ignores stale page completions -> implement reset semantics
- [ ] Robot journey tests + selectors/seams for scroll load then select: deterministic threshold, fake page loader
- [ ] Verify: `flutter analyze` && `flutter test`

### Phase 4: Multi-Select

- **Goal**: controlled multi-select, actions, paginated persistence
- [ ] `lib/src/dropify_selection.dart` - multi selection helpers, immutable list semantics
- [ ] `lib/src/dropify_field.dart` - multi mode, no auto-close by default, selected state across filters/pages
- [ ] `lib/src/dropify_multi_select.dart` - static/async/paginated factories
- [ ] `lib/src/widgets/` - selected chips/summary, select-all, clear-all, checked row semantics
- [ ] TDD: select/deselect emits new lists and keeps menu open -> implement multi mode
- [ ] TDD: clear all and select all affect loaded/filter-visible enabled items only -> implement actions
- [ ] TDD: paginated selections persist when page/query changes hide selected items -> implement selected display fallback
- [ ] Robot journey tests + selectors/seams for multi clear/select and multi paginated across pages: chip, select-all, clear-all keys
- [ ] Verify: `flutter analyze` && `flutter test`

### Phase 5: Forms, Keyboard, Theme

- **Goal**: form validation, accessibility, responsive polish
- [ ] `lib/src/dropify_field.dart` - keyboard open/select/highlight/Escape, outside tap, route pop, disabled close
- [ ] `lib/src/dropify_theme.dart` - full practical theme data, defaults, merge/copy behavior
- [ ] `lib/src/dropify_form_field.dart` - single/multi form wrappers, validator/reset/save/error display
- [ ] `lib/src/widgets/` - responsive sizing, safe area/keyboard insets, semantics wrappers, long-label handling
- [ ] `lib/flutter_dropify.dart` - export form/theme/controller APIs with dartdoc
- [ ] TDD: required single/multi validation fails and announces visible error -> implement form wrappers
- [ ] TDD: keyboard navigation skips disabled rows and Escape closes -> implement focus/actions
- [ ] TDD: per-widget theme overrides inherited defaults -> implement theme resolution
- [ ] Robot journey tests + selectors/seams for validation and keyboard path: form submit key, error text, highlighted row
- [ ] Verify: `flutter analyze` && `flutter test`

### Phase 6: Example And Docs

- **Goal**: demonstrable package; consumer copy/paste path
- [ ] `example/pubspec.yaml` - add path dependency on root package
- [ ] `example/lib/main.dart` - replace counter with static, async, paginated, multi, multi-paginated, validation, theme demos
- [ ] `example/test/widget_test.dart` - smoke demo import/render path; key critical demo sections
- [ ] `README.md` - package intro, install, quick start, static/async/paginated/multi/form/theme examples, limits
- [ ] `CHANGELOG.md` - initial real implementation entry
- [ ] `pubspec.yaml` - update description/homepage only if accurate; no runtime deps unless necessary
- [ ] TDD: example app renders primary demo sections from package widgets -> implement demo smoke path
- [ ] Robot journey tests + selectors/seams for demo critical flows where practical; document visual placement residual risk
- [ ] Verify: `flutter analyze` && `flutter test` && `(cd example && flutter analyze && flutter test)`

## Risks / Out of scope

- **Risks**: overlay placement/safe-area visual edge cases need manual or screenshot follow-up; async race bugs need strict fake-loader tests; broad API surface may creep beyond v0.1
- **Out of scope**: built-in HTTP client/config; remote caching beyond in-widget loaded pages; grouped/nested/cascading menus; modal bottom-sheet presentation; custom virtualization beyond lazy lists
