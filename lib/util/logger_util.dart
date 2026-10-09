import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class LoggerUtil {
  static late Logger logger;
  static late File _logFile;
  static Future<void> init() async {
    try {
      final logPath =
          '${(await getApplicationDocumentsDirectory()).path}/holo/log.txt';

      _logFile = File(logPath);
      logger = Logger(
        filter: _AcceptAllFilter(),
        output: MultiOutput([ConsoleOutput(), _FileOutput(_logFile)]),
      );
    } catch (_) {
      return;
    }
  }

  static Future<String> getLog() async {
    return _logFile.readAsString().catchError((e) => "");
  }

  static Future<void> clearLog() async {
    await _logFile.delete().catchError((_) => _logFile);
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
