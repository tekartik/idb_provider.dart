import 'package:idb_shim/idb_client_memory.dart';
import 'package:idb_shim/idb_client.dart';
import 'package:dev_test/test.dart';
import 'package:tekartik_idb_provider/record_provider.dart';

IdbFactory idbFactory;

void main() {
  //debugQuickLogging(Level.ALL);
  idbFactory = idbMemoryFactory;
  defineTests();
}

abstract class DbBasicRecordMixin {
  var id;
  String name;

  fillFromDbEntry(Map entry) {
    name = entry["name"];
  }

  fillDbEntry(Map entry) {
    if (name != null) {
      entry['name'] = name;
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
  String id;

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

defineTests() {
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
  });
}
