import 'provider_test.dart' as provider_test;
import 'dynamic_provider_test.dart' as dynamic_provider_test;
import 'provider_meta_test.dart' as provider_meta_test;
import 'provider_transaction_test.dart' as provider_transaction_test;
import 'package:idb_shim/idb_client.dart';
import 'package:idb_shim/idb_client_memory.dart';

void main() {
  testMain(idbMemoryFactory);
}

testMain(IdbFactory idbFactory) {
  provider_test.testMain(idbFactory);
  dynamic_provider_test.testMain(idbFactory);
  provider_meta_test.testMain(idbFactory);
  provider_transaction_test.testMain(idbFactory);
  print('running...');
}
