import 'package:tekartik_test/test_config_browser.dart';
import 'test_runner.dart' as test_runner;
import 'package:idb_shim/idb_browser.dart';

main() {
  useHtmlConfiguration();
  test_runner.testMain(idbBrowserFactory);

}
