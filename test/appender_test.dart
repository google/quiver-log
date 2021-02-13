// Copyright 2019 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library quiver.log.appender_test;

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:quiver_log/log.dart';
import 'package:test/test.dart';

void main() {
  group('Appender', () {
    test('Appends handles log message and formats before output', () {
      var appender = InMemoryListAppender(SimpleStringFormatter());
      var logger = SimpleLogger();
      appender.attachLogger(logger);

      logger.info('test message');

      expect(appender.messages.last, 'Formatted test message');
    });

    test('Retries logging using diagnostic formatter', () {
      var appender = InMemoryListAppender(ExceptionalFormatter());
      var logger = SimpleLogger();
      appender.attachLogger(logger);

      logger.info('test message');

      expect(appender.messages.last, contains('ErrorDiagnosticFormatter'));
    });

    test('Triggers assert when diagnostic formatter fails', () {
      // A new zone is used to ensure assert is not caught in the zone started
      // by the test harness.
      var failureDetected = false;
      runZonedGuarded(() {
        var appender = ExceptionalAppender();
        var logger = SimpleLogger();
        appender.attachLogger(logger);
        logger.info('test message');
      }, (e, s) {
        failureDetected = true;
        expect(e, isA<AssertionError>());
        expect(e, contains('failed to append'));
      });
      expect(failureDetected, isTrue,
          reason: 'Failed to detect error in appender.');
    });
  });
}

class ExceptionalAppender extends Appender {
  ExceptionalAppender() : super(SimpleStringFormatter());

  @override
  void append(LogRecord record, Formatter formatter) {
    throw 'cannot append';
  }
}

class SimpleLogger implements Logger {
  final _controller = StreamController<LogRecord>(sync: true);

  @override
  Stream<LogRecord> get onRecord => _controller.stream;

  @override
  void info(Object? msg, [Object? message, StackTrace? stackTrace]) =>
      _controller.add(LogRecord(Level.INFO, msg.toString(), 'simple'));

  @override
  dynamic noSuchMethod(Invocation i) {}
}

class SimpleStringFormatter implements Formatter {
  @override
  String call(LogRecord record) => 'Formatted ${record.message}';
}

class ExceptionalFormatter implements Formatter {
  @override
  String call(LogRecord record) => throw 'this aint good';
}
