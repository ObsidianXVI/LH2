import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/domain/notifiers/query_controller.dart';
import 'package:lh2_stub/lh2_stub.dart';

void main() {
  group('Query Parser', () {
    test('parses plain text', () {
      final ast = parseQuery('hello world');
      expect(ast.nodes.length, 2);
      expect(ast.nodes[0], isA<TextQueryNode>());
      expect((ast.nodes[0] as TextQueryNode).text, 'hello');
    });

    test('parses quoted text', () {
      final ast = parseQuery('"hello world"');
      expect(ast.nodes.length, 1);
      expect(ast.nodes[0], isA<TextQueryNode>());
      expect((ast.nodes[0] as TextQueryNode).text, 'hello world');
    });

    test('parses type filter', () {
      final ast = parseQuery('type:project');
      expect(ast.nodes.length, 1);
      expect(ast.nodes[0], isA<TypeQueryNode>());
      expect((ast.nodes[0] as TypeQueryNode).type, ObjectType.project);
    });

    test('parses status filter', () {
      final ast = parseQuery('status:done');
      expect(ast.nodes.length, 1);
      expect(ast.nodes[0], isA<StatusQueryNode>());
      expect((ast.nodes[0] as StatusQueryNode).status, TaskStatus.done);
    });

    test('parses date filter', () {
      final ast = parseQuery('date:2025-03-01..2025-03-31');
      expect(ast.nodes.length, 1);
      expect(ast.nodes[0], isA<DateQueryNode>());
      expect((ast.nodes[0] as DateQueryNode).start, DateTime(2025, 3, 1));
      expect((ast.nodes[0] as DateQueryNode).end, DateTime(2025, 3, 31));
    });

    test('handles parse errors for invalid type', () {
      final ast = parseQuery('type:invalid');
      expect(ast.errors.length, 1);
      expect(ast.nodes[0], isA<TextQueryNode>());
    });
  });
}
