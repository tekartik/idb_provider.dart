library tekartik_provider_meta_test;

import 'package:idb_shim/idb_client.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:tekartik_idb_provider/provider.dart';

import 'package:test/test.dart';
import 'dart:async';

void main() {
  testMain(idbMemoryFactory);
}

void testMain(IdbFactory idbFactory) {
  group('meta', () {
    group('raw', () {
      test('index', () {
        ProviderIndexMeta indexMeta = new ProviderIndexMeta("idx", "my_key");
        ProviderIndexMeta indexMeta2 = new ProviderIndexMeta("idx", "my_key");
        expect(indexMeta, indexMeta2);
        expect(
            indexMeta,
            new ProviderIndexMeta("idx", "my_key",
                unique: false, multiEntry: false));
        expect(
            indexMeta,
            isNot(new ProviderIndexMeta("idx", "my_key",
                unique: false, multiEntry: true)));
        expect(
            indexMeta,
            isNot(new ProviderIndexMeta("idx", "my_key",
                unique: true, multiEntry: false)));
        expect(
            indexMeta,
            isNot(new ProviderIndexMeta("idx", "my_key2",
                unique: false, multiEntry: false)));
        expect(
            indexMeta,
            isNot(new ProviderIndexMeta("idx2", "my_key",
                unique: false, multiEntry: false)));
      });

      test('store', () {
        ProviderStoreMeta storeMeta = new ProviderStoreMeta("str");
        expect(storeMeta, new ProviderStoreMeta("str"));
        expect(storeMeta, isNot(new ProviderStoreMeta("str2")));
        expect(storeMeta,
            new ProviderStoreMeta("str", keyPath: null, autoIncrement: false));
        expect(
            storeMeta,
            isNot(new ProviderStoreMeta("str",
                keyPath: null, autoIncrement: true)));
        expect(
            storeMeta,
            isNot(new ProviderStoreMeta("str",
                keyPath: "some", autoIncrement: false)));
        expect(
            storeMeta,
            isNot(new ProviderStoreMeta("str2",
                keyPath: null, autoIncrement: false)));

        storeMeta =
            new ProviderStoreMeta("str", keyPath: "some", autoIncrement: true);
        ProviderStoreMeta storeMeta2 =
            new ProviderStoreMeta("str", keyPath: "some", autoIncrement: true);
        expect(storeMeta, storeMeta2);
        ProviderIndexMeta indexMeta = new ProviderIndexMeta("idx", "my_key");
        ProviderIndexMeta indexMeta2 = new ProviderIndexMeta("idx", "my_key");

        storeMeta = new ProviderStoreMeta("str",
            keyPath: "some", autoIncrement: true, indecies: [indexMeta]);
        expect(storeMeta, isNot(storeMeta2));
        storeMeta = new ProviderStoreMeta("str",
            keyPath: "some",
            autoIncrement: true,
            indecies: [indexMeta, indexMeta2]);
        storeMeta2 = new ProviderStoreMeta("str",
            keyPath: "some",
            autoIncrement: true,
            indecies: [indexMeta2, indexMeta]);
        expect(storeMeta, storeMeta2);
      });

      test('stores', () {
        ProviderStoreMeta storeMeta = new ProviderStoreMeta("str");
        ProviderStoreMeta storeMeta2 = new ProviderStoreMeta("str2");
        ProviderStoresMeta storesMeta = new ProviderStoresMeta([]);
        ProviderStoresMeta storesMeta2 = new ProviderStoresMeta([]);
        expect(storesMeta, storesMeta2);
        storesMeta = new ProviderStoresMeta([storeMeta]);
        expect(storesMeta, isNot(storesMeta2));
        storesMeta2 = new ProviderStoresMeta([storeMeta]);
        expect(storesMeta, storesMeta2);
        storesMeta2 = new ProviderStoresMeta([storeMeta2]);
        expect(storesMeta, isNot(storesMeta2));
        storesMeta = new ProviderStoresMeta([storeMeta, storeMeta2]);
        storesMeta2 = new ProviderStoresMeta([storeMeta2, storeMeta]);
        expect(storesMeta, storesMeta2);
      });
    });
    group('provider', () {
      group('more', () {
        String PROVIDER_NAME = "test";

        DynamicProvider provider;
        ProviderTransaction transaction;

        setUp(() {
          provider = new DynamicProvider(
              idbFactory, new ProviderDbMeta(PROVIDER_NAME));
          return provider.delete();
        });
        tearDown(() async {
          if (transaction != null) {
            await transaction.completed;
          }
          provider.close();
        });

        _roundCircle(ProviderStoresMeta storesMeta) {
          provider.addStores(storesMeta);
          return provider.ready.then((Provider readyProvider) {
            return provider.storesMeta.then((metas) {
              expect(metas, storesMeta);
              expect(metas, isNot(same(storesMeta)));
            });
          });
        }

        test('one_store', () {
          provider.addStore(new ProviderStoreMeta("store"));
          return provider.ready.then((Provider readyProvider) {
            return provider.storesMeta.then((metas) {
              expect(metas,
                  new ProviderStoresMeta([new ProviderStoreMeta("store")]));
            });
          });
        });

        test('one_store round_cirle', () {
          ProviderStoresMeta meta = new ProviderStoresMeta([
            //)
            new ProviderStoreMeta("store")
          ]);
          return _roundCircle(meta);
        });
        test('two_stores', () {
          provider.addStore(new ProviderStoreMeta("store"));
          provider.addStore(new ProviderStoreMeta("store1"));
          return provider.ready.then((Provider readyProvider) {
            return provider.storesMeta.then((metas) {
              expect(
                  metas,
                  new ProviderStoresMeta([
                    new ProviderStoreMeta("store"),
                    new ProviderStoreMeta("store1")
                  ]));
            });
          });
        });

        test('one_index', () {
          ProviderStoresMeta meta = new ProviderStoresMeta([
            //)
            new ProviderStoreMeta("store", indecies: //
                    [new ProviderIndexMeta("idx", "my_key")] //
                )
          ]);
          return _roundCircle(meta);
        });
      });
    });
  });
}
//class TestApp extends ConsoleApp {
//
//}
