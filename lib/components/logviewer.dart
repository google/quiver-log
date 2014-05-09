library logviewer;

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:logging/logging.dart';
import './logviewer_controller.dart';

@CustomTag('log-viewer')
class LogViewer extends PolymerElement  {
  @published int windowWidth = 500;
  @published int windowHeight = 350;
  @observable List<LogRecord> messages = toObservable(new List<LogRecord>());
  @observable List<Filter> filters = toObservable(new List<Filter>());
  @published String log = "";
  LogViewerController controller;

  LogViewer.created() : super.created() {
    this.controller = new LogViewerController(this);
    this.changes.listen((change) {
      this.controller.logMayHaveChanged();
    });
  }

  // This is mainly a hack for testing. Instead of the controller directly
  // accessing the @published field, we use logName. Normally we wouldn't care,
  // though it might be slightly cleaner to separate the attribute from what the
  // controller accesses. However, unittest.mock.Mock has a concrete field 'log'
  // that means you can't mock an object with a field named 'log'.
  get logName => log;

  void consistentScrollingDuringMutation(mutation) {
    if (shadowRoot == null) {
      mutation();
      return;
    }

    var log = shadowRoot.querySelector("#logMessages");
    
    // We want to keep the person scrolled to the bottom, but only if they're
    // already scrolled to the bottom. It'd be annoying to have to pause your
    // application in the debugger to read some log messages.
    bool atBottom = log.scrollTop + log.clientHeight == log.scrollHeight;
    mutation();
    if (atBottom) {
      // The data binding process happens on window idle. Queue this update
      // for when the data binding has completed.
      // TODO: shouldn't I be able to run the mutation before, during, or after
      // this method runs and have the same result?
      Timer.run(() => log.scrollTop = log.scrollHeight);
    }
  }

  void newFilterKeyUp(KeyboardEvent evt, var detail, Node n) {
    if (evt.keyCode == 13) {
      TextInputElement elem = this.shadowRoot.querySelector("#newFilter");
      controller.addFilter(elem.value);
      elem.value = "";
    }
  }

  void showFilters(List<Filter> filters) {
    this.filters = filters.toList();
  }

  void killFilter(Event e, var detail, Node target) {
    Element elem = target;
    var id = int.parse(elem.id, onError: (e) => -1);
    if (id != -1) {
      controller.killFilter(id);
    }
  }

  String format(LogRecord record) {
    return "${record.time} [${record.level}] ${record.loggerName}: ${record.message}";
  }
}
