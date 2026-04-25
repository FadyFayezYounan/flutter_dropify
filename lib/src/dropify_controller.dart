import 'package:flutter/foundation.dart';

/// Imperative interaction commands supported by [DropifyController].
enum DropifyControllerCommand {
  /// Opens the dropdown menu.
  open,

  /// Closes the dropdown menu.
  close,

  /// Clears the current search text.
  clearSearch,

  /// Reloads the current query.
  refresh,

  /// Retries the current failed query.
  retry,
}

/// Controls transient Dropify interaction state.
///
/// Selection remains controlled by the host widget through `value` and
/// `onChanged`; this controller only opens, closes, clears search, refreshes,
/// or retries the active source.
class DropifyController extends ChangeNotifier {
  DropifyControllerCommand? _command;

  /// The latest command requested by the host app.
  DropifyControllerCommand? get command => _command;

  /// Opens the dropdown menu.
  void open() {
    _dispatch(DropifyControllerCommand.open);
  }

  /// Closes the dropdown menu.
  void close() {
    _dispatch(DropifyControllerCommand.close);
  }

  /// Clears the current search text.
  void clearSearch() {
    _dispatch(DropifyControllerCommand.clearSearch);
  }

  /// Reloads the current query.
  void refresh() {
    _dispatch(DropifyControllerCommand.refresh);
  }

  /// Retries the current failed query.
  void retry() {
    _dispatch(DropifyControllerCommand.retry);
  }

  void _dispatch(DropifyControllerCommand command) {
    _command = command;
    notifyListeners();
  }
}
