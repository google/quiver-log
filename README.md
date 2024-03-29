Quiver Log
======

Quiver log is a set of logging utilities that make it easy to configure and
manage Dart's built in logging capabilities.

# Documentation
[API Docs](http://www.dartdocs.org/documentation/quiver_log/latest) are
available.

# The Basics

Dart's built-in logging utilities are fairly low level. This means each time you
start a new project you have to copy/paste a bunch of logging configuration
code to setup output locations and logging formats. Quiver-log provides a set of
higher-level abstractions to make it easier to get logging setup correctly.
Specifically, there are two new concepts: `appender` and `formatter`. Appenders
define output locations like the console, http or even in-memory data structures
that can store logs. Formatters, as the name implies, allow for custom logging
formats.

Here is a simple example that sets up a `InMemoryAppender` with a
`SimpleStringFormatter`:

```
import 'package:logging/logging.dart';
import 'package:quiver_log/log.dart';

class SimpleStringFormatter implements Formatter {
  String call(LogRecord record) => record.message;
}

main() {
  var logger = Logger('quiver.TestLogger');
  var appender = InMemoryListAppender(SimpleStringFormatter());
  appender.attachLogger(logger);
}
```

That's all there is to it!

Quiver-log provides three `Appender`s: `PrintAppender`
which uses Dart's print statement to write to the console, 
`InMemoryListAppender` which writes logs to a simple list (this can be useful for debugging or testing) and a `WebAppender` which will take advantage of web console methods to improve readability in your browser. Additionally, a single `Formatter` called
`BasicLogFormatter` is included and uses a "MMyy HH:mm:ss.S" format. Of course
there is no limit to what kind of appenders you can create.

To create a new kind of `Appender` simply extend `Appender`. To create a new
`Formatter` just implement the `Formatter` abstract class. Take a look at
PrintAppender and BasicLogFormatter for an example.

# Making Changes and Running Tests

All patches must be formatted using dartfmt and submitted with tests. To run the tests use:

dart run test test/all_tests.dart

dart run test -p chrome test/all_web_tests.dart
