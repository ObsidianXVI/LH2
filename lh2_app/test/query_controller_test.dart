import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/domain/notifiers/query_controller.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller.dart';

class MockCanvasController extends CanvasController {
  final Set<String> mockVisibleObjectIds;

  MockCanvasController(this.mockVisibleObjectIds, super.ref);

  @override
  Set<String> get visibleObjectIds => mockVisibleObjectIds;
}

void main() {
  group('QueryAst', () {
    test('parseQuery wraps raw string', () {
      const raw = 'test query';
      final ast = parseQuery(raw);
      
      expect(ast.raw, equals(raw));
    });

    test('parseQuery accepts any text input', () {
      final testCases = [
        '',
        'simple',
        'UPPERCASE',
        'lowercase',
        'Mixed Case',
        'with numbers 123',
        'with special chars !@#\$%',
        'unicode: 你好世界',
        'very long query ${'x' * 1000}',
      ];

      for (final testCase in testCases) {
        final ast = parseQuery(testCase);
        expect(ast.raw, equals(testCase));
      }
    });
  });

  group('LH2ObjectRef', () {
    test('constructor stores id and name', () {
      const ref = LH2ObjectRef('id-1', 'Test Name');
      
      expect(ref.id, equals('id-1'));
      expect(ref.name, equals('Test Name'));
    });

    test('toString returns name', () {
      const ref = LH2ObjectRef('id-1', 'Test Name');
      
      expect(ref.toString(), equals('Test Name'));
    });
  });

  group('evaluateQuery', () {
    test('empty query returns all results', () async {
      final ast = parseQuery('');
      final results = await evaluateQuery(ast);
      
      expect(results.length, equals(10));
    });

    test('case-insensitive substring match works', () async {
      final ast = parseQuery('alpha');
      final results = await evaluateQuery(ast);
      
      expect(results.length, equals(1));
      expect(results.first.name, equals('Alpha Project Group'));
    });

    test('uppercase query matches lowercase name', () async {
      final ast = parseQuery('BETA');
      final results = await evaluateQuery(ast);
      
      expect(results.length, equals(1));
      expect(results.first.name, equals('Beta Project'));
    });

    test('lowercase query matches uppercase name', () async {
      final ast = parseQuery('omega');
      final results = await evaluateQuery(ast);
      
      expect(results.length, equals(1));
      expect(results.first.name, equals('Omega Project Group'));
    });

    test('partial match returns multiple results', () async {
      final ast = parseQuery('project');
      final results = await evaluateQuery(ast);
      
      // Should match: Alpha Project Group, Beta Project, Omega Project Group, Sigma Project
      expect(results.length, equals(4));
    });

    test('no match returns empty list', () async {
      final ast = parseQuery('xyznotfound');
      final results = await evaluateQuery(ast);
      
      expect(results, isEmpty);
    });

    test('query with spaces works', () async {
      final ast = parseQuery('Context Requirement');
      final results = await evaluateQuery(ast);
      
      expect(results.length, equals(1));
      expect(results.first.name, equals('Zeta Context Requirement'));
    });

    test('async delay is applied', () async {
      final ast = parseQuery('test');
      final stopwatch = Stopwatch()..start();
      
      await evaluateQuery(ast);
      
      stopwatch.stop();
      // Should take approximately 1 second
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(900));
    });
  });

  group('QueryController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty', () {
      final state = container.read(queryControllerProvider);
      
      expect(state.results, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.lastQuery, isNull);
    });

    test('runQuery sets lastQuery', () async {
      final controller = container.read(queryControllerProvider.notifier);
      
      // Start the query but don't await it yet
      final future = controller.runQuery('test query');
      
      // Immediately after calling, loading should be true
      expect(container.read(queryControllerProvider).isLoading, isTrue);
      expect(container.read(queryControllerProvider).lastQuery, equals('test query'));
      
      // Now await completion so container isn't disposed early
      await future;
    });

    test('runQuery updates results after completion', () async {
      final controller = container.read(queryControllerProvider.notifier);
      
      await controller.runQuery('alpha');
      
      final state = container.read(queryControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.results.length, equals(1));
      expect(state.results.first.name, equals('Alpha Project Group'));
    });

    test('runQuery returns multiple matches', () async {
      final controller = container.read(queryControllerProvider.notifier);
      
      await controller.runQuery('project');
      
      final state = container.read(queryControllerProvider);
      expect(state.results.length, equals(4));
    });

    test('clear resets state', () async {
      final controller = container.read(queryControllerProvider.notifier);
      
      await controller.runQuery('test');
      controller.clear();
      
      final state = container.read(queryControllerProvider);
      expect(state.results, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.lastQuery, isNull);
    });
  });

  group('QueryController hide results filter', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          activeCanvasControllerProvider.overrideWith((ref) =>
              MockCanvasController({'pg-1', 'p-1'}, ref)),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('does not filter when disabled', () async {
      final controller = container.read(queryControllerProvider.notifier);
      controller.setHideResultsInView(false);
      await controller.runQuery('project');
      final state = container.read(queryControllerProvider);
      expect(state.results.length, 4);
    });

    test('filters out visible objects when enabled', () async {
      final controller = container.read(queryControllerProvider.notifier);
      controller.setHideResultsInView(true);
      await controller.runQuery('project');
      final state = container.read(queryControllerProvider);
      expect(state.results.length, 2);
      expect(state.results.any((r) => r.id == 'pg-1'), isFalse);
      expect(state.results.any((r) => r.id == 'p-1'), isFalse);
      expect(state.results.any((r) => r.id == 'pg-2'), isTrue);
      expect(state.results.any((r) => r.id == 'p-2'), isTrue);
    });
  });
}
