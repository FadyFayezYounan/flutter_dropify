# Flutter Dropify Package Implementation Plan

## Goal

Build `flutter_dropify` into a production-ready Flutter package for app
developers who need reusable, typed, highly customizable dropdown components
without rebuilding search, async loading, pagination, selection, validation, and
theming logic in every app.

The package should be universal enough to support any dropdown visual style or
shape through builders, while still offering simple source-specific convenience
widgets for common use cases.

## Repository Context

- This repository is a Flutter package, not a full app.
- The package entrypoint is `lib/flutter_dropify.dart`.
- The `example/` folder is a separate generated Flutter app and should become
  the package demo app.
- Existing README, CHANGELOG, and placeholder package APIs are generated
  scaffolding and should be replaced during implementation.
- The `refrences/` folder is intentionally misspelled and contains commented
  Flutter framework source references for dropdown, menu, and overlay behavior.
- Reference files to study before implementation:
  - `refrences/flutter_raw_menu_anchor.dart`
  - `refrences/flutter_menu_anchor.dart`
  - `refrences/flutter_dropdown_menu.dart`
  - `refrences/flutter_dropdown_button.dart`

## Product Direction

Use a builder-first core with source-specific convenience widgets.

The core must allow package users to build dropdowns with any closed-field
shape, overlay shape, item design, selected-value display, loading UI, error UI,
empty UI, and pagination row UI.

Do not create a separate `DropifyMultiSelect<T>` widget. Multi-select belongs
as a named constructor on each source-specific widget family.

Avoid the public name `DropifyLayoutBuilder`. In Flutter, `LayoutBuilder`
strongly implies constraint-based layout. Use `DropifyBuilder<T>` for the
low-level universal dropdown composition widget.

## Public API Shape

### Core

- `DropifyBuilder<T>`
  - Low-level universal dropdown core.
  - Powers all convenience widgets.
  - Supports static, async, and paginated sources.
  - Supports single and multi-selection.
  - Owns shared overlay, search, keyboard, semantics, theming, loading, empty,
    error, retry, and selection behavior.

### Static Dropdowns

- `DropifyDropdown<T>`
  - Static item source.
  - Single-select by default.
  - Accepts `T? value` and `ValueChanged<T?> onChanged`.

- `DropifyDropdown<T>.multi`
  - Static item source.
  - Multi-select.
  - Accepts `List<T> values` and `ValueChanged<List<T>> onChanged`.

### Async Dropdowns

- `DropifyAsyncDropdown<T>`
  - Async non-paginated source.
  - Single-select by default.
  - Accepts `T? value` and `ValueChanged<T?> onChanged`.
  - Uses a typed async loader callback.

- `DropifyAsyncDropdown<T>.multi`
  - Async non-paginated source.
  - Multi-select.
  - Accepts `List<T> values` and `ValueChanged<List<T>> onChanged`.

### Paginated Dropdowns

- `DropifyPaginatedDropdown<T, PageKey>`
  - Paginated async source.
  - Single-select by default.
  - Accepts `T? value` and `ValueChanged<T?> onChanged`.
  - Uses `infinite_scroll_pagination` internally.
  - Public constructors must expose Dropify-owned page callbacks and page
    models, not `PagingController` or `PagingState`.

- `DropifyPaginatedDropdown<T, PageKey>.multi`
  - Paginated async source.
  - Multi-select.
  - Accepts `List<T> values` and `ValueChanged<List<T>> onChanged`.
  - Must preserve selected values across pages, search changes, and filters.

## Core Models And Types

Implement clear typed public models. Names may be adjusted only if the final API
is cleaner, but the concepts must remain.

- `DropifyItem<T>`
  - Equivalent to Flutter's `DropdownMenuEntry`.
  - `value`
  - `label`
  - `enabled`
  - optional metadata/building hooks if needed

- `DropifySource<T>`
  - Static source abstraction.
  - Async source abstraction.
  - Paginated source abstraction.
  - Convenience constructors should configure this internally where possible.

- `DropifyQuery`
  - Raw search text.
  - Normalized search text.
  - Any future query metadata.

- `DropifyPageRequest<PageKey>`
  - Current `DropifyQuery`.
  - Current page key, null for first page unless a different first key is
    explicitly configured.

- `DropifyPage<T, PageKey>` or `DropifyPageResult<T, PageKey>`
  - Loaded items.
  - Next page key.
  - Whether another page exists.

- `DropifyController`
  - Optional imperative controller for interaction only.
  - Supports open, close, toggle, clear search, refresh, retry.
  - Must not own selection state.

