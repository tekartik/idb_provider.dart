@TestOn('browser')
library tekartik_idb_provider.test.test_runner_browser_test;

import 'package:idb_shim/idb_browser.dart';

import 'test_common.dart';
import 'test_runner.dart' as test_runner;

class BrowserContext extends TestContext {
  BrowserContext() {
    factory = idbFactoryBrowser;
  }
}

BrowserContext idbBrowserContext = BrowserContext();

void main() {
  test_runner.testMain(idbBrowserContext);
}
