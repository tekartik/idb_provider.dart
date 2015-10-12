@TestOn("browser")
import 'package:test/test.dart';
import 'test_runner.dart' as test_runner;
import 'package:idb_shim/idb_browser.dart';

main() {
  test_runner.testMain(idbBrowserFactory);
}
