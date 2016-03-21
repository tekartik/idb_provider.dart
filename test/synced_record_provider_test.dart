import 'package:idb_shim/idb_client.dart';
import 'package:dev_test/test.dart';
import 'package:tekartik_idb_provider/record_provider.dart';
import 'package:tekartik_idb_provider/provider.dart';
//import 'package:tekartik_core/dev_utils.dart';
import 'test_common.dart';
//IdbFactory idbFactory;

void main() {
  testMain(idbMemoryContext);
}

const String dbFieldName = "name";

abstract class DbBasicRecordMixin {
  var id;
  String name;

  mixinFillFromDbEntry(Map entry) {
    name = entry[dbFieldName];
  }

  mixinFillDbEntry(Map entry) {
    if (name != null) {
      entry[dbFieldName] = name;
    }
  }
}

class DbAutoRecord extends DbSyncedRecordBase
    with DbBasicRecordMixin, IntIdMixin {
  DbAutoRecord();

  /// create if null
  factory DbAutoRecord.fromDbEntry(Map entry, int id) {
    if (entry == null) {
      return null;
    }
    DbAutoRecord record = new DbAutoRecord()..id = id;
    record.fillFromDbEntry(entry);
    return record;
  }

  fillFromDbEntry(Map entry) {
    super.fillFromDbEntry(entry);
    mixinFillFromDbEntry(entry);
  }

  fillDbEntry(Map entry) {
    super.fillDbEntry(entry);
    mixinFillDbEntry(entry);
  }
}

class DbBasicRecord extends DbSyncedRecordBase
    with DbBasicRecordMixin, StringIdMixin {
  DbBasicRecord();

  /// create if null
  factory DbBasicRecord.fromDbEntry(Map entry, String id) {
    if (entry == null) {
      return null;
    }
    DbBasicRecord record = new DbBasicRecord()..id = id;
    record.fillFromDbEntry(entry);
    return record;
  }

  fillFromDbEntry(Map entry) {
    super.fillFromDbEntry(entry);
    mixinFillFromDbEntry(entry);
  }

  fillDbEntry(Map entry) {
    super.fillDbEntry(entry);
    mixinFillDbEntry(entry);
  }
}

class DbBasicRecordProvider
    extends DbSyncedRecordProvider<DbBasicRecord, String> {
  String get store => DbBasicAppProvider.basicStore;
  DbBasicRecord fromEntry(Map entry, String id) =>
      new DbBasicRecord.fromDbEntry(entry, id);
}

class DbAutoRecordProvider extends DbSyncedRecordProvider<DbAutoRecord, int> {
  String get store => DbBasicAppProvider.autoStore;
  DbAutoRecord fromEntry(Map entry, int id) =>
      new DbAutoRecord.fromDbEntry(entry, id);
}

