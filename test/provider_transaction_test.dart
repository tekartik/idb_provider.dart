library tekartik_app_transaction_test;

import 'package:idb_shim/idb_client.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:tekartik_idb_provider/provider.dart';

import 'package:tekartik_test/test_utils.dart';
import 'dart:async';

void main() {
  testMain(new IdbMemoryFactory());
}

void testMain(IdbFactory idbFactory) {

  devWarning;
  // TODO Add store transaction test
  group('transaction', () {

    String PROVIDER_NAME = "test";
    String STORE_NAME = "store";
    String INDEX_NAME = "index";
    String INDEX_KEY = "my_key";

    DynamicProvider provider;
    ProviderTransaction transaction;

    setUp(() {
      provider = new DynamicProvider(idbFactory, new ProviderDbMeta(PROVIDER_NAME));
      return provider.delete().then((_) {
        ProviderIndexMeta indexMeta = new ProviderIndexMeta(INDEX_NAME, INDEX_KEY);
        provider.addStore(new ProviderStoreMeta(STORE_NAME, indecies: [indexMeta]));
        return provider.ready;
      });
    });
    tearDown(() {
      return new Future.value(() {
        if (transaction != null) {
          return transaction.completed;
        }
      }).then((_) {
        provider.close();
      });
    });


    test('store_index', () {

//      ProviderStoreTransaction txn = provider.storeTransaction(STORE_NAME);
//      Index index = txn.index(INDEX_NAME);
//
//      // for cleanup
//      transaction = txn;



    });
  });

}
//class TestApp extends ConsoleApp {
//
//}
