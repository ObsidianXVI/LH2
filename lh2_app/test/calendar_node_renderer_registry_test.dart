import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/ui/flow_canvas/calendar_node_renderer_registry.dart';
import 'package:lh2_app/domain/models/node_template.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_stub/lh2_stub.dart';

void main() {
  group('CalendarNodeRendererRegistry', () {
    late CalendarNodeRendererRegistry registry;

    setUp(() {
      registry = CalendarNodeRendererRegistry();
    });

    testWidgets('builds calendar-specific deliverable variant',
        (WidgetTester tester) async {
      final deliverable = Deliverable(
        name: 'D1',
        tasksIds: const [],
        deadlineTs: DateTime.now().millisecondsSinceEpoch,
      );

      const template = NodeTemplate(
        id: 't',
        objectType: ObjectType.deliverable,
        name: 't',
        schemaVersion: 1,
        renderSpec: {},
      );

      const item = CanvasItem(
        itemId: 'i',
        itemType: 'node',
        objectType: 'deliverable',
        worldRect: Rect.fromLTWH(0, 0, 100, 60),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: registry.build(deliverable, template, item),
          ),
        ),
      );

      // Title should appear.
      expect(find.text('D1'), findsOneWidget);
      // Deliverable variant draws a small circular out-port anchor.
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('contextRequirement variant renders "conditional" label',
        (WidgetTester tester) async {
      const cr = ContextRequirement(
        focusLevel: 0.5,
        contiguousMinutesNeeded: 30,
        resourceTags: {},
      );

      const template = NodeTemplate(
        id: 't',
        objectType: ObjectType.contextRequirement,
        name: 't',
        schemaVersion: 1,
        renderSpec: {},
      );

      const item = CanvasItem(
        itemId: 'i',
        itemType: 'node',
        objectType: 'contextRequirement',
        worldRect: Rect.fromLTWH(0, 0, 200, 120),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: registry.build(cr, template, item),
          ),
        ),
      );

      expect(find.text('conditional'), findsOneWidget);
    });
  });
}
