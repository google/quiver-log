import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';
import 'dart:async';
import 'dart:html';

@CustomTag('test-app')
class TestApp extends PolymerElement {
  Logger timerLogger;
  Logger inputLogger;
  TestApp.created() : super.created() {
    hierarchicalLoggingEnabled = true;
    timerLogger = new Logger("main.timer");
    inputLogger = new Logger("main.input");
    var count = 0;
    new Timer.periodic(new Duration(seconds: 2), (t) {
      timerLogger.info("heartbeat: ${count++}");
    });
  }
  
  void logClick(event, _, sender) {
    if (inputLogger == null) {
      return;
    }
    TextInputElement input = shadowRoot.children.firstWhere((x) => x.id == "textfield", orElse: null);
    if (input == null) {
      inputLogger.info("no logger found");
    }
    inputLogger.info("input entered: ${input.value}");
  }
}