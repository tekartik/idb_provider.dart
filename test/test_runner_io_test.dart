@TestOn("vm")
import 'package:test/test.dart';
import 'test_runner.dart' as all_common;
import 'io_test_common.dart';

main() {
  all_common.testMain(idbIoContext);
}