class DbBasicAppProvider extends DynamicProvider
    with DbRecordProvidersMixin, DbRecordProvidersMapMixin {
  DbBasicRecordProvider basic = new DbBasicRecordProvider();
  DbAutoRecordProvider auto = new DbAutoRecordProvider();

  // version 1 - initial
  static const int dbVersion = 1;

  static const String basicStore = "basic";
  static const String autoStore = "auto";

  static const String defaultDbName =
      'com.tekartik.tekartik_idb_provider.record_test.db';

  //static const String currentIndex = dbFieldCurrent;

  // _dbVersion for testing
  DbBasicAppProvider(IdbFactory idbFactory, String dbName, [int _dbVersion])
      : super.noMeta(idbFactory) {
    if (_dbVersion == null) {
      _dbVersion = dbVersion;
    }
    init(idbFactory, dbName == null ? defaultDbName : dbName, _dbVersion);

    providerMap = {basicStore: basic, autoStore: auto};

    initAll(this);
  }

  @override
  close() {
    closeAll();
    super.close();
  }

  /*
  Future<ProjectProvider> getCurrentProjectProvider() async {
    var txn = project.storeTransaction(true);
    var index = txn.index(currentIndex);
    DbProject dbProject = await index.get(true);
    await txn.completed;
    ProjectProvider projectProvider;
    if (dbProject != null) {
      projectProvider =
      new ProjectProvider(idbFactory, "${appPackage}-${dbProject.id}.db");
    }
    return projectProvider;
  }
  */
  void onUpdateDatabase(VersionChangeEvent e) {
    //devPrint("${e.newVersion}/${e.oldVersion}");
    //Database db = e.database;
    //int version = e.oldVersion;

//    if (e.oldVersion == 1) {
//      // add index
//      // e.transaction
//
//    }
    if (e.oldVersion < 2) {
      //db.deleteObjectStore(ENTRIES_STORE);

      // default erase everything, we don't care we sync
      db.deleteStore(basicStore);
      db.deleteStore(autoStore);

      ProviderIndexMeta nameIndexMeta =
          new ProviderIndexMeta(dbFieldName, dbFieldName);

      ProviderStoreMeta basicStoreMeta =
          new ProviderStoreMeta(basicStore, indecies: [nameIndexMeta]);
      ProviderStoreMeta autoStoreMeta = new ProviderStoreMeta(autoStore,
          autoIncrement: true, indecies: [nameIndexMeta]);

      // ProviderIndex fileIndex = entriesStore.createIndex(indexMeta);
      //devPrint(autoStoreMeta);
      addStores(new ProviderStoresMeta([basicStoreMeta, autoStoreMeta]));

      //providerStore.c
    } else if (e.newVersion > 2 && e.oldVersion < 3) {
      /*
      ObjectStore store = e.transaction.objectStore(basicStore);
      //idbDevPrint(store);
      ProviderStore providerStore = new ProviderStore(store);
      */
    }

    super.onUpdateDatabase(e);
  }
}

