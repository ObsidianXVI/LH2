/// Core operation framework for LH2.
///
/// All business logic and data mutations are encapsulated as operations.
/// Operation IDs follow the format: `api.<area>.<action>`
library;

import 'dart:convert';

import 'telemetry.dart';

/// Error model for LH2 operations.
///
/// Captures all relevant error context including operation ID, error code,
/// human-readable message, payload data, code location, and whether the error
/// is fatal (should throw) or recoverable.
class LH2OpError implements Exception {
  /// The operation ID (format: `api.<area>.<action>`).
  final String operationId;

  /// Standardized error code for programmatic handling.
  final String errorCode;

  /// Human-readable error message.
  final String message;

  /// Additional contextual data (JSON-encodable).
  final Map<String, Object?> payload;

  /// Code location where error originated (e.g., "lib/domain/operations/workspace.dart:WorkspaceLoadOp.run").
  final String? location;

  /// Original cause exception, if any.
  final Object? cause;

  /// Whether this error is fatal and should propagate via throw.
  final bool isFatal;

  const LH2OpError({
    required this.operationId,
    required this.errorCode,
    required this.message,
    this.payload = const {},
    this.location,
    this.cause,
    required this.isFatal,
  });

  /// Creates a copy with modified fields.
  LH2OpError copyWith({
    String? operationId,
    String? errorCode,
    String? message,
    Map<String, Object?>? payload,
    String? location,
    Object? cause,
    bool? isFatal,
  }) {
    return LH2OpError(
      operationId: operationId ?? this.operationId,
      errorCode: errorCode ?? this.errorCode,
      message: message ?? this.message,
      payload: payload ?? this.payload,
      location: location ?? this.location,
      cause: cause ?? this.cause,
      isFatal: isFatal ?? this.isFatal,
    );
  }

  /// Serializes to JSON for telemetry logging.
  Map<String, Object?> toJson() => {
        'operationId': operationId,
        'errorCode': errorCode,
        'message': message,
        'payload': payload,
        'location': location,
        'isFatal': isFatal,
        if (cause != null) 'cause': cause.toString(),
      };

  @override
  String toString() => 'LH2OpError(${jsonEncode(toJson())})';
}

/// Standard result type for LH2 operations.
///
/// Contains either a successful value or an error. Use `ok` to check success.
class LH2OpResult<T> {
  /// The successful result value (null if error).
  final T? value;

  /// The error (null if success).
  final LH2OpError? error;

  const LH2OpResult._(this.value, this.error);

  /// Creates a successful result with the given value.
  const LH2OpResult.ok(T value) : this._(value, null);

  /// Creates an error result with the given error.
  const LH2OpResult.error(LH2OpError error) : this._(null, error);

  /// Whether this result represents success (no error).
  bool get ok => error == null;

  /// Returns the value or throws the error if present.
  T getOrThrow() {
    final err = error;
    if (err != null) {
      throw err;
    }
    return value as T;
  }

  /// Maps a successful value to a new type, or propagates errors.
  LH2OpResult<R> map<R>(R Function(T) transform) {
    if (error != null) {
      return LH2OpResult<R>.error(error!);
    }
    return LH2OpResult<R>.ok(transform(value as T));
  }

  @override
  String toString() =>
      ok ? 'LH2OpResult.ok($value)' : 'LH2OpResult.error($error)';
}

/// Base class for all LH2 operations.
///
/// Operations encapsulate business logic with typed input/output,
/// standardized error handling, and telemetry integration.
abstract class LH2Operation<In, Out> {
  /// Unique operation identifier (format: `api.<area>.<action>`).
  String get operationId;

  /// Executes the operation with the given input.
  ///
  /// Returns an `LH2OpResult` containing either the output value
  /// or an `LH2OpError` with full context.
  /// 
  /// Errors are automatically logged to telemetry.
  Future<LH2OpResult<Out>> run(In input) async {
    final result = await execute(input);
    
    // Log any errors to telemetry
    final error = result.error;
    if (error != null) {
      Telemetry.error(error);
    }
    
    return result;
  }

  /// The actual operation implementation.
  /// 
  /// Subclasses must implement this method instead of [run].
  /// The [run] method wraps this to add telemetry logging.
  Future<LH2OpResult<Out>> execute(In input);

  /// Captures the current code location from stack trace.
  /// 
  /// Uses [captureLocation] helper for consistent formatting.
  String? _captureLocation() {
    try {
      throw StackTrace.current;
    } catch (_, stackTrace) {
      // Use the shared captureLocation helper
      return captureLocation(stackTrace, maxFrames: 8);
    }
  }

  /// Creates a standardized error with location capture.
  LH2OpError createError({
    required String errorCode,
    required String message,
    Map<String, Object?> payload = const {},
    Object? cause,
    required bool isFatal,
  }) {
    return LH2OpError(
      operationId: operationId,
      errorCode: errorCode,
      message: message,
      payload: payload,
      location: _captureLocation(),
      cause: cause,
      isFatal: isFatal,
    );
  }
}

/// Executes an operation and returns the result, throwing if fatal error.
///
/// This helper provides the "throw vs recover" pattern:
/// - Non-fatal errors are returned in the result for caller handling
/// - Fatal errors are thrown immediately to halt execution
///
/// Usage:
/// ```dart
/// final workspace = await runOrThrow(
///   ref.read(workspaceLoadOpProvider),
///   WorkspaceLoadInput(workspaceId: 'ws-123'),
/// );
/// ```
Future<T> runOrThrow<T>(LH2Operation<dynamic, T> op, dynamic input) async {
  final result = await op.run(input);

  final error = result.error;
  if (error != null && error.isFatal) {
    throw error;
  }

  return result.getOrThrow();
}

/// Standard error codes used across operations.
class LH2ErrorCodes {
  LH2ErrorCodes._();

  // Validation errors
  static const String invalidInput = 'INVALID_INPUT';
  static const String notFound = 'NOT_FOUND';
  static const String alreadyExists = 'ALREADY_EXISTS';
  static const String unauthorized = 'UNAUTHORIZED';

  // Data errors
  static const String databaseError = 'DATABASE_ERROR';
  static const String serializationError = 'SERIALIZATION_ERROR';
  static const String schemaVersionUnsupported = 'SCHEMA_VERSION_UNSUPPORTED';

  // Network errors
  static const String networkError = 'NETWORK_ERROR';
  static const String timeout = 'TIMEOUT';

  // Business logic errors
  static const String operationFailed = 'OPERATION_FAILED';
  static const String preconditionFailed = 'PRECONDITION_FAILED';
}
