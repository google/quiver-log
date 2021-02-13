part of quiver.log.web;

/// Takes advantage of console logging methods to improve logging filterability.
///  The levels don't map exactly but are close enough.
///
///  Levels are mapped as follows:
///
///  Level.CONFIG => console.log
///  Level.FINEST => console.log
///  Level.FINER => console.log
///  Level.FINE => console.log
///  Level.INFO => console.info
///  Level.WARNING => console.warning
///  Level.SEVERE => console.error
///  Level.SHOUT => console.error
class WebAppender extends Appender {
  final Console _console;
  UnmodifiableMapView<Level, Function>? _levelToOutputFunction;

  WebAppender(Formatter formatter, this._console) : super(formatter) {
    _levelToOutputFunction = UnmodifiableMapView({
      Level.CONFIG: _console.log,
      Level.FINEST: _console.log,
      Level.FINER: _console.log,
      Level.FINE: _console.log,
      Level.INFO: _console.info,
      Level.WARNING: _console.warn,
      Level.SEVERE: _console.error,
      Level.SHOUT: _console.error,
    });
  }

  /// Constructor that creates appender which formats the messages using the
  /// [Formatter] and outputs to the supplied [Console].
  factory WebAppender.usingConsole(
          Formatter formatter, Console console) =>
      WebAppender(formatter, console);

  /// Constructor that creates appender which formats the messages using the
  /// [Formatter] and outputs to Window.console
  factory WebAppender.webConsole(Formatter formatter) =>
      WebAppender(formatter, window.console);

  @override
  void append(LogRecord record, Formatter formatter) {
    _levelToOutputFunction![record.level]!(formatter.call(record));
  }
}
