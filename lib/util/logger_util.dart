import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class LoggerUtil {
  static late Logger logger;
  static late File logFile;
  static Future<void> init() async {
    final logPath =
        '${(await getApplicationDocumentsDirectory()).path}/log.txt';
    logFile = File(logPath);
    logger = Logger(
      filter: _AcceptAllFilter(),
      output: MultiOutput([ConsoleOutput(), _FileOutput(logFile)]),
    );
  }

  static Future<String> getLog() async {
    try {
      return logFile.readAsString();
    } catch (e) {
      return "";
    }
  }

  static Future<void> clearLog() async {
    try {
      await logFile.delete();
    } catch (e) {
      return;
    }
  }
}

class _AcceptAllFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

class _FileOutput extends LogOutput {
  late final File _logFile;
  _FileOutput(this._logFile);
  @override
  void output(OutputEvent event) {
    if (!_logFile.existsSync()) {
      _logFile.createSync(recursive: true);
    }
    _logFile.writeAsStringSync(
      '${event.lines.join('\r\n')}\r\n',
      mode: FileMode.append,
    );
  }
}
