/// Telemetry instrumentation for LH2.
///
/// Logs JSON to console for all errors and warnings.
/// Part of the observability layer per FEATURES.md §7.3.1.
library;

import 'dart:convert';
import 'core.dart';

/// Telemetry logger for LH2 operations.
///
/// Logs JSON-formatted messages to console only.
/// Usage:
/// ```dart
/// Telemetry.error(error);  // Log an LH2OpError
/// Telemetry.warn('api.workspace.load', 'Slow operation detected', {...});
/// ```
class Telemetry {
  Telemetry._(); // Private constructor - static utility only

  /// Logs an error with full context.
  ///
  /// Output JSON includes:
  /// - ts: epoch millis
  /// - level: "error"
  /// - message
  /// - operationId
  /// - errorCode
  /// - payload
  /// - location
  static void error(LH2OpError e) {
    // Treat non-fatal errors as warnings.
    // This avoids noisy "error" logs for recoverable states like
    // "workspace not found" on first boot.
    if (!e.isFatal) {
      warn(
        e.operationId,
        e.message,
        payload: {'errorCode': e.errorCode, ...e.payload},
        stackTrace: StackTrace.current,
      );
      return;
    }

    final logEntry = <String, Object?>{
      'ts': DateTime.now().millisecondsSinceEpoch,
      'level': 'error',
      'message': e.message,
      'operationId': e.operationId,
      'errorCode': e.errorCode,
      'payload': e.payload,
      if (e.location != null) 'location': e.location,
      if (e.cause != null) 'cause': e.cause.toString(),
      if (e.isFatal) 'isFatal': true,
    };

    _log(logEntry);
  }

  /// Logs a warning message.
  ///
  /// Output JSON includes:
  /// - ts: epoch millis
  /// - level: "warn"
  /// - message
  /// - operationId
  /// - payload (optional)
  /// - location (optional)
  static void warn(
    String operationId,
    String message, {
    Map<String, Object?> payload = const {},
    StackTrace? stackTrace,
    int maxFrames = 8,
  }) {
    final logEntry = <String, Object?>{
      'ts': DateTime.now().millisecondsSinceEpoch,
      'level': 'warn',
      'message': message,
      'operationId': operationId,
      'payload': payload,
      if (stackTrace != null) 'location': captureLocation(stackTrace, maxFrames: maxFrames),
    };

    _log(logEntry);
  }

  /// Logs a Firestore read latency.
  static void firestoreRead(String collection, String id, int latencyMs) {
    _log({
      'ts': DateTime.now().millisecondsSinceEpoch,
      'level': 'info',
      'type': 'firestore_read',
      'collection': collection,
      'id': id,
      'latencyMs': latencyMs,
    });
  }

  /// Logs a cache hit.
  static void cacheHit(String type, String id) {
    _log({
      'ts': DateTime.now().millisecondsSinceEpoch,
      'level': 'info',
      'type': 'cache_hit',
      'objectType': type,
      'id': id,
    });
  }

  /// Logs a cache miss.
  static void cacheMiss(String type, String id) {
    _log({
      'ts': DateTime.now().millisecondsSinceEpoch,
      'level': 'info',
      'type': 'cache_miss',
      'objectType': type,
      'id': id,
    });
  }

  /// Internal log output - writes JSON to console.
  static void _log(Map<String, Object?> entry) {
    // Use print for console output in Flutter Web
    // ignore: avoid_print
    print(const JsonEncoder.withIndent('').convert(entry));
  }
}

