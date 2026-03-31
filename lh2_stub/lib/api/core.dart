part of lh2.stub;

class LH2API {
  final DatabaseInterface databaseInterface;

  const LH2API({
    required this.databaseInterface,
  });
}

abstract class APIOperation<In, Out> {
  final Out Function(In) operation;
  final String code;

  const APIOperation(
    String code, {
    required this.operation,
  }) : code = 'api.$code';
}

class DataAPIOperation<T extends FutureOr>
    extends APIOperation<DatabaseInterface, T> {
  const DataAPIOperation(
    String code, {
    required super.operation,
  }) : super('data.$code');

  FutureOr<T> run({
    required DatabaseInterface database,
  }) async => await operation(database);
}
