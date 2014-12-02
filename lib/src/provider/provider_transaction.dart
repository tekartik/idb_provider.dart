part of tekartik_provider;

class ProviderIndexTransaction<K, V> extends Object implements ProviderSourceTransaction<K, V> {

  Future get completed => _store.completed;

  ProviderStoreTransaction _store;
  ProviderStoreTransaction get store => _store;

  ProviderIndexTransaction.fromStoreTransaction(this._store, String indexName) {
    _index = _store.store.index(indexName);
  }
  //ProviderIndex get index => _index;
  //ProviderStore get store => this;
  //ProviderStore get store => super._store;

  @override
  Future<V> get(K key) {
    return _index.index.get(key);
  }

  Future getKey(K key) {
    return _index.index.getKey(key);
  }

  ProviderIndex _index;
  ProviderIndexTransaction(Provider provider, String storeName, String indexName, [bool readWrite = false]) //
  {
    _store = new ProviderStoreTransaction(provider, storeName, readWrite);
    _index = _store.store.index(indexName);
  }

  @override
  Future<int> count() => _index.count();

  @override
  Stream<CursorWithValue> openRawCursor({K key, String direction}) {
    return _index.index.openCursor( //
    key: key, direction: direction);
  }

  Stream<CursorWithValue> openCursor({K key, bool reverse: false, int limit, int offset}) {
    StreamController<CursorWithValue> ctlr = new StreamController(sync: true);

    int count = 0;

    close() {
      if (!ctlr.isClosed) {
        ctlr.close();
      }
    }
    onCursorValue(CursorWithValue cwv) {
      if (offset != null && offset > 0) {
        cwv.advance(offset);
      } else {
        if (limit != null) {
          if (count >= limit) {
            // stop here
            close();
            return;
          }
        }
        ctlr.add(cwv);
        count++;
        cwv.next();
      }
    }

    Stream<CursorWithValue> all;
    String direction = reverse ? IDB_DIRECTION_PREV : null;

    all = openRawCursor( //
    key: key, direction: direction);


    // all.listen(//onCursorValue)
    all.listen(onCursorValue, onDone: () {
      close();
    });

    //}).asFuture() {
    return ctlr.stream;
  }
}

class ProviderStoreTransaction<K, V> extends ProviderStoreTransactionBase<K, V> {
  ProviderStoreTransaction(Provider provider, String storeName, [bool readWrite = false])
      : super(provider, storeName, readWrite) {
  }
  // for creating from list
  ProviderStoreTransaction._() : super._();
}

class WriteTransactionMixin {

}

abstract class ProviderWritableSourceTransactionMixin<K, V> {
  ProviderStore _store;

  Future<K> add(V value, [K key]) {
    return _store.objectStore.add(value, key);
  }

  Future<K> put(V value, [K key]) {
    return _store.objectStore.put(value, key);
  }

  Future<V> get(K key) {
    return _store.objectStore.getObject(key);
  }
}

abstract class ProviderSourceTransaction<K, V> {

  Future<V> get(K key);
  Future<int> count();
  Stream<CursorWithValue> openRawCursor({String direction});
}

abstract class ProviderWritableSourceTransaction<K, V> {

  Future<K> add(V value, [K key]);
  Future<K> put(V value, [K key]);
  Future<V> get(K key);
}

class ProviderStoreTransactionBase<K, V> extends ProviderTransaction with ProviderStoreTransactionMixin {

  ProviderStore _store;

  // not recommended though
  //@deprecated
  ProviderStore get store => _store;

  ProviderStoreTransactionBase._();

  ProviderStoreTransactionBase(Provider provider, String storeName, [bool readWrite = false]) {
    _mode = readWrite ? IDB_MODE_READ_WRITE : IDB_MODE_READ_ONLY;

    try {
      _transaction = provider.db._database.transaction(storeName, _mode);
    } catch (e) {
      // typically db might have been closed so add some debug information
      if (provider.isClosed) {
        print("database has been closed");
      }
      rethrow;
    }
    _store = new ProviderStore(_transaction.objectStore(storeName));
  }


}

abstract class ProviderStoreTransactionMixin<K, V> {
  ProviderStore get store;

  Stream<CursorWithValue> openRawCursor({String direction}) {
    return store.objectStore.openCursor( //
    direction: direction);
  }

  ProviderIndexTransaction index(String name) => new ProviderIndexTransaction.fromStoreTransaction(this, name);

  Future count() => store.count();

  Future get(var key) => store.get(key);

  Future<K> add(V value, [K key]) => store.add(value, key);

  Future<K> put(V value, [K key]) => store.put(value, key);

  delete(K key) => store.delete(key);

  Future clear() => store.clear();

  Stream<CursorWithValue> openCursor({bool reverse: false, int limit, int offset}) {
    StreamController<CursorWithValue> ctlr = new StreamController(sync: true);

    int count = 0;

    close() {
      if (!ctlr.isClosed) {
        ctlr.close();
      }
    }
    onCursorValue(CursorWithValue cwv) {
      if (offset != null && offset > 0) {
        cwv.advance(offset);
      } else {
        if (limit != null) {
          if (count >= limit) {
            // stop here
            close();
            return;
          }
        }
        ctlr.add(cwv);
        count++;
        cwv.next();
      }
    }

    Stream<CursorWithValue> all;
    String direction = reverse ? IDB_DIRECTION_PREV : null;

    all = openRawCursor( //
    direction: direction);


    // all.listen(//onCursorValue)
    all.listen(onCursorValue, onDone: () {
      close();
    });

    //}).asFuture() {
    return ctlr.stream;
  }
}

class _ProviderStoreInTransactionList extends Object with ProviderStoreTransactionMixin {
  final ProviderStore store;
  _ProviderStoreInTransactionList(this.store);
}

class ProviderTransactionList extends ProviderTransaction {

  ProviderTransactionList(Provider provider, Iterable<String> storeNames, [bool readWrite = false]) {
    _mode = readWrite ? IDB_MODE_READ_WRITE : IDB_MODE_READ_ONLY;
    _transaction = provider.db._database.transactionList(storeNames, _mode);
  }
  ProviderStoreTransaction store(String storeName) {

    var store = new ProviderStore(_transaction.objectStore(storeName));
    return new ProviderStoreTransaction._()
        .._mode = this._mode
        .._store = store
        .._transaction = this._transaction;

  }

  ProviderIndexTransaction index(String storeName, String indexName) => store(storeName).index(indexName);

}
class ProviderTransaction {
  Provider _provider;
  Transaction _transaction;
  String _mode;



  Future get completed => _transaction.completed;

//
//  Future<int> add(Map<String, dynamic> data) {
//    if (_store != null) {
//      return _store.add(data);
//    }
//    // should crash then
//    return null;
//  }
//
//  Future<Map<String, dynamic>> getById(int id) {
//    if (_index != null) {
//      return _index.get(id);
//
//    } else if (_store != null) {
//      return _store.getObject(id);
//    }
//    // should crash then
//    return null;
//  }




}
