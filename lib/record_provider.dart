library tekartik_idb_provider.record_provider;

import 'package:tekartik_idb_provider/provider.dart';
import 'package:idb_shim/idb_client.dart' as idb;
import 'dart:async';
import 'package:collection/equality.dart';

abstract class DbField {
  static const String syncVersion = "syncVersion";
  static const String version = "version";

  // local version (incremented)
  static const String dirty = "dirty";
  static const String deleted = "deleted";
  static const String syncId = "syncId";
  static const String kind = "kind";
}

abstract class DbRecordBase {
  get id;
  set id(var id);

  fillDbEntry(Map entry);

  fillFromDbEntry(Map entry);

  Map toDbEntry() {
    Map entry = new Map();
    fillDbEntry(entry);

    return entry;
  }

  set(Map map, String key, value) {
    if (value != null) {
      map[key] = value;
    } else {
      map.remove(key);
    }
  }

  @override toString() {
    Map map = new Map();
    fillDbEntry(map);
    return map.toString();
  }

  @override
  int get hashCode => const MapEquality().hash(toDbEntry());

  @override
  bool operator ==(o) {
    if (o == null) {
      return false;
    }
    return (o.runtimeType == runtimeType) &&
        (const MapEquality().equals(toDbEntry(), o.toDbEntry()));
  }
}

abstract class DbRecord extends DbRecordBase {
  get id;

  set id(var id);

  @override
  int get hashCode => id == null ? 0 : id.hashCode * 17 + super.hashCode;

  @override
  bool operator ==(o) {
    return (super == (o) && id == o.id);
  }
}

abstract class DbSyncedRecord extends DbRecordBase {
  String get kind;

  int _id;

  int get id => _id;

  set id(int id) => _id = id;

  int _version;

  int get version => _version;

  // updated on each modification
  set version(int version) => _version = version;

  String _syncId;
  String _syncVersion;

  String get syncId => _syncId;

  // will match the tag when synced
  String get syncVersion => _syncVersion;

  void setSyncInfo(String syncId, String syncVersion) {
    _syncId = syncId;
    _syncVersion = syncVersion;
  }

  bool _deleted;

  bool get deleted => _deleted == true;

  // true or false
  set deleted(bool deleted) => _deleted = deleted;

  bool _dirty;

  bool get dirty => _dirty == true;

  // true or false
  set dirty(bool dirty) => _dirty = dirty;

  DbSyncedRecord() {
    _version = 0;
  }

  fillFromDbEntry(Map entry) {
    // type = entry[FIELD_TYPE]; already done
    _version = entry[DbField.version];
    _syncId = entry[DbField.syncId];
    _syncVersion = entry[DbField.syncVersion];
    _deleted = entry[DbField.deleted];
    _dirty = entry[DbField.dirty] == 1;
  }

  fillDbEntry(Map entry) {
    entry[DbField.version] = version;
    set(entry, DbField.syncId, syncId);
    set(entry, DbField.syncVersion, syncVersion);
    set(entry, DbField.deleted, deleted ? true : null);
    set(entry, DbField.dirty, dirty ? 1 : null);
    set(entry, DbField.kind, kind);
  }
}

class DbRecordProviderPutEvent extends DbRecordProviderEvent {
  DbRecordBase record;
}

class DbRecordProviderDeleteEvent extends DbRecordProviderEvent {
  var key;
}

// not tested
class DbRecordProviderClearEvent extends DbRecordProviderEvent {}

class DbRecordProviderEvent {
  bool _syncing;

  bool get syncing => _syncing;

  set syncing(bool syncing) => _syncing = syncing == true;
}

// only for writable transaction
abstract class DbRecordProviderTransaction<K>
    extends ProviderStoreTransaction<Map, K> {
  DbRecordBaseProvider _provider;
  factory DbRecordProviderTransaction(
      DbRecordBaseProvider provider, String storeName,
      [bool readWrite = false]) {
    if (readWrite == true) {
      return new DbRecordProviderWriteTransaction(provider, storeName);
    } else {
      return new DbRecordProviderReadTransaction(provider, storeName);
    }
  }

  DbRecordProviderTransaction._fromList(
      this._provider, ProviderTransactionList list, String storeName)
      : super.fromList(list, storeName) {}

  DbRecordProviderTransaction._(DbRecordBaseProvider provider, String storeName,
      [bool readWrite = false])
      : super(provider.provider, storeName, readWrite),
        _provider = provider;
}

class DbRecordProviderReadTransaction extends DbRecordProviderTransaction {
  DbRecordProviderReadTransaction(
      DbRecordBaseProvider provider, String storeName)
      : super._(provider, storeName, false) {}

  DbRecordProviderReadTransaction.fromList(DbRecordBaseProvider _provider,
      ProviderTransactionList list, String storeName)
      : super._fromList(_provider, list, storeName) {}
}

