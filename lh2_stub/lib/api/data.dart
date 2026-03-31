part of lh2.stub;

abstract class DatabaseInterface<Q, QR> {
  FutureOr<T> getObject<T extends LH2Object>(String id);
  FutureOr<void> updateObject<T extends LH2Object>(
    String id,
    T newObject,
  );
  FutureOr<String> createAndSetObject<T extends LH2Object>(T object);
  FutureOr<void> deleteObject<T extends LH2Object>(String id);
  FutureOr<QR> runQuery(Q query);
}

abstract class StorageInterface {}
