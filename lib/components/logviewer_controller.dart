library logviewer.controller;

import 'dart:async';
import 'package:logging/logging.dart';

class Filter {
  static int _nextId = 1;
  final int id;
  bool _invert = false;
  String _loggerName;
  String _messageExact;
  RegExp _messageRegex;
  // In the case of an exact or regex matcher, the user entered a possibly
  // escaped string. For instance, _messageRegex = new RegExp("\t\n"), which
  // means the user entered /\t\n/. _rawMatcher contains that text, with a
  // literal backslash and so forth.
  String _rawMatcher;
  Level _minLevel;
  Level _exactLevel;
  String _fileName;
  DateTime _minDate;
  DateTime _maxDate;

  Filter() : id = _nextId++ {
  }

  Filter.parse(String text) : id = _nextId++ {
    var parts = text.split(':');
    var name = parts[0];
    if (parts.length == 1) {
      _messageExact = _rawMatcher = text;
      return;
    }
    var rest = parts.skip(1).join(':');
    if (name[0] == '-') {
      _invert = true;
    }
    switch (name) {
      case 'level':
        var levelName = rest.toLowerCase();
        for (var level in Level.LEVELS) {
          if (level.name.toLowerCase() == levelName) {
            _exactLevel = level;
            return;
          }
        }
        break;
      case 'minlevel':
        var levelName = rest.toLowerCase();
        for (var level in Level.LEVELS) {
          if (level.name.toLowerCase() == levelName) {
            _minLevel = level;
            return;
          }
        }
        break;
      case 'file':
        _fileName = rest.toLowerCase();
        if (!_fileName.endsWith(".dart")) {
          _fileName = "$_fileName.dart";
        }
        return;
      case 'logger':
        _loggerName = rest.toLowerCase();
        return;
      case 'mindate':
        _minDate = DateTime.parse(rest.toUpperCase());
        return;
      case 'maxdate':
        _maxDate = DateTime.parse(rest.toUpperCase());
        return;
      default:
        break;
    }
    _messageExact = _rawMatcher = text;
  }
  
  static List<Filter> parseAll(String str) {
    var filters = [];
    int i = 0;
    
    /// Returns [escaped string, non-escaped string]
    List<String> parseDelimited() {
      var delimiter = str[i];
      var escaped = '';
      var start = i + 1;
      while (i < str.length - 1) {
        i++;
        if (str[i] == '\\' && i < str.length - 1) {
          if (str[i + 1] == delimiter) {
            escaped += delimiter;
            i++;
            continue;
          }
          switch (str[i + 1]) {
            // See http://code.google.com/p/dart/issues/detail?id=9190 -- this
            // would greatly benefit from a String.unescape() method.
            // Specifically, this doesn't support unicode or hex literals.
            case 't':
              escaped += '\t';
              break;
            case 'n':
              escaped += '\n';
              break;
            case 'r':
              escaped += '\r';
              break;
            default:
              escaped += '\\${str[i]}';
              break;
          }
          i++;
        } else if (str[i] == delimiter) {
          i++;  // to advance past the quoted regex
          break;
        } else {
          escaped += str[i];
        }
      }
      return [escaped, str.substring(start, i - 1)];
    }
    while (i < str.length) {
      bool invert = false;
      if (str[i] == '-') {
        i++;
        invert = true;
      }
      
      if (str[i] == '/') {
        var pair = parseDelimited();
        var regex = pair[0];
        var raw = pair[1];
        filters.add(new Filter()
          .._messageRegex = new RegExp(regex)
          .._rawMatcher = raw
          .._invert = invert);
        continue;
      }
      
      if (str[i] == '"') {
        var pair = parseDelimited();
        var exact = pair[0];
        var raw = pair[1];
        filters.add(new Filter()
          .._messageExact = exact
          .._rawMatcher = raw
          .._invert = invert);
        continue;
      }

      if (str[i] == " ") {
        i++;
        continue;
      }

      // A bare search term, or a type:value term.
      var nextSpace = str.indexOf(' ', i);
      if (nextSpace < 0) nextSpace = str.length;
      var term = str.substring(i, nextSpace);
      i = nextSpace;
      filters.add(new Filter.parse(term).._invert = invert);
    }
    return filters;
  }

