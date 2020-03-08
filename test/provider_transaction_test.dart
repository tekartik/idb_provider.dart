library tekartik_app_transaction_test;

import 'package:idb_shim/idb_client.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_idb_provider/provider.dart';

import 'test_common.dart';

void main() {
  testMain(idbMemoryContext);
}

void testMain(TestContext context) {
  var idbFactory = context.factory;
  //devWarning;
  // TODO Add store transaction test
  group('transaction', () {
    //String providerName = 'test';
    var storeName = 'store';
    var indexName = 'index';
    var indexKey = 'my_key';

    DynamicProvider provider;
    ProviderTransaction transaction;

    Future _setUp() {
      provider = DynamicProvider(idbFactory, ProviderDbMeta(context.dbName));
      return provider.delete().then((_) {
        var indexMeta = ProviderIndexMeta(indexName, indexKey);
        provider.addStore(ProviderStoreMeta(storeName,
            indecies: [indexMeta], autoIncrement: true));
        return provider.ready;
      });
    }

    tearDown(() async {
      await transaction?.completed;
      provider.close();
    });

    test('store_cursor', () async {
      await _setUp();
      var storeTxn = provider.storeTransaction(storeName, true);
      // put one with a key one without
      unawaited(storeTxn.put({'value': 'value1'}));
      unawaited(storeTxn.put({'value': 'value2'}));
      await storeTxn.completed;

      var txn = provider.storeTransaction(storeName, false);
      var data = <Map>[];
      //List<String> keyData = [];
      txn.openCursor().listen((CursorWithValue cwv) {
        data.add(cwv.value as Map);
      });

      // listed last
      await txn.completed;
      expect(data, [
        {'value': 'value1'},
        {'value': 'value2'}
      ]);
    });

    test('store_index', () async {
      await _setUp();
      var storeTxn = provider.storeTransaction(storeName, true);
      // put one with a key one without
      unawaited(storeTxn.put({'value': 'value1'}));
      unawaited(storeTxn.put({'my_key': 2, 'value': 'value2'}));
      unawaited(storeTxn.put({'value': 'value3'}));
      unawaited(storeTxn.put({'my_key': 1, 'value': 'value4'}));
      await storeTxn.completed;

      var txn = provider.indexTransaction(storeName, indexName);
      var data = <Map>[];
      var keyData = <int>[];
      txn.openCursor().listen((CursorWithValue cwv) {
        data.add(cwv.value as Map);
      });
      txn.openKeyCursor().listen((Cursor c) {
        keyData.add(c.key as int);
      });

      // listed last
      await txn.completed;
      expect(data.length, 2);
      expect(data[0], {'my_key': 1, 'value': 'value4'});
      expect(data[1], {'my_key': 2, 'value': 'value2'});
      expect(keyData.length, 2);
      expect(keyData[0], 1);
      expect(keyData[1], 2);
    });
  });
}
//class TestApp extends ConsoleApp {
//
//}
