import 'dart:io';
import 'package:logger/logger.dart';

class LoggerUtil {
  static late Logger logger;
  static late File logFile;
  static void init(String logPath) {
    logFile = File(logPath);
    logger = Logger(
      output: MultiOutput([ConsoleOutput(), FileOutput(logFile)]),
    );
  }

  static String getLog() {
    try {
      return logFile.readAsStringSync();
    } catch (e) {
      return "";
    }
  }
}

class FileOutput extends LogOutput {
  late final File _logFile;
  FileOutput(this._logFile);
  @override
  void output(OutputEvent event) {
    if (event.level == Level.error) {
      _logFile.writeAsStringSync(event.lines.join('\n'));
    }
  }
}