  static const String DART_SUFFIX = ".dart";
  bool match(LogRecord record) {
    bool matches = true;
    if (_messageExact != null && record.message.indexOf(_messageExact) < 0) {
      matches = false;
    }
    if (_loggerName != null) {
      if (hierarchicalLoggingEnabled) {
        // Hierarchical logging has dot-separated hierarchies.
        // So logger ui.calendar.event-highlighter inherits from ui.calendar and ui.
        if (_loggerName != record.loggerName && !(record.loggerName.startsWith(_loggerName + "."))) {
          matches = false;
        }
      } else {
        matches = matches && _loggerName == record.loggerName;
      }
    }
    if (_messageRegex != null) {
      matches = matches && _messageRegex.firstMatch(record.message) != null;
    }
    if (_minLevel != null && record.level < _minLevel) {
      matches = false;
    }
    if (_exactLevel != null && record.level != _exactLevel) {
      matches = false;
    }
    if (_fileName != null) {
      // Dart stacktraces are root -> tip, most recent call last.
      // Each line contains the relevant source file's full path.
      String stacktrace = record.stackTrace.toString();
      if (!_fileName.endsWith(DART_SUFFIX)) {
        _fileName = "$_fileName$DART_SUFFIX";
      }

      // It's easier to tell if the filenames end at the same place than if
      // they begin at the same place.
      var offset = stacktrace.lastIndexOf(DART_SUFFIX) + DART_SUFFIX.length;
      var fileoffset = stacktrace.lastIndexOf(_fileName) + _fileName.length;
      if (offset != fileoffset) {
        matches = false;
      }
    }
    if (_minDate != null) {
      matches = record.time.compareTo(_minDate) >= 0;
    }
    if (_maxDate != null) {
      matches = record.time.compareTo(_maxDate) <= 0;
    }

    if (_invert) {
      return !matches;
    }
    return matches;
  }

  toString() {
    var str = "";
    if (_messageRegex != null) {
      str += "/$_rawMatcher/ ";
    }
    if (_messageExact != null) {
      str += "\"$_rawMatcher\"";
    }
    if (_loggerName != null) {
      str += "logger:$_loggerName ";
    }
    if (_minLevel != null) {
      str += "minlevel:$_minLevel ";
    }
    if (_exactLevel != null) {
      str += "level:$_exactLevel ";
    }
    if (_fileName != null) {
      str += "file:$_fileName ";
    }
    if (_minDate != null) {
      str += "mindate:${_minDate.toIso8601String()} ";
    }
    if (_maxDate != null) {
      str += "maxdate:${_maxDate.toIso8601String()} ";
    }
    str = str.trim();
    if (_invert) {
      return "NOT ($str)";
    }
    return str;
  }
}

class LogViewerController {
  var view;
  List<LogRecord> _logs = [];
  List<Filter> filters = [];
  String _log;
  StreamSubscription<LogRecord> _sub;

  LogViewerController(this.view) {
    logMayHaveChanged();
  }
  
  void logMayHaveChanged() {
    String newLog = view.logName;
    if (_log == newLog) {
      return;
    }
    if (_sub != null) {
      _sub.cancel();
    }
    _sub = new Logger(newLog).onRecord.listen(appendRecord);
    _log = newLog;
  }
  
  void appendRecord(LogRecord logRecord) {
    _logs.add(logRecord);
    for (var filter in filters) {
      if (!filter.match(logRecord)) {
        return;
      }
    }
    view.consistentScrollingDuringMutation(() => view.messages.add(logRecord));
  }

  void killFilter(int filterId) {
    filters.removeWhere((filter) => filter.id == filterId);
    view.showFilters(filters);
    
    // TODO: stay scrolled to roughly the same place.
    view.messages.clear();
    view.messages.addAll(_logs.where((record) => !filters.any((filter) => !filter.match(record))));
  }

  void addFilter(var filter) {
    if (filter is String) {
      for (var parsed in Filter.parseAll(filter)) {
        addFilter(parsed);
      }
      return;
    }
    filters.add(filter);
    view.showFilters(filters);

    // We just added a filter. Remove elements from our list that are not part of that filter.
    view.messages.retainWhere(filter.match);
  }
}
