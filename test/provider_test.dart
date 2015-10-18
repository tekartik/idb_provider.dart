library tekartik_app_provider_test;

import 'package:idb_shim/idb_client.dart';
import 'package:tekartik_idb_provider/provider.dart';

import 'dart:async';

import 'test_provider.dart';
import 'test_common.dart';

void main() {
  testMain(idbMemoryContext);
}

void testMain(TestContext context) {
  IdbFactory idbFactory = context.factory;

  group('provider', () {
    group('row', () {
      String PROVIDER_NAME = "test";

      DynamicProvider provider;
      ProviderTransaction transaction;

      setUp(() {
        provider =
            new DynamicProvider(idbFactory, new ProviderDbMeta(PROVIDER_NAME));
        return provider.delete();
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

      test('int_map', () {
        provider.addStore(new ProviderStoreMeta("store", autoIncrement: true));
        return provider.ready.then((Provider readyProvider) {
          ProviderStoreTransaction txn =
              provider.storeTransaction("store", true);
          // for cleanup
          transaction = txn;

          return txn.put({"test": 1}).then((key) {
            return txn.get(key).then((value) {
              IntMapRow row = intMapProviderRawFactory.newRow(key, value);

              // Cursor
              txn.openCursor().listen((cwv) {
                IntMapRow cursorRow =
                    intMapProviderRawFactory.cursorWithValueRow(cwv);
                expect(cursorRow, row);
              });
            });
          });
        });
      });
    });
  });
  group('test_provider_open', () {
    test('open', () {
      // open normal
      TestProvider provider = new TestProvider(idbFactory);
      TestProvider provider2 = new TestProvider(idbFactory);
      return provider.delete().then((_) {
        expect(provider.isReady, isFalse);
        Future done = provider.ready.then((readyProvider) {
          expect(readyProvider, provider);
        });
        // not ready yet when opening the db
        expect(provider.isReady, isFalse);
        return done;
      }).then((_) {
        // open using an incoming db
        expect(provider2.isReady, isFalse);
        provider2.db = provider.db;
        expect(provider2.isReady, isTrue);
        Future done = provider2.ready.then((readyProvider2) {
          expect(readyProvider2, provider2);
        });
        return done;
      }).then((_) {
        //provider2.close();
      }).then((_) {
        provider.close();
      });
    });
  });
  group('test_provider', () {
    TestProvider provider = new TestProvider(idbFactory);
    setUp(() {
      return provider.delete().then((_) {
        return provider.ready.then((_) {
          //print(provider.db);
        });
      });
    });
    tearDown(() {
      provider.close();
    });
    test('empty', () {
      return provider.count().then((int count) {
        expect(count, 0);
      });
    });

    test('put/get', () {
      return provider.putName("test").then((int key) {
        expect(key, 1);
        return provider.getName(key).then((String name) {
          expect(name, "test");
        });
      });
    });

    test('get/put', () {
      return provider.getName(1).then((data) {
        expect(data, isNull);
        return provider.putName("test").then((int key) {
          expect(key, 1);
          return provider.getName(key).then((String name) {
            expect(name, "test");
          });
        }).then((_) {
          return provider.count().then((int count) {
            expect(count, 1);
          });
        });
      });
    });

    Future<int> slowCount() {
      ProviderStoreTransaction trans =
          new ProviderStoreTransaction(provider, ITEMS_STORE);
      int count = 0;
      return trans.store.objectStore
          .openCursor(
              //
              direction: IDB_DIRECTION_NEXT,
              autoAdvance: false)
          .listen((CursorWithValue cwv) {
        count++;
      }).asFuture().then((_) {
        return count;
      });
    }
    test('cursor count', () {
      slowCount().then((int count) {
        expect(count, 0);
      });
    });
    test('getNames', () {
      String C1 = "C1";
      String A2 = "A2";
      String B3 = "B3";
      /*
      int c1;
      int a2;
      int b3;
      */
      return provider.getNames().then((var list) {
        expect(list, isEmpty);
      }).then((_) {
        return provider.putName(C1).then((int key) {
          //c1 = key;
        });
      }).then((_) {
        return provider.getNames().then((var list) {
          expect(list, [C1]);
          //expect(list.first, C1);
        });
      }).then((_) {
        return provider.putName(A2).then((int key) {
          //a2 = key;
        });
      }).then((_) {
        return provider.putName(B3).then((int key) {
          //b3 = key;
        });
      }).then((_) {
        return provider.getNames().then((var list) {
          expect(list, [C1, A2, B3]);
          //expect(list.first, C1);
        });
      }).then((_) {
        return provider.getNames(limit: 2).then((var list) {
          expect(list, [C1, A2]);
          //expect(list.first, C1);
        });
      }).then((_) {
        return provider.getOrderedNames().then((var list) {
          expect(list, [A2, B3, C1]);
          //expect(list.first, C1);
        });
      });
    });

    test('put/clear/get', () {
      return provider.putName("test").then((int key) {
        expect(key, 1);
        return provider.clear().then((_) {
          return provider.getName(key).then((String name) {
            expect(name, isNull);
          });
        });
      });
    });
  });
}
//class TestApp extends ConsoleApp {
//
//}
