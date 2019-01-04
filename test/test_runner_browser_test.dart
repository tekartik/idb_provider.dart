@TestOn("browser")
import 'package:test/test.dart';
import 'test_runner.dart' as test_runner;
import 'package:idb_shim/idb_browser.dart';
import 'test_common.dart';

class BrowserContext extends TestContext {
  BrowserContext() {
    factory = idbBrowserFactory;
  }
}

BrowserContext idbBrowserContext = BrowserContext();
main() {
  test_runner.testMain(idbBrowserContext);
}
