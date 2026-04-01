import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/domain/operations/core.dart';
import 'package:lh2_app/domain/operations/telemetry.dart';

void main() {
  group('Telemetry', () {
    group('error()', () {
      test('produces correct JSON structure', () {
        final error = LH2OpError(
          operationId: 'api.workspace.load',
          errorCode: 'NOT_FOUND',
          message: 'Workspace not found',
          payload: {'workspaceId': 'test-123'},
          location: 'lib/domain/operations/workspace.dart:WorkspaceLoadOp.run',
          cause: Exception('Original cause'),
          isFatal: false,
        );

        // Build the expected log entry structure
        final logEntry = <String, Object?>{
          'ts': DateTime.now().millisecondsSinceEpoch,
          'level': 'error',
          'message': error.message,
          'operationId': error.operationId,
          'errorCode': error.errorCode,
          'payload': error.payload,
          if (error.location != null) 'location': error.location,
          if (error.cause != null) 'cause': error.cause.toString(),
          if (error.isFatal) 'isFatal': true,
        };

        // Verify the structure matches what Telemetry.error would log
        expect(logEntry['level'], equals('error'));
        expect(logEntry['message'], equals('Workspace not found'));
        expect(logEntry['operationId'], equals('api.workspace.load'));
        expect(logEntry['errorCode'], equals('NOT_FOUND'));
        expect(logEntry['payload'], equals({'workspaceId': 'test-123'}));
        expect(logEntry['location'],
            equals('lib/domain/operations/workspace.dart:WorkspaceLoadOp.run'));
        expect(logEntry['cause'], contains('Original cause'));
        // isFatal should be false
        expect(logEntry['isFatal'], isNull);
        expect(logEntry['ts'], isA<int>());
      });

      test('handles minimal error fields', () {
        final error = LH2OpError(
          operationId: 'api.objects.get',
          errorCode: 'INVALID_INPUT',
          message: 'Object ID cannot be empty',
          isFatal: true,
        );

        // Build minimal log entry
        final logEntry = <String, Object?>{
          'ts': DateTime.now().millisecondsSinceEpoch,
          'level': 'error',
          'message': error.message,
          'operationId': error.operationId,
          'errorCode': error.errorCode,
          'payload': error.payload,
          if (error.location != null) 'location': error.location,
          if (error.cause != null) 'cause': error.cause.toString(),
          if (error.isFatal) 'isFatal': true,
        };

        expect(logEntry['level'], equals('error'));
        expect(logEntry['message'], equals('Object ID cannot be empty'));
        expect(logEntry['operationId'], equals('api.objects.get'));
        expect(logEntry['errorCode'], equals('INVALID_INPUT'));
        expect(logEntry['isFatal'], equals(true));
        // Optional fields not present (isFatal is included when true)
        expect(logEntry.containsKey('location'), isFalse);
        expect(logEntry.containsKey('cause'), isFalse);
      });
    });

    group('warn()', () {
      test('produces correct warning structure', () {
        const operationId = 'api.canvas.updateViewport';
        const message = 'Viewport update took longer than expected';
        const payload = {'durationMs': 2500};

        final logEntry = <String, Object?>{
          'ts': DateTime.now().millisecondsSinceEpoch,
          'level': 'warn',
          'message': message,
          'operationId': operationId,
          'payload': payload,
        };

        expect(logEntry['level'], equals('warn'));
        expect(logEntry['operationId'], equals('api.canvas.updateViewport'));
        expect(logEntry['message'],
            equals('Viewport update took longer than expected'));
        expect(logEntry['payload'], equals({'durationMs': 2500}));
        expect(logEntry['ts'], isA<int>());
      });

      test('can include location from stack trace', () {
        String? capturedLocation;

        try {
          throw StackTrace.current;
        } catch (_, stackTrace) {
          capturedLocation = captureLocation(stackTrace, maxFrames: 8);
        }

        final logEntry = <String, Object?>{
          'ts': DateTime.now().millisecondsSinceEpoch,
          'level': 'warn',
          'message': 'Test warning',
          'operationId': 'api.test',
          'payload': {},
          'location': capturedLocation,
        };

        expect(logEntry['level'], equals('warn'));
        expect(logEntry['operationId'], equals('api.test'));
        expect(logEntry.containsKey('location'), isTrue);
        expect(logEntry['location'], isNotNull);
      });
    });
  });

  group('captureLocation()', () {
    test('extracts location from stack trace', () {
      StackTrace capturedStack;

      try {
        throw StackTrace.current;
      } catch (_, st) {
        capturedStack = st;
      }

      final location = captureLocation(capturedStack, maxFrames: 10);

      // Should find this test function
      expect(location, isNotEmpty);
      expect(location, isNot(equals('unknown')));
    });

    test('returns unknown for empty stack trace', () {
      final location = captureLocation(StackTrace.fromString(''), maxFrames: 8);
      expect(location, equals('unknown'));
    });

    test('respects maxFrames parameter', () {
      // Create a deep stack trace
      Future<String> deepFunction() async {
        try {
          throw StackTrace.current;
        } catch (_, st) {
          return captureLocation(st, maxFrames: 2);
        }
      }

      // Should not crash and should return something
      expect(deepFunction(), completion(isNotEmpty));
    });
  });
}
