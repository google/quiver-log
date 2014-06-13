library quiver.log.logviewer_test;

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:mock/mock.dart' as mock;
import 'package:matcher/matcher.dart';
import 'package:quiver_log/components/logviewer_controller.dart';
import 'package:unittest/unittest.dart';

main() {
  group('Filter', () {
    group('Parsing', () {
      test('min date', () {
        var dateString = '2014-03-17T05:19:03.000Z';
        var filters = Filter.parseAll("mindate:$dateString");
        expect(filters.length, equals(1));
        var filter = filters[0];
        expect(filter.toString(), equals("mindate:${dateString}"));
      });

      test('max date', () {
        var dateString = '2014-03-17T05:19:03.000Z';
        var filters = Filter.parseAll("maxdate:$dateString");
        expect(filters.length, equals(1));
        var filter = filters[0];
        expect(filter.toString(), equals("maxdate:${dateString}"));
      });

      test('file.dart', () {
        var filters = Filter.parseAll('file:foo.dart');
        expect(filters.length, equals(1));
        var filter = filters[0];
        expect(filter.toString(), equals('file:foo.dart'));
      });

      test('file', () {
        var filters = Filter.parseAll('file:foo');
        expect(filters.length, equals(1));
        var filter = filters[0];
        expect(filter.toString(), equals('file:foo.dart'));
      });

      test('logger name', () {
        var filters = Filter.parseAll('logger:foo');
        expect(filters.length, equals(1));
        var filter = filters[0];
        expect(filter.toString(), equals('logger:foo'));
      });
    });

    group('Regex matching', () {
      test('non-matching regex', () {
        var logRecord = makeLogRecord(message: 'washbourne');
        // Expects 4th letter to be 's', but it's 'h'.
        var regexFilter = Filter.parseAll('/wa.sb[ou]{2}rne/')[0];
        expect(regexFilter.match(logRecord), isFalse);
      });

      test('matching regex', () {
        var logRecord = makeLogRecord(message: 'washbourne');
        var regexFilter = Filter.parseAll('/wa..b[ou]{2}rne/')[0];
        expect(regexFilter.match(logRecord), isTrue);
      });

      test('regex found later in message', () {
        var logRecord = makeLogRecord(message: 'captain washbourne');
        var regexFilter = Filter.parseAll('/wa..b[ou]{2}rne/')[0];
        expect(regexFilter.match(logRecord), isTrue);
      });
    });

    group('Exact matching', () {
      test('no match', () {
        // This would match if it were a regex.
        var logRecord = makeLogRecord(message: 'Kagamine Rin');
        var regexFilter = Filter.parseAll('"Kagamine .in"')[0];
        expect(regexFilter.match(logRecord), isFalse);
      });

      test('full message match', () {
        var logRecord = makeLogRecord(message: 'Kagamine Rin');
        var regexFilter = Filter.parseAll('"Kagamine Rin"')[0];
        expect(regexFilter.match(logRecord), isTrue);
      });

      test('partial message match', () {
        var logRecord = makeLogRecord(message: 'Vocaloid Live with Kagamine Rin');
        var regexFilter = Filter.parseAll('"Kagamine Rin"')[0];
        expect(regexFilter.match(logRecord), isTrue);
      });

      test('single word, no quotes', () {
        var logRecord = makeLogRecord(message: 'Vocaloid Live with Kagamine Rin');
        var regexFilter = Filter.parseAll('Kagamine')[0];
        expect(regexFilter.match(logRecord), isTrue);
      });
    });

    group('Date matching', () {
      // These tests require calling new DateTime.now() twice and getting different results.
      // (new LogRecord calls DateTime.now.) Thus the Timer usage.
      test('min date, record too late', () {
        var logRecord = makeLogRecord();
        new Timer(new Duration(milliseconds: 30), expectAsync0(() {
          var date = new DateTime.now();
          var filter = Filter.parseAll("mindate:${date.toIso8601String()}")[0];
          expect(filter.match(logRecord), isFalse);
        }));
      });

      test('min date, record early enough', () {
        var date = new DateTime.now();
        new Timer(new Duration(milliseconds: 30), expectAsync0(() {
          var logRecord = makeLogRecord();
          var filter = Filter.parseAll("mindate:${date.toIso8601String()}")[0];
          expect(filter.match(logRecord), isTrue);
        }));
      });

      test('max date, record late enough', () {
        var logRecord = makeLogRecord();
        new Timer(new Duration(milliseconds: 30), expectAsync0(() {
          var date = new DateTime.now();
          var filter = Filter.parseAll("maxdate:${date.toIso8601String()}")[0];
          expect(filter.match(logRecord), isTrue);
        }));
      });

      test('max date, record too early', () {
        var date = new DateTime.now();
        new Timer(new Duration(milliseconds: 30), expectAsync0(() {
          var logRecord = makeLogRecord();
          var filter = Filter.parseAll("maxdate:${date.toIso8601String()}")[0];
          expect(filter.match(logRecord), isFalse);
        }));
      });
    });

    group('Levels', () {
      test('exact, same level', () {
        var logRecord = makeLogRecord(level: Level.FINE);
        var filter = Filter.parseAll('level:fine')[0];
        expect(filter.match(logRecord), isTrue);
      });

      test('exact, lower level', () {
        var logRecord = makeLogRecord(level: Level.FINE);
        var filter = Filter.parseAll('level:info')[0];
        expect(filter.match(logRecord), isFalse);
      });

      test('exact, higher level', () {
        var logRecord = makeLogRecord(level: Level.INFO);
        var filter = Filter.parseAll('level:fine')[0];
        expect(filter.match(logRecord), isFalse);
      });

      test('at least, same level', () {
        var logRecord = makeLogRecord(level: Level.FINE);
        var filter = Filter.parseAll('minlevel:fine')[0];
        expect(filter.match(logRecord), isTrue);
      });

      test('at least, lower level', () {
        var logRecord = makeLogRecord(level: Level.FINE);
        var filter = Filter.parseAll('minlevel:info')[0];
        expect(filter.match(logRecord), isFalse);
      });

      test('at least, higher level', () {
        var logRecord = makeLogRecord(level: Level.INFO);
        var filter = Filter.parseAll('minlevel:fine')[0];
        expect(filter.match(logRecord), isTrue);
      });
    });

    group('Logger', () {
      test('same logger name', () {
        var logRecord = makeLogRecord(logger: 'denton');
        var filter = Filter.parseAll('logger:denton')[0];
        expect(filter.match(logRecord), isTrue);
      });

      test('incompatible logger name', () {
        var logRecord = makeLogRecord(logger: 'denton');
        var filter = Filter.parseAll('logger:troy')[0];
        expect(filter.match(logRecord), isFalse);
      });

      test('hierarchical matching logger name', () {
        hierarchicalLoggingEnabled = true;
        var logRecord = makeLogRecord(logger: 'denton.paul');
        var filter = Filter.parseAll('logger:denton')[0];
        expect(filter.match(logRecord), isTrue);
      });

      test('prefixes are not hierarchies', () {
        hierarchicalLoggingEnabled = true;
        var logRecord = makeLogRecord(logger: 'denton.paul');
        var filter = Filter.parseAll('logger:denton.p')[0];
        expect(filter.match(logRecord), isFalse);
      });

      test('hierarchical logging disabled so no match', () {
        hierarchicalLoggingEnabled = false;
        var logRecord = makeLogRecord(logger: 'denton.paul');
        var filter = Filter.parseAll('logger:denton')[0];
        expect(filter.match(logRecord), isFalse);
      });
    });

    group('Inverted', () {
      test('logger name match', () {
        var logRecord = makeLogRecord(logger: 'denton');
        var filter = Filter.parseAll('-logger:denton')[0];
        expect(filter.match(logRecord), isFalse);
      });

      test('logger name no match', () {
        var logRecord = makeLogRecord(logger: 'denton');
        var filter = Filter.parseAll('-logger:paul')[0];
        expect(filter.match(logRecord), isTrue);
      });
    });
  });

  group('Controller', () {
    test('showSomeMessages', () {
      var logName = 'denton.jc';
      var mockView = new mock.Mock();
      var messages = [];
      mockView.when(mock.callsTo('get logName')).alwaysReturn(logName);
      mockView.when(mock.callsTo('get messages')).alwaysReturn(messages);
      mockView.when(mock.callsTo('consistentScrollingDuringMutation', anything))
          .alwaysCall((x) => x());

      var controller = new LogViewerController(mockView);
      // Now send a few log messages...
      var logger = new Logger(logName);
      logger.info('Tracer Tong is here');
      logger.info('Paul Denton is here');
      expect(mockView.messages.length, equals(2));
      expect(mockView.messages[0].message, equals('Tracer Tong is here'));
      expect(mockView.messages[1].message, equals('Paul Denton is here'));
    });

    test('filterOutAMessage', () {
      var logName = 'denton.jc';
      var mockView = new mock.Mock();
      var messages = [];
      mockView.when(mock.callsTo('get logName')).alwaysReturn(logName);
      mockView.when(mock.callsTo('get messages')).alwaysReturn(messages);
      mockView.when(mock.callsTo('consistentScrollingDuringMutation', anything))
          .alwaysCall((x) => x());

      var controller = new LogViewerController(mockView);
      // Now send a few log messages...
      var logger = new Logger(logName);
      logger.info('Tracer Tong is here');
      logger.info('Paul Denton is here');
      controller.addFilter('Denton');
      expect(mockView.messages.length, equals(1));
      expect(mockView.messages[0].message, equals('Paul Denton is here'));
    });

    test('killAFilterShowsNewSetOfFilters', () {
      var logName = 'denton.jc';
      var mockView = new mock.Mock();
      var messages = [];
      mockView.when(mock.callsTo('get logName')).alwaysReturn(logName);
      expect(mockView.logName, equals(logName));
      mockView.when(mock.callsTo('get messages')).alwaysReturn(messages);
      expect(mockView.messages, equals(messages));

      var controller = new LogViewerController(mockView);
      controller.addFilter('/foo/');
      controller.addFilter('/bar/');
      controller.addFilter('/baz/');
      var oldFilters = controller.filters.toList();
      controller.killFilter(oldFilters[1].id);
      mockView.getLogs(mock.callsTo('showFilters', [oldFilters[0], oldFilters[2]]))
          .verify(mock.happenedAtLeast(1));
    });

    test('killAFilterShowsPreviouslyFilteredOutMessages', () {
      var logName = 'denton.jc';
      var mockView = new mock.Mock();
      var messages = [];
      mockView.when(mock.callsTo('get logName')).alwaysReturn(logName);
      mockView.when(mock.callsTo('get messages')).alwaysReturn(messages);
      mockView.when(mock.callsTo('consistentScrollingDuringMutation', anything))
          .alwaysCall((x) => x());

      var controller = new LogViewerController(mockView);
      // Now send a few log messages...
      var logger = new Logger(logName);
      logger.info('Tracer Tong is here');
      logger.info('Paul Denton is here');
      logger.info('Tracer Tong has left');
      logger.severe('Kill switch activated');
      controller.addFilter(new Filter.parse('is here'));
      controller.addFilter('Tong');
      // Only one left.
      expect(mockView.messages.length, equals(1));
      expect(mockView.messages[0].message, equals('Tracer Tong is here'));

      controller.killFilter(controller.filters[1].id);
      // Should be showing the first two messages.
      expect(mockView.messages.length, equals(2));
      expect(mockView.messages[0].message, equals('Tracer Tong is here'));
      expect(mockView.messages[1].message, equals('Paul Denton is here'));
    });
  });
}

LogRecord makeLogRecord({String message: 'message', Level level: Level.FINE, String logger: 'logger'}) {
  return new LogRecord(level, message, logger);
}
