library quiver.log.logviewer_test;

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:quiver_log/src/logviewer/logviewer_controller.dart';
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

    group('Date matching', () {
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
  });
}

LogRecord makeLogRecord() {
  return new LogRecord(Level.FINE, "message", "logger");
}