- `DropifyTheme`
  - Inherited theme widget.

- `DropifyThemeData`
  - Theme data with defaults, `copyWith`, merge/resolve behavior, and
    diagnostics.

- `DropifyKeys`
  - Stable keys for tests and robot journeys.

## Selection Rules

Selection is controlled by the host app.

Single-select constructors:

- Accept `T? value`.
- Accept `ValueChanged<T?> onChanged`.
- Close the menu after selecting an enabled item by default.
- Do not change selection when the user only types in search.

Multi-select constructors:

- Accept `List<T> values`.
- Accept `ValueChanged<List<T>> onChanged`.
- Keep the menu open after selecting or deselecting by default.
- Emit a new immutable list on every selection change.
- Support clear all.
- Support select all for the current loaded/filter-visible enabled items.
- Preserve selected values even when their items are not currently loaded,
  filtered out, or hidden by pagination.

Identity rules:

- Prefer a stable item identity property for selection and keys.
- If no stable identity is provided, fall back to `value`.
- Duplicate visible identities should assert in debug mode with a clear message.
- Disabled items remain visible but cannot be selected and are skipped by
  keyboard activation.

## Builder API

All dropdown families must support customization builders. The builder API is a
first-class part of v0.1, not a later add-on.

Shared builders:

- `fieldBuilder`
  - Builds the closed field or anchor.
  - Receives open state, enabled state, selected display data, error text if
    applicable, and callbacks such as open/toggle/clear.

- `searchBuilder`
  - Builds the search input above the list.
  - Receives controller/focus node or a safe interaction object.
  - Default search input should be practical and themeable.

- `itemBuilder`
  - Builds an item row.
  - Receives item, selected state, highlighted state, disabled state, and
    selection callback.
  - Must not break semantics, keyboard behavior, hover/focus state, or stable
    selectors.

- `selectedBuilder`
  - Builds the selected display for single-select.

- `selectedItemsBuilder`
  - Builds the selected display for multi-select.

- `loadingBuilder`
  - Builds the first-load loading state.

- `dataBuilder`
  - Optional full content override when data is available.
  - Should be advanced-use only; default list behavior should still cover common
    use cases.

- `emptyBuilder`
  - Builds empty and search-empty states.

- `errorBuilder`
  - Builds first-load or search-load error state.
  - Receives error details and retry callback.

- `overlayBuilder`
  - Optional full overlay shell override.
  - Must still allow Dropify to provide tap-region, constraints, keyboard,
    semantics, and close behavior.

- `menuHeaderBuilder`
  - Optional content above the list and below search.

- `menuFooterBuilder`
  - Optional content below the list.

Pagination-only builders:

- `loadMoreBuilder`
  - Builds the next-page loading row.

- `loadMoreErrorBuilder`
  - Builds the next-page error row.
  - Receives error details and retry callback.

- `noMoreItemsBuilder`
  - Builds the end-of-list row.

- `pagedItemBuilder`
  - Optional paginated-specific item row builder.
  - If null, reuse `itemBuilder`.

## Search Behavior

Every dropdown mode has a search field above the list by default.

Static search:

- Uses local filtering.
- Default filter is case-insensitive `label.contains(query)`.
- Allows a custom filter callback.
- Clearing search restores the original item list.

Async search:

- Loader receives `DropifyQuery`.
- Debounce defaults to 300 milliseconds.
- Debounce duration must be configurable for tests and special UX.
- Latest response wins.
- Stale responses must not overwrite newer visible state.
- Loader errors produce visible error UI and optional `onError`.

Paginated search:

- Search resets loaded pages and scroll position.
- First page reloads for the new query.
- Stale first-page or next-page responses must be ignored.
- Selected multi values must survive query changes.

## Pagination Behavior

Use `infinite_scroll_pagination` internally for paginated dropdowns.

Public API rules:

- Do not expose `PagingController`, `PagingState`, or package-specific paging
  types in the primary public constructors.
- Public API should use Dropify-owned typed callbacks and page models.
- This keeps the user API stable if the internal paging package changes later.

Required behavior:

- Load the first page when the menu opens unless cached state is still valid.
- Load more when the scroll position approaches the end.
- Coalesce duplicate load-more triggers.
- Preserve already loaded items when a next-page request fails.
- Render a load-more loading row through `loadMoreBuilder`.
- Render a next-page error row through `loadMoreErrorBuilder`.
- Render an optional end-of-list row through `noMoreItemsBuilder`.
- Retry next-page errors without reloading successful pages.
- Reset pagination when the query changes.
- Never clear multi-select values just because their items are not in the
  current loaded page.

