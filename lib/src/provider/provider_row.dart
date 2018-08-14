part of tekartik_provider;

abstract class _BaseRow<K, V> {
  K key;
  V value;

  _BaseRow();
  _BaseRow.from(this.key, this.value);

  @override
  int get hashCode => safeHashCode(key);

  @override
  String toString() => '${key} ${value}';

  @override
  operator ==(other) {
    if (other.runtimeType == runtimeType) {
      return (key == other.key) && (value == other.value);
    }
    return false;
  }
}

abstract class _BaseMapRow<K> extends _BaseRow<K, Map> {
  Map get value => super.value;

  _BaseMapRow.from(K key, Map map) : super.from(key, map);

  @override
  operator ==(Object other) {
    if (other.runtimeType == runtimeType) {
      return const MapEquality().equals(value, (other as _BaseMapRow).value);
    }
    return false;
  }

  operator [](String key) => value[key];
}

class StringMapRow extends _BaseMapRow<String> {
  StringMapRow.from(String key, Map value) : super.from(key, value);
}

class IntMapRow extends _BaseMapRow<int> {
  IntMapRow.from(int key, Map value) : super.from(key, value);
}

abstract class ProviderRowFactory<T extends _BaseRow<K, V>, K, V> {
  T newRow(K key, V value);

  T cursorWithValueRow(CursorWithValue cwv) =>
      newRow(cwv.primaryKey as K, cwv.value as V);
}

class IntMapProviderRowFactory extends ProviderRowFactory<IntMapRow, int, Map> {
  IntMapRow newRow(int key, Map value) {
    return new IntMapRow.from(key, value);
  }
}

final IntMapProviderRowFactory intMapProviderRawFactory =
    new IntMapProviderRowFactory();

class StringMapProviderRowFactory
    extends ProviderRowFactory<StringMapRow, String, Map> {
  StringMapRow newRow(String key, Map value) {
    return new StringMapRow.from(key, value);
  }
}
