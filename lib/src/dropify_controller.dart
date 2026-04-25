import 'package:flutter/foundation.dart';

/// A controller for Dropify interaction commands.
class DropifyController extends ChangeNotifier {
  DropifyControllerCommand? _pendingCommand;
  String? _pendingSearchText;

  /// Opens the attached dropdown.
  void open() {
    _dispatch(DropifyControllerCommand.open);
  }

  /// Closes the attached dropdown.
  void close() {
    _dispatch(DropifyControllerCommand.close);
  }

  /// Toggles the attached dropdown.
  void toggle() {
    _dispatch(DropifyControllerCommand.toggle);
  }

  /// Replaces the attached dropdown search text.
  void search(String text) {
    _pendingSearchText = text;
    _dispatch(DropifyControllerCommand.search);
  }

  /// Clears the attached dropdown search text.
  void clearSearch() {
    search('');
  }

  /// Requests a source refresh from the attached dropdown.
  void refresh() {
    _dispatch(DropifyControllerCommand.refresh);
  }

  /// Retries the last failed operation in the attached dropdown.
  void retry() {
    _dispatch(DropifyControllerCommand.retry);
  }

  /// Takes the latest pending command for widget consumption.
  DropifyControllerCommand? takePendingCommand() {
    final command = _pendingCommand;
    _pendingCommand = null;
    return command;
  }

  /// Takes the latest pending search text for widget consumption.
  String? takePendingSearchText() {
    final text = _pendingSearchText;
    _pendingSearchText = null;
    return text;
  }

  void _dispatch(DropifyControllerCommand command) {
    _pendingCommand = command;
    notifyListeners();
  }
}

/// Commands emitted by [DropifyController].
enum DropifyControllerCommand {
  /// Open the dropdown.
  open,

  /// Close the dropdown.
  close,

  /// Toggle the dropdown.
  toggle,

  /// Update search text.
  search,

  /// Clear and reload current data.
  refresh,

  /// Retry the current failed data operation.
  retry,
}
