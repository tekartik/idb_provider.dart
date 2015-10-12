library tekartik_dynamic_provider_test;

import 'package:idb_shim/idb_client.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:tekartik_idb_provider/provider.dart';

import 'package:test/test.dart';
import 'dart:async';

void main() {
  testMain(idbMemoryFactory);
}

void testMain(IdbFactory idbFactory) {
  group('provider_dynamic', () {
    group('raw', () {
      //DynamicProvider provider;

      test('database', () {
        DynamicProvider provider =
            new DynamicProvider(idbFactory, new ProviderDbMeta("test"));

        return provider
            .delete()
            .then((_) => provider.ready.then((Provider readyProvider) {
                  expect(provider, readyProvider);
                  expect(provider.db.meta.name, "test");
                  expect(provider.db.meta.version, 1);
                  expect(provider.db.storeNames, []);
                  provider.close();
                }));
      });

      test('database name version', () {
        DynamicProvider provider =
            new DynamicProvider(idbFactory, new ProviderDbMeta("test2", 2));

        return provider
            .delete()
            .then((_) => provider.ready.then((Provider readyProvider) {
                  expect(provider, readyProvider);
                  expect(provider.db.meta.name, "test2");
                  expect(provider.db.meta.version, 2);
                  expect(provider.db.storeNames, []);
                  provider.close();
                }));
      });
    });
  });
  group('more', () {
    String PROVIDER_NAME = "test";

    DynamicProvider provider;
    ProviderTransaction transaction;

    setUp(() {
      transaction = null;
      provider =
          new DynamicProvider(idbFactory, new ProviderDbMeta(PROVIDER_NAME));
      return provider.delete();
    });
    tearDown(() async {
      if (transaction != null) {
        await transaction.completed;
      }
      provider.close();
    });

    test('one_store', () {
      provider.addStore(new ProviderStoreMeta("store"));
      return provider.ready.then((Provider readyProvider) {
        ProviderStoreTransaction txn = provider.storeTransaction("store");
        expect(txn.store.meta.name, "store");
        expect(txn.store.meta.keyPath, null);
        expect(txn.store.meta.autoIncrement, false);

        expect(txn.store.meta.indecies, isEmpty);

        // for cleanup
        transaction = txn;
      });
    });

    test('multiple_store', () {
      provider.addStore(
          new ProviderStoreMeta("store", keyPath: "key", autoIncrement: true));
      provider.addStore(new ProviderStoreMeta("store2"));
      return provider.ready.then((Provider readyProvider) {
        ProviderTransactionList txn =
            provider.transactionList(["store", "store2"]);
        ProviderStoreTransactionMixin txn1 = txn.store("store");
        expect(txn1.store.meta.name, "store");
        expect(txn1.store.meta.keyPath, "key");
        expect(txn1.store.meta.autoIncrement, true);

        expect(txn1.store.meta.indecies, isEmpty);

        ProviderStoreTransactionMixin txn2 = txn.store("store2");
        expect(txn2.store.meta.name, "store2");
        expect(txn2.store.meta.keyPath, null);
        expect(txn2.store.meta.autoIncrement, false);

        expect(txn2.store.meta.indecies, isEmpty);

// for cleanup
        transaction = txn;
      });
    });

    test('one_index', () {
      ProviderIndexMeta indexMeta = new ProviderIndexMeta("idx", "my_key");
      provider.addStore(new ProviderStoreMeta("store", indecies: [indexMeta]));
      return provider.ready.then((Provider readyProvider) {
        ProviderStoreTransaction txn = provider.storeTransaction("store");
        expect(txn.store.meta.name, "store");
        expect(txn.store.meta.keyPath, null);
        expect(txn.store.meta.autoIncrement, false);

        expect(txn.store.meta.indecies, [indexMeta]);

        // for cleanup
        transaction = txn;
      });
    });
  });
}
//class TestApp extends ConsoleApp {
//
//}
