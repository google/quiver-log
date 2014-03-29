Quiver Log
======

Quiver log is a set of logging utilities that make it easy to configure and
manage Dart's built in logging capabilities.

# Documentation

http://google.github.io/quiver-log/

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
import 'package:quiver/log.dart';

main() {
  var logger = new Logger('quiver.TestLogger');
  var appender = new InMemoryListAppender(new SimpleStringFormatter());
  appender.attachLogger(logger);
}
```

That's all there is to it!

Quiver-log provides two `Appender`s: `PrintAppender`
which uses Dart's print statement to write to the console and
`InMemoryListAppender` which writes logs to a simple list (this can be useful for debugging or testing). Additionally, a single `Formatter` called
`BasicLogFormatter` is included and uses a "MMyy HH:mm:ss.S" format. Of course
there is no limit to what kind of appenders you can create, we have plans to
add appenders HTTP, WebSocket, DOM, Isolate and SysOut.

To create a new kind of `Appender` simply extends `Appender`. To create a new
`Formatter` just implement the `Formatter` typedef or `FormatterBase` class if
you need to hold state in your formtatter. Take a look at PrintAppender and BasicLogFormatter for an example.
