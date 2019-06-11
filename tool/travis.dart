import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  await shell.run('''

  dartanalyzer --fatal-warnings lib test tool
  dartfmt -w lib test tool --set-exit-if-changed

  pub run test -p vm
  # pub run test -p chrome -j 1
  # pub run build_runner -- -p chrome -j 1
  ''');

  //  pub run test -p chrome -j 1 test/test_runner_browser_test.dart
}
