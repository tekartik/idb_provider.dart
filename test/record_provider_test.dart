import 'package:idb_shim/idb_client.dart';
import 'package:dev_test/test.dart';
import 'package:tekartik_idb_provider/record_provider.dart';
import 'package:tekartik_idb_provider/provider.dart';
import 'test_common.dart';
//IdbFactory idbFactory;

void main() {
  testMain(idbMemoryContext);
}

const String dbFieldName = "name";

abstract class DbBasicRecordMixin {
  dynamic id;
  String name;

  fillFromDbEntry(Map entry) {
    name = entry[dbFieldName] as String;
  }

  fillDbEntry(Map entry) {
    if (name != null) {
      entry[dbFieldName] = name;
    }
  }
}

class DbBasicRecordBase extends DbRecordBase with DbBasicRecordMixin {
  DbBasicRecordBase();

  /// create if null
  factory DbBasicRecordBase.fromDbEntry(Map entry) {
    if (entry == null) {
      return null;
    }
    DbBasicRecordBase record = new DbBasicRecordBase();
    record.fillFromDbEntry(entry);
    return record;
  }
}

class DbBasicRecord extends DbRecord with DbBasicRecordMixin {
  //String id;

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
}

class DbBasicRecordProvider extends DbRecordProvider<DbBasicRecord, String> {
  String get store => DbBasicAppProvider.basicStore;
  DbBasicRecord fromEntry(Map entry, String id) =>
      new DbBasicRecord.fromDbEntry(entry, id);
}

class DbBasicAppProvider extends DynamicProvider
    with DbRecordProvidersMixin, DbRecordProvidersMapMixin {
  DbBasicRecordProvider basic = new DbBasicRecordProvider();

  // version 1 - initial
  static const int dbVersion = 1;

  static const String basicStore = "basic";

  static const String defaultDbName =
      'com.tekartik.tekartik_idb_provider.record_test.db';

  //static const String currentIndex = dbFieldCurrent;

  // _dbVersion for testing
  DbBasicAppProvider(IdbFactory idbFactory, String dbName, [int _dbVersion])
      : super.noMeta(idbFactory) {
    basic.provider = this;
    if (_dbVersion == null) {
      _dbVersion = dbVersion;
    }
    init(idbFactory, dbName == null ? defaultDbName : dbName, _dbVersion);

    providerMap = {
      basicStore: basic,
    };
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

      ProviderIndexMeta nameIndexMeta =
          new ProviderIndexMeta(dbFieldName, dbFieldName);

      ProviderStoreMeta basicStoreMeta = new ProviderStoreMeta(basicStore,
          autoIncrement: true, indecies: [nameIndexMeta]);

      // ProviderIndex fileIndex = entriesStore.createIndex(indexMeta);

      addStores(new ProviderStoresMeta([basicStoreMeta]));

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
  group('record_provider', () {
    group('DbRecordBase', () {
      test('equality', () {
        DbBasicRecordBase record1 = new DbBasicRecordBase();
        DbBasicRecordBase record2 = new DbBasicRecordBase();
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
        dynamic txn = readTxn;
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
        expect(
            (await appProvider.basic
                    .txnGet(txn as DbRecordProviderWriteTransaction, "_1"))
                .id,
            "_1");
        await txn.completed;

        txn = appProvider.basic.storeReadTransaction;
        var stream = txn.openCursor(limit: 1);
        await stream.listen((CursorWithValue cwv) {
          DbBasicRecord record = new DbBasicRecord.fromDbEntry(
              cwv.value as Map, cwv.primaryKey as String);
          expect(record.id, "_1");
        }).asFuture();

        await txn.completed;

        var txnList = appProvider.dbRecordProviderReadTransactionList(
            [DbBasicAppProvider.basicStore]);
        txn = appProvider.basic.txnListReadTransaction(txnList);
        expect(
            (await appProvider.basic
                    .txnGet(txn as DbRecordProviderTransaction, "_1"))
                .id,
            "_1");

        await txnList.completed;

        var writeTxnList = appProvider.dbRecordProviderWriteTransactionList(
            [DbBasicAppProvider.basicStore]);
        //txn = appProvider.basic.txnListReadTransaction(txnList);

        txn = appProvider.basic.txnListWriteTransaction(writeTxnList);
        expect(
            (await appProvider.basic
                    .txnGet(txn as DbRecordProviderTransaction, "_1"))
                .id,
            "_1");
        await appProvider.basic
            .txnClear(txn as DbRecordProviderWriteTransaction);
        expect(
            (await appProvider.basic
                .txnGet(txn as DbRecordProviderTransaction, "_1")),
            isNull);

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
        DbRecordProviderTransaction txn = writeTxn;

        DbBasicRecord record = new DbBasicRecord();
        record.name = "test";
        record.id = "_1";

        var key =
            (await (txn as DbRecordProviderWriteTransaction).putRecord(record))
                .id;
        expect(key, "_1");
        expect((await appProvider.basic.txnGet(txn, "_1")).id, "_1");
        await txn.completed;

        txn = appProvider.basic.storeReadTransaction;
        var stream = txn.openCursor(limit: 1);
        await stream.listen((CursorWithValue cwv) {
          DbBasicRecord record = new DbBasicRecord.fromDbEntry(
              cwv.value as Map, cwv.primaryKey as String);
          expect(record.id, "_1");
        }).asFuture();

        await txn.completed;

        var txnList = appProvider.dbRecordProviderReadTransactionList(
            [DbBasicAppProvider.basicStore]);
        txn = appProvider.basic.txnListReadTransaction(txnList);
        expect((await appProvider.basic.txnGet(txn, "_1")).id, "_1");

        await txnList.completed;

        var writeTxnList = appProvider.dbRecordProviderWriteTransactionList(
            [DbBasicAppProvider.basicStore]);
        //txn = appProvider.basic.txnListReadTransaction(txnList);

        txn = appProvider.basic.txnListWriteTransaction(writeTxnList);
        expect((await appProvider.basic.txnGet(txn, "_1")).id, "_1");
        await appProvider.basic
            .txnClear(txn as DbRecordProviderWriteTransaction);
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
        DbRecordProviderTransaction txn = writeTxn;

        DbBasicRecord record = new DbBasicRecord();
        record.name = "test";
        record.id = "_1";

        var key =
            (await (txn as DbRecordProviderWriteTransaction).putRecord(record))
                .id;
        await txn;

        txn = appProvider.basic.readTransaction;
        var index = txn.index(dbFieldName);

        expect((await appProvider.basic.indexGet(index, "test")).id, key);

        await txn;
        //index.
        //expect(key, "_1");
      });
    });
  });
}
