@TestOn('vm')
import 'package:test/test.dart';

import 'io_test_common.dart';
import 'test_runner.dart' as all_common;

void main() {
  all_common.testMain(idbIoContext);
}