class DbRecordProviderWriteTransaction<T extends DbRecordBase, K>
    extends DbRecordProviderTransaction<K> {
  bool get _hasListener => _provider._hasListener;

  List<DbRecordProviderEvent> changes = [];

  DbRecordProviderWriteTransaction(
      DbRecordBaseProvider provider, String storeName)
      : super._(provider, storeName, true) {}

  DbRecordProviderWriteTransaction.fromList(DbRecordBaseProvider provider,
      ProviderTransactionList list, String storeName)
      : super._fromList(provider, list, storeName) {}

  Future<T> putRecord(T record, {bool syncing}) {
    return super.put(record.toDbEntry(), record.id).then((K key) {
      record.id = key;
      if (_hasListener) {
        changes.add(new DbRecordProviderPutEvent()
          ..record = record
          ..syncing = syncing);
      }
      return record;
    });
  }

  _throwError() async => throw new UnsupportedError(
      "use putRecord, deleteRecord and clearRecords API");

  @deprecated
  @override
  Future<K> add(Map value, [K key]) => _throwError();

  @deprecated
  @override
  Future<K> put(Map value, [K key]) => _throwError();

  @deprecated
  @override
  delete(K key) => _throwError();

  @deprecated
  @override
  Future clear() => _throwError();

  Future deleteRecord(K key, {bool syncing}) {
    return super.delete(key).then((_) {
      if (_hasListener) {
        changes.add(new DbRecordProviderDeleteEvent()
          ..key = key
          ..syncing = syncing);
      }
    });
  }

  Future clearRecords({bool syncing}) {
    return super.clear().then((_) {
      if (_hasListener) {
        changes.add(new DbRecordProviderClearEvent()..syncing = syncing);
      }
    });
  }

  @override
  Future get completed {
    // delayed notification
    return super.completed.then((_) {
      if (_hasListener && changes.isNotEmpty) {
        for (StreamController ctlr in _provider._onChangeCtlrs) {
          ctlr.add(changes);
        }
      }
    });
  }
}

///
/// A record provider is a provider of a given object type
/// in one store
///
abstract class DbRecordBaseProvider<T extends DbRecordBase, K> {
  DynamicProvider provider;

  String get store;

  DbRecordProviderTransaction storeTransaction(bool readWrite) =>
      new DbRecordProviderTransaction(this, store, readWrite);

  Future<T> get(K id) async {
    var txn = provider.storeTransaction(store);
    T record = await txnGet(txn, id);
    await txn.completed;
    return record;
  }

  T fromEntry(Map entry, K id);

  Future<T> txnGet(ProviderStoreTransaction txn, K id) {
    return txn.get(id).then((Map entry) {
      return fromEntry(entry, id);
    });
  }

  // Listener
  final List<StreamController> _onChangeCtlrs = [];

  Stream<List<DbRecordProviderEvent>> get onChange {
    StreamController ctlr = new StreamController(sync: true);
    _onChangeCtlrs.add(ctlr);
    return ctlr.stream;
  }

  void close() {
    for (StreamController ctlr in _onChangeCtlrs) {
      ctlr.close();
    }
  }

  bool get _hasListener => _onChangeCtlrs.isNotEmpty;
}

abstract class DbRecordProvider<T extends DbRecord, K>
    extends DbRecordBaseProvider<T, K> {
  Future<T> put(T record) async {
    var txn = storeTransaction(true);
    record = await txnPut(txn, record);
    await txn.completed;
    return record;
  }

  Future<T> txnPut(DbRecordProviderWriteTransaction txn, T record) =>
      txn.putRecord(record);

  Future delete(K key) async {
    var txn = storeTransaction(true);
    await txnDelete(txn, key);
    await txn.completed;
  }

  Future txnDelete(DbRecordProviderWriteTransaction txn, K key) =>
      txn.deleteRecord(key);
}

