library tekartik_app_transaction_test;

import 'package:idb_shim/idb_client.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:tekartik_idb_provider/provider.dart';

import 'package:dev_test/test.dart';
import 'dart:async';

void main() {
  testMain(idbMemoryFactory);
}

void testMain(IdbFactory idbFactory) {

  //devWarning;
  // TODO Add store transaction test
  group('transaction', () {

    String providerName = "test";
    String storeName = "store";
    String indexName = "index";
    String indexKey = "my_key";

    DynamicProvider provider;
    ProviderTransaction transaction;

    setUp(() {
      provider = new DynamicProvider(idbFactory, new ProviderDbMeta(providerName));
      return provider.delete().then((_) {
        ProviderIndexMeta indexMeta = new ProviderIndexMeta(indexName, indexKey);
        provider.addStore(new ProviderStoreMeta(storeName, indecies: [indexMeta], autoIncrement: true));
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



    solo_test('store_cursor', () async {

      ProviderStoreTransaction storeTxn = provider.storeTransaction(storeName, true);
      // put one with a key one without
      storeTxn.put({"value": "value1"});
      storeTxn.put({"value": "value2"});
      await storeTxn.completed;

      ProviderStoreTransaction txn = provider.storeTransaction(storeName, false);
      List<Map> data = [];
      List<String> keyData = [];
      txn.openCursor().listen((CursorWithValue cwv) {
        data.add(cwv.value);
      });

      // listed last
      await txn.completed;
      expect(data, [{"value": "value1"},{"value": "value2"}]);
    });

    solo_test('store_index', () async {

      ProviderStoreTransaction storeTxn = provider.storeTransaction(storeName, true);
      // put one with a key one without
      storeTxn.put({"value": "value1"});
      storeTxn.put({"my_key": 2, "value": "value2"});
      storeTxn.put({"value": "value3"});
      storeTxn.put({"my_key": 1, "value": "value4"});
      await storeTxn.completed;

      ProviderIndexTransaction txn = provider.indexTransaction(storeName, indexName);
      List<Map> data = [];
      List<String> keyData = [];
      txn.openCursor().listen((CursorWithValue cwv) {
        data.add(cwv.value);
      });
      txn.openKeyCursor().listen((Cursor c) {
        keyData.add(c.key);
      });

      // listed last
      await txn.completed;
      expect(data.length, 4);
      expect(data[2], {"my_key": 1, "value": "value4"});
      expect(data[3], {"my_key": 2, "value": "value2"});
      expect(keyData.length, 4);
      expect(keyData[2], 1);
      expect(keyData[3], 2);
    });


  });

}
//class TestApp extends ConsoleApp {
//
//}
