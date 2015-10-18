import 'provider_test.dart' as provider_test;
import 'dynamic_provider_test.dart' as dynamic_provider_test;
import 'provider_meta_test.dart' as provider_meta_test;
import 'provider_transaction_test.dart' as provider_transaction_test;
import 'test_common.dart';

void main() {
  testMain(idbMemoryContext);
}

testMain(TestContext context) {
  provider_test.testMain(context);
  dynamic_provider_test.testMain(context);
  provider_meta_test.testMain(context);
  provider_transaction_test.testMain(context);
}
