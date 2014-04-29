library logpopup;

import 'package:polymer/polymer.dart';

// TODO:
// * Usage example / test page.
// * Help text.
// * Highlight matching regex for regex matches.
//   * Hover: highlight the matching filter.
// * Log entry view: filename, concise timestamp, etc.
//   * Click filename: only show this file.
//   * Before/after buttons for timestamps.
// * Expand stacktrace for log entry.
// * Store logging call site.
// * Reduce noise option. Hide log entries with this message / call site.
// * Resizable window.

/**
 * A LogPopup is a small button that hovers somewhere in your application.
 * Clicking on it opens a log window.
 */
@CustomTag("log-popup")
class LogPopup extends PolymerElement {
  /** The name of the log to listen to. Attribute. */
  @published String log = "";
  /** The width of the popped-out window, using standard CSS-style units. Attribute. */
  @published String windowWidth = "500px";
  /** The height of the popped-out window, using standard CSS-style units. Attribute. */
  @published String windowHeight = "350px";
  @observable bool expanded = false;
  @observable String logDisplay;
  @observable String title;
  @observable String windowPosition = "auto";
  @observable String buttonBottomRadius = '0.2em';
  String name;

  LogPopup.created() : super.created() {
    if (log == "") {
      name = "Logs";
    } else {
      name = log;
    }
    _display();
  }
  
  void toggle() {
    expanded = !expanded;
    _display();
  }

  void _display() {
    if (expanded) {
      logDisplay = "block";
      title = "[-] $name";
      buttonBottomRadius = '0em';
    } else {
      logDisplay = "none";
      title = "[+] $name";
      // Curved button corners are important.
      buttonBottomRadius = '0.2em';
    }
  }
}