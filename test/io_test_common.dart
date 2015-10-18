library tekartik_idb_provider.test.io_test_common;

import 'dart:mirrors';
import 'package:sembast/sembast_io.dart';
import 'package:idb_shim/idb_client_sembast.dart';
import 'package:path/path.dart';
import 'test_common.dart';
export 'test_common.dart';

class IoTestContext extends SembastTestContext {
  IoTestContext() {
    sdbFactory = ioDatabaseFactory;
    factory = new IdbSembastFactory(ioDatabaseFactory, testOutTopPath);
  }
}

IoTestContext idbIoContext = new IoTestContext();

class _TestUtils {
  static final String scriptPath =
      (reflectClass(_TestUtils).owner as LibraryMirror).uri.toFilePath();
}

String get testScriptPath => _TestUtils.scriptPath;
String get testOutTopPath => join(dirname(testScriptPath), "out");
