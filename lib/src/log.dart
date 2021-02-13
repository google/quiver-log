// Copyright 2019 Google Inc. All Rights Reserved.

//
// Licensed under the Apache License, Version 2.0 (the 'License');
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

part of quiver.log;

/// Appenders define output vectors for logging messages. An appender can be
/// used with multiple [Logger]s, but can use only a single [Formatter]. This
/// class is designed as base class for other Appenders to extend.
///
/// Generally an Appender recieves a log message from the attached logger
/// streams, runs it through the formatter and then outputs it.
abstract class Appender {
  final List<StreamSubscription> _subscriptions = [];
  final Formatter formatter;

  Appender(this.formatter);

  /// Attaches a logger to this appender
  void attachLogger(Logger logger) {
    _subscriptions.add(logger.onRecord.listen(_append));
  }

  void _append(LogRecord r) {
    try {
      append(r, formatter);
    } catch (error, stack) {
      try {
        // Attempt to output one more time with a safe formatter and
        // information about the error.
        var errorRecord = LogRecord(
            Level.SHOUT,
            'Appender failed to append log message. Original message: $r',
            '$_ErrorDiagnosticFormatter',
            error,
            stack);
        append(errorRecord, _diagnosticFormatter);
      } catch (e, s) {
        // Even the diagnostic formatter failed, now it's time to give up.
        // In dev we will attempt to crash the app as this must be a
        // programming error.
        assert(
            false,
            'Appender failed to append log message: error: $e\nstack '
            'trace: $s');
      }
    }
  }

  /// Each appender should implement this method to perform custom log output.
  void append(LogRecord record, Formatter formatter);

  /// Terminate this Appender and cancel all logging subscriptions.
  void stop() => _subscriptions.forEach((s) => s.cancel());
}

/// Interface defining log formatter.
abstract class Formatter {
  /// Returns a formatted string message based on [LogRecord].
  String call(LogRecord record);
}

/// Prints the contents of a [LogRecord] in key:value format.
///
/// This formatter is used as a fallback in situations where the configured
/// formatter throws an exception or error. All of the details of the log
/// record are dumped in a key:value format.
class _ErrorDiagnosticFormatter implements Formatter {
  const _ErrorDiagnosticFormatter();

  @override
  String call(LogRecord record) {
    var message = 'time: ${record.time} '
        'level: ${record.level} '
        'loggerName: ${record.loggerName} '
        'message: ${record.message}';
    if (record.error != null) {
      message = '$message\nerror: ${record.error}';
    }
    if (record.stackTrace != null) {
      message = '$message\nstackTrace: ${record.stackTrace}';
    }
    return message;
  }
}

const _diagnosticFormatter = _ErrorDiagnosticFormatter();

/// Formats log messages using a simple pattern
class BasicLogFormatter implements Formatter {
  static final _dateFormat = DateFormat('yyMMdd HH:mm:ss.S');

  const BasicLogFormatter();

  /// Formats a [LogRecord] using the following pattern:
  ///
  /// MMyy HH:MM:ss.S level sequence loggerName message
  @override
  String call(LogRecord record) {
    var message = '${_dateFormat.format(record.time)} '
        '${record.level} '
        '${record.sequenceNumber} '
        '${record.loggerName} '
        '${record.message}';
    if (record.error != null) {
      message = '$message, error: ${record.error}';
    }
    if (record.stackTrace != null) {
      message = '$message, stackTrace: ${record.stackTrace}';
    }
    return message;
  }
}

/// Default instance of the BasicLogFormatter
const basicLogFormatter = BasicLogFormatter();

/// Appends string messages to the console using print function
class PrintAppender extends Appender {
  /// Returns a new ConsoleAppender with the given [Formatter<String>]
  PrintAppender(Formatter formatter) : super(formatter);

  @override
  void append(LogRecord record, Formatter formatter) {
    print(formatter.call(record));
  }
}

/// Appends string messages to the messages list. Note that this logger does not
/// ever truncate so only use for diagnostics or short lived applications.
class InMemoryListAppender extends Appender {
  final List<String> messages = [];

  /// Returns a new InMemoryListAppender with the given [Formatter]
  InMemoryListAppender(Formatter formatter) : super(formatter);

  @override
  void append(LogRecord record, Formatter formatter) {
    messages.add(formatter.call(record));
  }
}