## Overlay And Interaction Architecture

Use Flutter's modern menu/overlay primitives as implementation guidance.

Preferred implementation:

- Use `RawMenuAnchor` and `MenuController` for the anchored overlay foundation.
- Use `TapRegion` behavior so outside taps close correctly.
- Use lazy scrollable lists for rows.

Fallback only if required:

- `OverlayPortal` or `OverlayEntry` with `CompositedTransformTarget` and
  `CompositedTransformFollower`.

Do not use Flutter `DropdownMenu` directly as the core implementation because
its fixed entry model is too restrictive for async loading, pagination, retry,
and multi-select.

Overlay requirements:

- Width matches the field by default.
- Supports min width, max width, and max height through theme/configuration.
- Stays within visible screen bounds and safe areas.
- Handles small screens, rotation/resizing, text scale, and keyboard insets.
- Dismisses on outside tap, Escape, route pop, and disabled-state changes.
- Does not dismiss after each multi-select item tap unless configured.

## Keyboard And Accessibility

Keyboard support:

- Tab focus traversal.
- Enter/Space to open and select.
- ArrowUp/ArrowDown to move highlight.
- Escape to close.
- Search input focus when menu opens, according to platform-appropriate
  behavior.
- Disabled rows skipped by keyboard activation.

Accessibility semantics:

- Field expanded/collapsed state.
- Enabled/disabled state.
- Selected item state.
- Multi-select checked state.
- Loading state.
- Empty state.
- Error state and retry action.
- Clear all and select all actions.

## Theme Requirements

Provide a practical theme system:

- `DropifyTheme`
- `DropifyThemeData`
- Per-widget theme overrides
- Merge with inherited/default values

Theme coverage:

- Field shape, padding, color, border, text style, icon style.
- Overlay/menu shape, elevation, padding, color, border.
- Search input decoration and text style.
- Item row height, padding, text style, hover/highlight/selected/disabled
  styles.
- Multi-select chips or summary display.
- Loading, error, empty, retry, load-more, and no-more rows.
- Spacing and constraints.
- Animation durations/curves if animations are implemented.

## Forms

Add form support after the main dropdown behavior is stable.

Required form APIs:

- Single-select form field wrapper.
- Multi-select form field wrapper.
- Validator.
- `AutovalidateMode`.
- `onSaved`.
- Reset behavior.
- Enabled/disabled behavior.
- Error display on the field.

Validation rules:

- Required single-select fails when `value == null`.
- Required multi-select fails when `values.isEmpty`.
- Search text is never treated as selected value.
- Errors must be visible and accessible.

## Error Handling

Initial async load error:

- Show visible error UI.
- Provide retry.
- Call optional `onError(Object error, StackTrace stackTrace)`.
- Keep the menu open unless the user dismisses it.

Search load error:

- Show visible error UI for the current query.
- Retry the same query.

Next-page error:

- Preserve loaded items.
- Show inline pagination error row.
- Retry only the failed page.

Late results:

- Ignore results after dispose.
- Ignore results after menu close if no longer relevant.
- Ignore stale results after query/source/refresh changes.
- Do not call `setState` after dispose.

Invalid configuration:

- Assert in debug mode with clear messages.
- Examples:
  - negative debounce duration
  - duplicate visible item identities
  - missing loader for async source
  - invalid pagination result such as reporting more pages without a next key
    when the selected pagination mode requires a next key

## Implementation Phases

### Phase 1: Static Dropdowns

Implement:

- `DropifyBuilder<T>` static source path.
- `DropifyDropdown<T>`.
- `DropifyDropdown<T>.multi`.
- `DropifyItem<T>`.
- Static `DropifySource<T>`.
- Controlled single and multi-selection.
- Local search.
- Empty state.
- Disabled state.
- Default field, search, overlay, item, selected, loading, empty, and error
  widgets.
- Stable keys.

Verify:

- Static single open/search/select/close.
- Static multi select/deselect/clear/select visible.
- Empty state.
- Disabled state.
- Custom builders are invoked.

### Phase 2: Async Dropdowns

Implement:

- `DropifyAsyncDropdown<T>`.
- `DropifyAsyncDropdown<T>.multi`.
- Async source callbacks.
- Loading state.
- Error state.
- Retry.
- Debounced search.
- Latest-response-wins protection.
- `onError`.
- Controller refresh/retry.

