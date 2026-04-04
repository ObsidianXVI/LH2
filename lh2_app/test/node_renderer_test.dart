import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/domain/models/node_template.dart';
import 'package:lh2_app/ui/flow_canvas/node_renderer_registry.dart';
import 'package:lh2_stub/lh2_stub.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:flutter/material.dart';

void main() {
  group('NodeTemplate & RendererRegistry Tests', () {
    test('NodeTemplate JSON roundtrip', () {
      final template = NodeTemplate(
        id: 'test-id',
        objectType: ObjectType.project,
        name: 'Test Template',
        schemaVersion: 1,
        renderSpec: {
          'header': {'showTitle': true},
          'bodyFields': ['name'],
          'style': {'backgroundColor': 0xFFFFFFFF},
        },
      );

      final json = template.toJson();
      final fromJson = NodeTemplate.fromJson(json);

      expect(fromJson.id, template.id);
      expect(fromJson.objectType, template.objectType);
      expect(fromJson.name, template.name);
      expect(fromJson.renderSpec['header']['showTitle'], true);
    });

    testWidgets('NodeRendererRegistry builds default widgets',
        (WidgetTester tester) async {
      final project = Project(
        name: 'Test Project',
        deliverablesIds: [],
        nonDeliverableTasksIds: [],
      );

      final template = NodeTemplate(
        id: 'test-id',
        objectType: ObjectType.project,
        name: 'Test Template',
        schemaVersion: 1,
        renderSpec: {
          'header': {'showTitle': true},
          'bodyFields': ['name'],
        },
      );

      final item = CanvasItem(
        itemId: 'item-1',
        itemType: 'project',
        worldRect: Rect.fromLTWH(0, 0, 100, 100),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: nodeRendererRegistry.build(project, template, item),
          ),
        ),
      );

      expect(find.text('Test Project'), findsAtLeast(1));
    });
  });
}
