library tekartik_provider;

import 'package:idb_shim/idb_client.dart';
import 'package:tekartik_core/hash_code_utils.dart';
import 'package:collection/collection.dart';
import 'dart:async';

part 'src/provider/provider_transaction.dart';
part 'src/provider/provider_row.dart';
part 'src/provider/provider_meta.dart';

class DynamicProvider extends Provider {
  final List<ProviderStoreMeta> _storeMetas = [];

  void onUpdateDatabase(VersionChangeEvent e) {
    for (var meta in _storeMetas) {
      var store = db.createStore(meta);
      for (var indexMeta in meta.indecies) {
        store.createIndex(indexMeta);
      }
    }
  }

  // to call before ready
  void addStore(ProviderStoreMeta storeMeta) {
    _storeMetas.add(storeMeta);
  }

  // to call before ready
  void addStores(ProviderStoresMeta storesMeta) {
    for (ProviderStoreMeta storeMeta in storesMeta.stores) {
      addStore(storeMeta);
    }
  }

  DynamicProvider.noMeta(IdbFactory idbFactory) {
    _idbFactory = idbFactory;
  }
  DynamicProvider(IdbFactory idbFactory, [ProviderDbMeta meta]) {
    _idbFactory = idbFactory;
    _databaseMeta = meta;
  }
}

abstract class Provider {
  IdbFactory _idbFactory;
  ProviderDb _db;
  ProviderDbMeta _databaseMeta;

  IdbFactory get idbFactory => _idbFactory;
  ProviderDb get db => _db;

  Provider();
  Provider.fromIdb(Database idbDatabase) {
    _setDatabase(idbDatabase);
    _databaseMeta = db.meta;
  }
  //AppProvider(this.idbFactory);
  void init(IdbFactory idbFactory, String dbName, int dbVersion) {
    this._idbFactory = idbFactory;
    _databaseMeta = new ProviderDbMeta(dbName, dbVersion);
  }

  // when everything ready
  _setDatabase(Database db) {
    this._db = new ProviderDb(db);
  }

  // must be set before being ready
  // The provider take ownership of the database
  set db(ProviderDb db) {
    if (db == null) {
      this._db = null;
      _ready = null;
      _readyCompleter = null;
    } else {
      if (_ready != null) {
        throw "ready should not have been called before setting the db";
      } else {
        _readyCompleter = new Completer.sync();
        this._db = db;
        this._idbFactory = db.factory;
        this._databaseMeta = _db.meta;

        _ready = _readyCompleter.future;
        _readyCompleter.complete(this);
      }
    }
  }

  Database get database => db.database;

  // must be set before being ready
  // The provider take ownership of the database
  set database(Database db) {
    if (db == null) {
      this._db = null;
      _ready = null;
      _readyCompleter = null;
    } else {
      if (_ready != null) {
        throw "ready should not have been called before setting the db";
      } else {
        _readyCompleter = new Completer.sync();
        _setDatabase(db);
        this._idbFactory = db.factory;
        this._databaseMeta = _db.meta;

        _ready = _readyCompleter.future;
        _readyCompleter.complete(this);
      }
    }
  }

  // during onUpdateOnly

  close() {
    if (db != null) {
      db.close();
      _db = null;
      _ready = null;
      _readyCompleter = null;
    }
  }

  // delete content
  Future clear() {
    List<String> storeNames =
        db.database.objectStoreNames.toList(growable: false);
    var globalTrans = new ProviderTransactionList(this, storeNames, true);
    List<Future> futures = [];
    for (String storeName in storeNames) {
      var trans = globalTrans.store(storeName);
      futures.add(trans.clear());
    }
    return Future.wait(futures).then((_) {
      return globalTrans.completed;
    });
  }

  // check if database is still opened
  bool get isClosed => (_db == null) && (_ready == null);

  // to implement
  void onUpdateDatabase(VersionChangeEvent e);

  void _onUpdateDatabase(VersionChangeEvent e) {
    _setDatabase(e.database);
    onUpdateDatabase(e);
  }

  Future<ProviderStoresMeta> _storesMeta;
  Future<ProviderStoresMeta> get storesMeta {
    if (_storesMeta == null) {
      _storesMeta = new Future.sync(() {
        List<ProviderStoreMeta> metas = [];

        Iterable<String> storeNames = db.storeNames.toList();
        ProviderTransactionList txn = transactionList(storeNames);
        for (String storeName in storeNames) {
          metas.add(txn.store(storeName).store.meta);
        }
        return txn.completed.then((_) {
          ProviderStoresMeta meta = new ProviderStoresMeta(metas);
          return meta;
        });
      });
    }
    return _storesMeta;
  }

//      Database db = e.database;
//      int version = e.oldVersion;
//
//      if (e.oldVersion == 1) {
//        db.deleteObjectStore(FILES_STORE);
//
//        // dev bug
//        if (db.objectStoreNames.contains(METAS_STORE)) {
//          db.deleteObjectStore(METAS_STORE);
//        }
//      }
//
//      var objectStore = db.createObjectStore(FILES_STORE, autoIncrement: true);
//      Index index = objectStore.createIndex(NAME_INDEX, NAME_FIELD, unique: true);
//
//
//      var metaStrore = db.createObjectStore(METAS_STORE, autoIncrement: true);
//      Index fileIndex = metaStrore.createIndex(FILE_ID_INDEX, FILE_ID_FIELD, unique: true);
//    }

//  Stream<CursorWithValue> Future<List<MetaRow>> metaCursorToList(Stream<CursorWithValue> stream) {
//      List<MetaRow> list = new List();
//      return stream.listen((CursorWithValue cwv) {
//        MetaRow row = new MetaRow.fromCursor(cwv);
//
//        list.add(row);
//        cwv.next();
//      }).asFuture(list);
//    }

  Future delete() {
    close();
    return idbFactory.deleteDatabase(_databaseMeta.name);
  }

  Future<Provider> _ready;
  Completer _readyCompleter;
  bool get isReady => _readyCompleter != null && _readyCompleter.isCompleted;
  Future<Provider> get ready {
    if (_ready == null) {
      _readyCompleter = new Completer.sync();

      _ready = _readyCompleter.future;

      runZoned(() {
        return _idbFactory
            .open(_databaseMeta.name,
                version: _databaseMeta.version,
                onUpgradeNeeded: _onUpdateDatabase)
            .then((Database db) {
          _setDatabase(db);
          _readyCompleter.complete(this);
        });
      }, onError: (e, st) {
        print('open failed');
        print(e);
        print(st);
        _readyCompleter.completeError(e, st);
      });
    }
    return _ready;
  }

// default read-only
  ProviderStoreTransaction storeTransaction(String storeName,
      [bool readWrite = false]) {
    return new ProviderStoreTransaction(this, storeName, readWrite);
  }

  // default read-only
  ProviderIndexTransaction indexTransaction(String storeName, String indexName,
      [bool readWrite = false]) {
    return new ProviderIndexTransaction(this, storeName, indexName, readWrite);
  }

  ProviderTransactionList transactionList(List<String> storeNames,
      [bool readWrite = false]) {
    return new ProviderTransactionList(this, storeNames, readWrite);
  }

  Map toMap() {
    Map map = {};
    if (_db != null) {
      map['db'] = _db._database.name;
    }
    return map;
  }

  String toString() => toMap().toString();
}
