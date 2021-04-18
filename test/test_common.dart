library tekartik_idb_provider.test.test_common;

import 'package:dev_test/test.dart';
import 'package:idb_shim/idb_client.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:idb_shim/idb_client_sembast.dart';
import 'package:path/path.dart';
import 'package:sembast/sembast.dart' as sdb;

export 'dart:async';

export 'package:dev_test/test.dart';
export 'package:idb_shim/idb_client_memory.dart';
export 'package:idb_shim/src/common/common_meta.dart';

class TestContext {
  late IdbFactory factory;

  String get dbName => testDescriptions.join('-') + '.db';
}

class SembastTestContext extends TestContext {
  late sdb.DatabaseFactory sdbFactory;

  @override
  IdbFactorySembast get factory => super.factory as IdbFactorySembast;

  @override
  String get dbName => join(joinAll(testDescriptions), 'test.db');
}

TestContext idbMemoryContext = SembastTestContext()..factory = idbFactoryMemory;