abstract class DbSyncedRecordProvider<T extends DbSyncedRecord>
    extends DbRecordBaseProvider<T, int> {
  static const String dirtyIndex = DbField.dirty;

  // must be int for indexing
  static const String syncIdIndex = DbField.syncId;

  ProviderIndexTransaction indexTransaction(String indexName,
          [bool readWrite]) =>
      new ProviderIndexTransaction.fromStoreTransaction(
          storeTransaction(readWrite), indexName);

  Future delete(int id, {bool syncing}) async {
    var txn = storeTransaction(true);
    T list = await txnGet(txn, id);
    if (list != null) {
      // Not synced yet or from sync adapter
      if (list.syncId == null || (syncing == true)) {
        await txnDelete(txn, id);
      } else if (list.deleted != true) {
        list.deleted = true;
        list.dirty = true;
        await txnPut(txn, list);
      }
    }
    await txn.completed;
  }

  Future txnDelete(DbRecordProviderWriteTransaction txn, int id) =>
      txn.deleteRecord(id);

  Future<T> getBySyncId(String syncId) async {
    var txn = indexTransaction(syncIdIndex);
    var id = await txn.getKey(syncId);
    T record;
    if (id != null) {
      record = await txnGet(txn.store, id);
    }
    await txn.completed;
    return record;
  }

  Future<T> txnPut(DbRecordProviderWriteTransaction txn, T record) {
    return txn.putRecord(record);
  }

  Future clear({bool syncing}) async {
    var txn = storeTransaction(true);
    await txn.clearRecords();
    return txn.completed;
  }

  ///
  /// TODO: Put won't change data (which one) if local version has changed
  ///
  Future<T> put(T record, {bool syncing}) async {
    var txn = storeTransaction(true);

    syncing = syncing == true;
    T existingRecord;
    if (record.id != null) {
      existingRecord = await txnGet(txn, record.id);
    }
    if (existingRecord != null) {
      record.version = existingRecord.version + 1;
    } else {
      record.version++;
    }
    /*
      if (list.version != existingList.version) {
        // don't erase data - only update syncInfo if needed
        if (syncing) {
          existingList.setSyncInfo(list.syncId, list.syncVersion);
          await txnPutList(txn, existingList);
        }

          (txn, list);
        }
      } else
    }
    */
    // remove deleted if set
    record.deleted = false;
    // never update sync info
    // dirty for not sync only
    if (syncing == true) {
      record.dirty = false;
    } else {
      // try to retrieve existing sync info
      // list.setSyncInfo(null, null);
      record.dirty = true;
      if (existingRecord != null) {
        record.setSyncInfo(existingRecord.syncId, existingRecord.syncVersion);
      }
    }
    record = await txnPut(txn, record);
    await txn.completed;
    return record;
  }

  ///
  /// during sync, update the sync version
  /// if the local version has changed since, keep the dirty flag
  /// other data is not touched
  /// the dirty flag is only cleared if the local version has not changed
  ///
  Future updateSyncInfo(T record, String syncId, String syncVersion) async {
    var txn = storeTransaction(true);
    DbSyncedRecord existingRecord = await txnGet(txn, record.id);
    if (existingRecord != null) {
      // Check version before changing the dirty flag
      if (record.version == existingRecord.version) {
        existingRecord.dirty = false;
      }
      record = existingRecord;
    }
    record.setSyncInfo(syncId, syncVersion);
    await txnPut(txn, record);
    await txn.completed;
  }

  Future<T> getFirstDirty() async {
    var txn = indexTransaction(dirtyIndex);
    var id = await txn.getKey(1); // 1 is dirty
    DbSyncedRecord record;
    if (id != null) {
      record = await txnGet(txn.store, id);
    }
    await txn.completed;
    return record;
  }

  // Delete all records with synchronisation information
  txnDeleteSyncedRecord(DbRecordProviderWriteTransaction txn) {
    ProviderIndexTransaction index =
        new ProviderIndexTransaction.fromStoreTransaction(txn, syncIdIndex);
    index.openCursor().listen((idb.CursorWithValue cwv) {
      //print("deleting: ${cwv.primaryKey}");
      cwv.delete();
    });
  }
}

// only for writable transaction
abstract class DbRecordProviderTransactionList extends ProviderTransactionList {
  DbRecordProvidersMixin _provider;
  factory DbRecordProviderTransactionList(
      DbRecordProvidersMixin provider, List<String> storeNames,
      [bool readWrite = false]) {
    if (readWrite == true) {
      return new DbRecordProviderWriteTransactionList(provider, storeNames);
    } else {
      return new DbRecordProviderReadTransactionList(provider, storeNames);
    }
  }

  DbRecordProviderTransactionList._(
      DbRecordProvidersMixin provider, List<String> storeNames,
      [bool readWrite = false])
      : super(provider as Provider, storeNames, readWrite),
        _provider = provider;
}

class DbRecordProviderReadTransactionList
    extends DbRecordProviderTransactionList {
  DbRecordProviderReadTransactionList(
      DbRecordProvidersMixin provider, List<String> storeNames)
      : super._(provider, storeNames, false) {}

  DbRecordProviderReadTransaction store(String storeName) {
    return new DbRecordProviderReadTransaction.fromList(
        _provider.getRecordProvider(storeName), this, storeName);
  }
}

class DbRecordProviderWriteTransactionList
    extends DbRecordProviderTransactionList {
  DbRecordProviderWriteTransactionList(
      DbRecordProvidersMixin provider, List<String> storeNames)
      : super._(provider, storeNames, true) {}

  DbRecordProviderTransaction store(String storeName) {
    return new DbRecordProviderWriteTransaction.fromList(
        _provider.getRecordProvider(storeName), this, storeName);
  }
}

abstract class DbRecordProvidersMixin {
  DbRecordProviderTransactionList dbRecordProviderTransactionList(
      List<String> storeNames,
      [bool readWrite = false]) {
    return new DbRecordProviderTransactionList(this, storeNames, readWrite);
  }

  // to implement
  DbRecordBaseProvider getRecordProvider(String storeName);
  Iterable<DbRecordBaseProvider> get recordProviders;
}
