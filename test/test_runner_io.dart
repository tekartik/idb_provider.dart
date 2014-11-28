import 'package:tekartik_test/test_utils_io.dart';
import 'test_runner.dart' as all_common;
import 'package:idb_shim/idb_console.dart';

main() {
  useVMConfiguration();
  all_common.testMain(idbMemoryFactory);
  
}