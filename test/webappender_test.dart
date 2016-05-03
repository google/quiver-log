// Copyright 2013 Google Inc. All Rights Reserved.
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

library quiver.log.webappender_test;

import 'dart:html';

import 'package:logging/logging.dart';
import 'package:quiver_log/log.dart';
import 'package:quiver_log/web.dart';
import "package:test/test.dart";

main() {
  WebAppender webAppender;
  Logger logger;
  FakeConsole fakeConsole;

  group('WebAppender', (){
    setUp(() {
      Logger.root.level = Level.ALL;
      logger = new Logger('testlogger');
      fakeConsole = new FakeConsole();
      webAppender =
          new WebAppender.usingConsole(new NoopFormatter(), fakeConsole);
      webAppender.attachLogger(logger);
    });

    test('Uses correct console methods for config level', (){
      expect(fakeConsole.logMessages.length, equals(0));
      logger.config('config message');
      expect(fakeConsole.logMessages.length, equals(1));
      expect(fakeConsole.logMessages.last, equals('config message'));
    });

    test('Uses correct console methods for finest level', (){
      expect(fakeConsole.logMessages.length, equals(0));
      logger.finest('finest message');
      expect(fakeConsole.logMessages.length, equals(1));
      expect(fakeConsole.logMessages.last, equals('finest message'));
    });

    test('Uses correct console methods for finer level', (){
      expect(fakeConsole.logMessages.length, equals(0));
      logger.finer('finer message');
      expect(fakeConsole.logMessages.length, equals(1));
      expect(fakeConsole.logMessages.last, equals('finer message'));
    });

    test('Uses correct console methods for fine level', (){
      expect(fakeConsole.logMessages.length, equals(0));
      logger.fine('fine message');
      expect(fakeConsole.logMessages.length, equals(1));
      expect(fakeConsole.logMessages.last, equals('fine message'));
    });

    test('Uses correct console methods for info level', (){
      expect(fakeConsole.infoMessages.length, equals(0));
      logger.info('info message');
      expect(fakeConsole.infoMessages.length, equals(1));
      expect(fakeConsole.infoMessages.last, equals('info message'));
    });

    test('Uses correct console methods for warning level', (){
      expect(fakeConsole.warnMessages.length, equals(0));
      logger.warning('warn message');
      expect(fakeConsole.warnMessages.length, equals(1));
      expect(fakeConsole.warnMessages.last, equals('warn message'));
    });

    test('Uses correct console methods for severe level', (){
      expect(fakeConsole.errorMessages.length, equals(0));
      logger.severe('severe message');
      expect(fakeConsole.errorMessages.length, equals(1));
      expect(fakeConsole.errorMessages.last, equals('severe message'));
    });

    test('Uses correct console methods for shout level', (){
      expect(fakeConsole.errorMessages.length, equals(0));
      logger.shout('shout message');
      expect(fakeConsole.errorMessages.length, equals(1));
      expect(fakeConsole.errorMessages.last, equals('shout message'));
    });
  });
}

class NoopFormatter implements FormatterBase<String>{
  const NoopFormatter();
  String call(LogRecord record) => record.message;
}

class FakeConsole implements Console{
  List logMessages = [];
  List infoMessages = [];
  List warnMessages = [];
  List errorMessages = [];

  void log(Object msg) {
    logMessages.add(msg);
  }

  void info(Object msg) {
    infoMessages.add(msg);
  }

  void warn(Object msg) {
    warnMessages.add(msg);
  }

  void error(Object msg) {
    errorMessages.add(msg);
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
