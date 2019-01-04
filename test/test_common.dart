library tekartik_idb_provider.test.test_common;

import 'package:idb_shim/idb_client.dart';
import 'package:idb_shim/idb_client_sembast.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:sembast/sembast.dart' as sdb;
export 'package:idb_shim/idb_client_memory.dart';
export 'package:idb_shim/src/common/common_meta.dart';
import 'package:dev_test/test.dart';
export 'package:dev_test/test.dart';
export 'dart:async';
import 'package:path/path.dart';

class TestContext {
  IdbFactory factory;
  String get dbName => testDescriptions.join('-') + ".db";
}

class SembastTestContext extends TestContext {
  sdb.DatabaseFactory sdbFactory;
  @override
  IdbFactorySembast get factory => super.factory as IdbFactorySembast;
  String get dbName => join(joinAll(testDescriptions), "test.db");
}

TestContext idbMemoryContext = SembastTestContext()..factory = idbMemoryFactory;