Verify:

- Initial load success.
- Initial load error and retry.
- Search reload.
- Stale responses ignored.
- Multi-selection persists across async result changes.

### Phase 3: Paginated Dropdowns

Implement:

- Add `infinite_scroll_pagination` dependency.
- Internal pagination adapter.
- `DropifyPaginatedDropdown<T, PageKey>`.
- `DropifyPaginatedDropdown<T, PageKey>.multi`.
- First-page loading/error/empty states.
- Next-page loading row through `loadMoreBuilder`.
- Next-page error row through `loadMoreErrorBuilder`.
- End-of-list row through `noMoreItemsBuilder`.
- Query reset.
- Retry failed next page.

Verify:

- First page loads on open.
- Scroll loads next page once.
- Next-page failure preserves loaded items.
- Retry next page.
- Search resets pages.
- Multi-select values persist across pages and searches.

### Phase 4: Theme, Forms, Keyboard, Accessibility

Implement:

- `DropifyTheme`.
- Full `DropifyThemeData`.
- Per-widget theme override resolution.
- Form field wrappers.
- Keyboard traversal and activation.
- Accessibility semantics.
- Responsive overlay sizing and safe-area behavior.

Verify:

- Theme inheritance and overrides.
- Required validation.
- Keyboard open/select/highlight/close.
- Semantics for selected, disabled, loading, error, retry, and checked states.

### Phase 5: Example And Documentation

Implement:

- Replace the example counter app.
- Demonstrate:
  - static single
  - static multi
  - async single
  - async multi
  - paginated single
  - paginated multi
  - validation
  - custom builders
  - theme overrides
- Update README.
- Update CHANGELOG.
- Update package description if appropriate.

Verify:

- Root analyzer and tests pass.
- Example analyzer and tests pass.
- README examples match the implemented public API.

## Test Plan

Unit tests:

- `DropifyItem` identity/equality.
- Duplicate identity assertions.
- Static filtering.
- Query normalization.
- Page request/result contracts.
- Selection helpers.
- Theme `copyWith`, merge, and defaults.

Widget tests:

- `DropifyDropdown`.
- `DropifyDropdown.multi`.
- `DropifyAsyncDropdown`.
- `DropifyAsyncDropdown.multi`.
- `DropifyPaginatedDropdown`.
- `DropifyPaginatedDropdown.multi`.
- Disabled state.
- Empty state.
- Loading state.
- Error and retry state.
- Load-more state.
- Load-more error and retry state.
- No-more-items state.
- Custom builder invocation.
- Keyboard navigation.
- Form validation.
- Theme overrides.

Robot-style journey tests:

- Static select: open, search, select, close.
- Static multi: open, select multiple, clear, select visible.
- Async: open, fail, retry, search, select.
- Paginated: open, scroll load more, select.
- Paginated multi: select from page one, load page two, select more, search,
  ensure previous selections persist.

Required stable selectors:

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

Verification commands:

```sh
flutter pub get
flutter analyze
flutter test
cd example && flutter pub get
cd example && flutter analyze
cd example && flutter test
```

## Boundaries

In scope for v0.1:

- Static dropdowns.
- Async dropdowns.
- Paginated dropdowns.
- Single and multi-selection.
- Search in every mode.
- Custom builders.
- Loading, data, error, empty, load-more, load-more-error, and no-more states.
- Theme.
- Form wrappers.
- Example and docs.

Out of scope for v0.1:

- Built-in HTTP client configuration.
- URL/header/JSON-path based API setup.
- Remote caching beyond current widget state.
- Grouped sections.
- Cascading submenus.
- Modal bottom-sheet presentation.
- Full custom virtualization beyond Flutter lazy lists and the paging package.

## Done When

The implementation is complete when:

- `lib/flutter_dropify.dart` exports the real Dropify public API.
- No placeholder `Calculator` API remains.
- All public constructors listed in this plan exist.
- Static, async, paginated, static multi, async multi, and paginated multi flows
  work.
- Search works in every dropdown family.
- Builder customization works for field, search, item, selected display,
  loading, data, empty, error, overlay, menu header/footer, load-more,
  load-more-error, and no-more states.
- Pagination is powered internally by `infinite_scroll_pagination`.
- Controlled selection works consistently.
- Multi-select preserves values across filtering and pages.
- Form validation works.
- Theme overrides work.
- Example app demonstrates the package.
- README and CHANGELOG are updated.
- Root and example analyzer/tests pass.
