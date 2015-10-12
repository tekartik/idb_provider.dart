@TestOn("vm")
import 'package:test/test.dart';
import 'test_runner.dart' as all_common;
import 'package:idb_shim/idb_client_memory.dart';

main() {
  all_common.testMain(idbMemoryFactory);
}