/// Captures a clean code location from a stack trace.
///
/// Parses the stack trace to extract the most relevant frame,
/// filtering out framework and operation infrastructure frames.
///
/// Returns a string like "lib/domain/operations/workspace.dart:WorkspaceLoadOp.run"
/// or the raw frame if parsing fails.
///
/// [maxFrames] controls how many frames to examine (default: 8).
String captureLocation(StackTrace st, {int maxFrames = 8}) {
  final frames = st.toString().split('\n');

  for (var i = 0; i < frames.length && i < maxFrames; i++) {
    final frame = frames[i].trim();

    // Skip empty frames
    if (frame.isEmpty) continue;

    // Skip Dart/Flutter internal frames
    if (_isInternalFrame(frame)) continue;

    // Skip operation framework frames
    if (_isOperationFrameworkFrame(frame)) continue;

    // Parse the frame to extract location
    final location = _parseFrame(frame);
    if (location != null) {
      return location;
    }

    // Return raw frame if we can't parse it
    return frame;
  }

  // Fallback: return first non-empty frame or "unknown"
  final firstFrame = frames.firstWhere(
    (f) => f.trim().isNotEmpty,
    orElse: () => 'unknown',
  );
  return firstFrame.trim();
}

/// Checks if a frame is from Dart/Flutter internals.
bool _isInternalFrame(String frame) {
  final internalPatterns = [
    RegExp(r'dart:'),
    RegExp(r'package:flutter/'),
    RegExp(r'package:riverpod/'),
    RegExp(r'package:async/'),
    RegExp(r'_DefaultZone'),
    RegExp(r'_RootZone'),
    RegExp(r'Future'),
    RegExp(r'Microtask'),
  ];

  return internalPatterns.any((pattern) => pattern.hasMatch(frame));
}

/// Checks if a frame is from the operation framework itself.
bool _isOperationFrameworkFrame(String frame) {
  final frameworkPatterns = [
    RegExp(r'LH2Operation'),
    RegExp(r'LH2OpError'),
    RegExp(r'LH2OpResult'),
    RegExp(r'Telemetry'),
    RegExp(r'captureLocation'),
    RegExp(r'operations/core.dart'),
    RegExp(r'operations/telemetry.dart'),
  ];

  return frameworkPatterns.any((pattern) => pattern.hasMatch(frame));
}

/// Parses a stack frame to extract file and method information.
///
/// Handles various Dart stack trace formats including:
/// - #0      MethodName (file:line:col)
/// - #1      Class.method (package:name/file.dart:line:col)
/// - package:name/file.dart:line:col in method
String? _parseFrame(String frame) {
  // Try to match "#N MethodName (file:line:col)" pattern
  final methodCallPattern = RegExp(r'#\d+\s+([^\s(]+)\s+\(([^)]+)\)');
  final methodMatch = methodCallPattern.firstMatch(frame);

  if (methodMatch != null) {
    final methodName = methodMatch.group(1);
    final location = methodMatch.group(2);

    if (methodName != null && location != null) {
      // Clean up the location - keep only up to the line number
      final locationParts = location.split(':');
      if (locationParts.length >= 2) {
        return '${locationParts[0]}:${locationParts[1]}:$methodName';
      }
      return '$location:$methodName';
    }
  }

  // Try to match "package:name/file.dart:line:col in method" pattern
  final packagePattern = RegExp(r'(package:[^:]+:\d+):\d+\s+in\s+(.+)');
  final packageMatch = packagePattern.firstMatch(frame);

  if (packageMatch != null) {
    final fileLocation = packageMatch.group(1);
    final methodName = packageMatch.group(2);

    if (fileLocation != null && methodName != null) {
      return '$fileLocation:$methodName';
    }
  }

  // Try to match file path patterns directly
  final filePattern = RegExp(r'(lib/[^:]+):\d+:\d+');
  final fileMatch = filePattern.firstMatch(frame);

  if (fileMatch != null) {
    final filePath = fileMatch.group(1);
    // Try to extract method name from the frame
    final methodPattern = RegExp(r'([a-zA-Z_][a-zA-Z0-9_]*(?:\.[a-zA-Z_][a-zA-Z0-9_]*)?)\s*\(');
    final methodMatch = methodPattern.firstMatch(frame);
    final methodName = methodMatch?.group(1);

    if (filePath != null) {
      if (methodName != null) {
        return '$filePath:$methodName';
      }
      return filePath;
    }
  }

  return null;
}