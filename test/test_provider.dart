library test_provider;

import 'dart:async';
import 'package:idb_shim/idb_client.dart';
import 'package:tekartik_idb_provider/provider.dart';

int DB_VERSION = 1;
String DB_NAME = 'tekartik_app.test.app_provider';

String ITEMS_STORE = "items";
String NAME_INDEX = "name";
String NAME_FIELD = "name";


class TestProvider extends Provider {
  TestProvider(IdbFactory idbFactory) {
    init(idbFactory, DB_NAME, DB_VERSION);
  }
  void onUpdateDatabase(VersionChangeEvent e) {
    if (e.oldVersion < DB_VERSION) {
      // delete stuff
    }
    var objectStore = database.createObjectStore(ITEMS_STORE, autoIncrement: true);
    Index index = objectStore.createIndex(NAME_INDEX, NAME_FIELD, unique: false);
  }

  Future delete() {
    return idbFactory.deleteDatabase(DB_NAME);
  }


  Future count() {
    var trans = new ProviderStoreTransaction(this, ITEMS_STORE);
    return trans.count().then((int count) {
      return trans.completed.then((_) {
        return count;
      });
    });

  }

  Future<List<String>> getNames({int limit, int offset}) {
    var trans = new ProviderStoreTransaction(this, ITEMS_STORE);
    List<String> names = [];
    return trans.openCursor(limit: limit, offset: offset).listen((CursorWithValue cwv) {
      names.add((cwv.value as Map)[NAME_FIELD]);

    }).asFuture().then((_) {
      return names;
    });
  }

  Future<List<String>> getOrderedNames({int limit, int offset}) {
    var trans = new ProviderIndexTransaction(this, ITEMS_STORE, NAME_INDEX);

    List<String> names = [];
    return trans.openCursor(limit: limit, offset: offset).listen((CursorWithValue cwv) {
      names.add((cwv.value as Map)[NAME_FIELD]);

    }).asFuture().then((_) {
      return trans.completed;
    }).then((_) {
      return names;
    });
  }

  Future<int> putName(String name) {
    var trans = new ProviderStoreTransaction(this, ITEMS_STORE, true);

    Map data = {};
    data[NAME_FIELD] = name;

    return trans.add(data).then((int key) {
      return trans.completed.then((_) {
        return key;
      });
    });

  }

  // null if not found
  Future<String> getName(int key) {
    var trans = new ProviderStoreTransaction(this, ITEMS_STORE);

    return trans.get(key).then((Map data) {
      return trans.completed.then((_) {
        if (data == null) {
          return null;
        }
        return data[NAME_FIELD];
      });
    });

  }

  Future<int> get(int key) {
    var trans = new ProviderStoreTransaction(this, ITEMS_STORE);
    return trans.store.get(key).then((int key) {
      return trans.completed.then((_) {
        return key;
      });
    });

  }

}