void testMain(TestContext context) {
  IdbFactory idbFactory = context.factory;
  group('synced_record_provider', () {
    group('DbRecord', () {
      test('toString', () {
        DbBasicRecord record1 = new DbBasicRecord();

        expect(record1.toString(), "{}");
        record1.id = "key1";
        expect(record1.toString(), "{_id: key1}");
        record1.name = "test";
        expect(record1.toString(), "{name: test, _id: key1}");
      });
      test('equality', () {
        DbBasicRecord record1 = new DbBasicRecord();
        DbBasicRecord record2 = new DbBasicRecord();
        expect(record1.hashCode, record2.hashCode);
        expect(record1, record2);

        record1.id = "key";

        expect(record1.hashCode, isNot(record2.hashCode));
        expect(record1, isNot(record2));

        record2.id = "key";

        expect(record1.hashCode, record2.hashCode);
        expect(record1, record2);

        record1.name = "value";

        expect(record1.hashCode, isNot(record2.hashCode));
        expect(record1, isNot(record2));

        record2.name = "value";

        expect(record1.hashCode, record2.hashCode);
        expect(record1, record2);
      });
    });

    group('access', () {
      test('version', () async {
        DbBasicAppProvider appProvider =
            new DbBasicAppProvider(idbFactory, context.dbName);
        await appProvider.delete();
        await appProvider.ready;
        await appProvider.close();

        appProvider = new DbBasicAppProvider(
            idbFactory, DbBasicAppProvider.defaultDbName, 3);
        await appProvider.ready;
      });

      test('open', () async {
        DbBasicAppProvider appProvider =
            new DbBasicAppProvider(idbFactory, context.dbName);
        await appProvider.delete();
        await appProvider.ready;

        DbRecordProviderReadTransaction<DbBasicRecord, String> readTxn =
            appProvider.basic.readTransaction;
        var txn = readTxn;
        expect(await appProvider.basic.txnGet(readTxn, "_1"), isNull);
        await readTxn.completed;

        DbBasicRecord record = new DbBasicRecord();
        record.name = "test";
        record.id = "_1";

        DbRecordProviderWriteTransaction<DbBasicRecord, String> writeTxn =
            appProvider.basic.writeTransaction;
        txn = writeTxn;

        var key = (await txn.putRecord(record)).id;
        expect(key, "_1");
        expect((await appProvider.basic.txnGet(txn, "_1")).id, "_1");
        await txn.completed;

        txn = appProvider.basic.storeReadTransaction;
        var stream = txn.openCursor(limit: 1);
        await stream.listen((CursorWithValue cwv) {
          DbBasicRecord record =
              new DbBasicRecord.fromDbEntry(cwv.value, cwv.primaryKey);
          expect(record.id, "_1");
        }).asFuture();

        await txn.completed;

        var txnList = appProvider.dbRecordProviderReadTransactionList(
            [DbBasicAppProvider.basicStore]);
        txn = appProvider.basic.txnListReadTransaction(txnList);
        expect((await appProvider.basic.txnGet(txn, "_1")).id, "_1");

        await txnList.completed;

        txnList = appProvider.dbRecordProviderWriteTransactionList(
            [DbBasicAppProvider.basicStore]);
        //txn = appProvider.basic.txnListReadTransaction(txnList);

        txn = appProvider.basic.txnListWriteTransaction(txnList);
        expect((await appProvider.basic.txnGet(txn, "_1")).id, "_1");
        await appProvider.basic.txnClear(txn, syncing: true);
        expect((await appProvider.basic.txnGet(txn, "_1")), isNull);

        await txnList.completed;
        //var txn = basicRecordProvider.store;
        //basicRecordProvider.get()
      });

      test('write', () async {
        DbBasicAppProvider appProvider =
            new DbBasicAppProvider(idbFactory, context.dbName);
        await appProvider.delete();
        await appProvider.ready;

        DbRecordProviderWriteTransaction<DbBasicRecord, String> writeTxn =
            appProvider.basic.writeTransaction;
        var txn = writeTxn;

        DbBasicRecord record = new DbBasicRecord();
        record.name = "test";
        record.id = "_1";

        var key = (await txn.putRecord(record)).id;
        expect(key, "_1");
        expect((await appProvider.basic.txnGet(txn, "_1")).id, "_1");
        await txn.completed;

        txn = appProvider.basic.storeReadTransaction;
        var stream = txn.openCursor(limit: 1);
        await stream.listen((CursorWithValue cwv) {
          DbBasicRecord record =
              new DbBasicRecord.fromDbEntry(cwv.value, cwv.primaryKey);
          expect(record.id, "_1");
        }).asFuture();

        await txn.completed;

        var txnList = appProvider.dbRecordProviderReadTransactionList(
            [DbBasicAppProvider.basicStore]);
        txn = appProvider.basic.txnListReadTransaction(txnList);
        expect((await appProvider.basic.txnGet(txn, "_1")).id, "_1");

        await txnList.completed;

        txnList = appProvider.dbRecordProviderWriteTransactionList(
            [DbBasicAppProvider.basicStore]);
        //txn = appProvider.basic.txnListReadTransaction(txnList);

        txn = appProvider.basic.txnListWriteTransaction(txnList);
        expect((await appProvider.basic.txnGet(txn, "_1")).id, "_1");
        await appProvider.basic.txnClear(txn, syncing: true);
        expect((await appProvider.basic.txnGet(txn, "_1")), isNull);

        await txnList.completed;
        //var txn = basicRecordProvider.store;
        //basicRecordProvider.get()
      });

      test('index', () async {
        DbBasicAppProvider appProvider =
            new DbBasicAppProvider(idbFactory, context.dbName);
        await appProvider.delete();
        await appProvider.ready;

        DbRecordProviderWriteTransaction<DbBasicRecord, String> writeTxn =
            appProvider.basic.writeTransaction;
        var txn = writeTxn;

        DbBasicRecord record = new DbBasicRecord();
        record.name = "test";
        record.id = "_1";

        var key = (await txn.putRecord(record)).id;
        await txn;

        txn = appProvider.basic.readTransaction;
        var index = txn.index(dbFieldName);

        expect((await appProvider.basic.indexGet(index, "test")).id, key);

        await txn;
        //index.
        //expect(key, "_1");
      });
    });

    group('put', () {
      DbBasicRecordProvider basicProvider;
      DbAutoRecordProvider autoProvider;
      DbBasicAppProvider appProvider;

      setUp(() async {
        appProvider = new DbBasicAppProvider(idbFactory, context.dbName);
        await appProvider.delete();
        await appProvider.ready;
        basicProvider = appProvider.basic;
        autoProvider = appProvider.auto;
      });
      tearDown(() {
        appProvider.close();
      });

      test('put', () async {
        DbBasicRecord dbRecord = new DbBasicRecord()..id = "key";
        dbRecord = await basicProvider.put(dbRecord);
        expect(dbRecord.id, "key");
      });

      test('put_auto', () async {
        DbAutoRecord dbRecord = new DbAutoRecord();

        dbRecord = await autoProvider.put(dbRecord);
        expect(dbRecord.id, 1);
        expect(dbRecord.version, 1);
        expect(dbRecord.dirty, true);

        await autoProvider.put(dbRecord);
        expect(dbRecord.id, 1);
        expect(dbRecord.version, 2);
        expect(dbRecord.dirty, true);

        await autoProvider.put(dbRecord, syncing: true);
        expect(dbRecord.id, 1);
        expect(dbRecord.version, 3);
        expect(dbRecord.dirty, false);

        var txn = autoProvider.storeTransaction(true);
        dbRecord = await autoProvider.txnPut(txn, dbRecord);
        await txn;
        expect(dbRecord.id, 1);
        expect(dbRecord.version, 4);
        expect(dbRecord.dirty, true);

        txn = autoProvider.storeTransaction(true);
        dbRecord = await autoProvider.txnPut(txn, dbRecord, syncing: true);
        await txn;
        expect(dbRecord.id, 1);
        expect(dbRecord.version, 5);
        expect(dbRecord.dirty, false);
      });

      test('delete_auto', () async {
        DbAutoRecord dbRecord = new DbAutoRecord();

        // not synced yet
        dbRecord.setSyncInfo("1", "ver");
        dbRecord.deleted = true;
        dbRecord = await autoProvider.put(dbRecord);
        expect(dbRecord.id, 1);
        expect(dbRecord.version, 1);
        expect(dbRecord.dirty, true);
        expect(dbRecord.syncId, isNull);
        expect(dbRecord.syncVersion, isNull);
        expect(dbRecord.deleted, false);

        await autoProvider.delete(dbRecord.id);
        expect(await autoProvider.get(dbRecord.id), isNull);

        // synced
        dbRecord = new DbAutoRecord();
        dbRecord.setSyncInfo("1", "ver");
        dbRecord = await autoProvider.put(dbRecord, syncing: true);
        expect(dbRecord.id, 2);
        expect(dbRecord.version, 1);
        expect(dbRecord.dirty, false);
        expect(dbRecord.syncId, '1');
        expect(dbRecord.syncVersion, 'ver');

        await autoProvider.delete(dbRecord.id);
        dbRecord = await autoProvider.get(dbRecord.id);
        expect(dbRecord.id, 2);
        expect(dbRecord.version, 2);
        expect(dbRecord.dirty, true);
        expect(dbRecord.deleted, true);
        expect(dbRecord.syncId, '1');
        expect(dbRecord.syncVersion, 'ver');

        // put again
        dbRecord = await autoProvider.put(dbRecord, syncing: true);
        expect(dbRecord.id, 2);
        expect(dbRecord.version, 3);
        expect(dbRecord.dirty, false);
        expect(dbRecord.deleted, false);
        expect(dbRecord.syncId, '1');
        expect(dbRecord.syncVersion, 'ver');

        await autoProvider.delete(dbRecord.id, syncing: true);
        expect(await autoProvider.get(dbRecord.id), isNull);

        // put again
        dbRecord = await autoProvider.put(dbRecord, syncing: true);
        expect(dbRecord.id, 2);
        expect(dbRecord.version, 1);
        expect(dbRecord.dirty, false);
        expect(dbRecord.syncId, '1');
        expect(dbRecord.syncVersion, 'ver');

        // delete in transaction
        var txn = autoProvider.storeTransaction(true);
        await autoProvider.txnDelete(txn, dbRecord.id);
        await txn;
        dbRecord = await autoProvider.get(dbRecord.id);
        expect(dbRecord.id, 2);
        expect(dbRecord.version, 2);
        expect(dbRecord.dirty, true);
        expect(dbRecord.deleted, true);
        expect(dbRecord.syncId, '1');
        expect(dbRecord.syncVersion, 'ver');

        txn = autoProvider.storeTransaction(true);
        await autoProvider.txnDelete(txn, dbRecord.id, syncing: true);
        await txn;
        expect(await autoProvider.get(dbRecord.id), isNull);
      });
    });
  });
}
