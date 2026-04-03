import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_app/ui/info_popup_overlay.dart';
import 'package:lh2_app/domain/notifiers/info_popup_controller.dart';
import 'package:lh2_app/ui/flow_canvas/canvas_provider.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_stub/lh2_stub.dart';
import 'package:lh2_app/domain/operations/objects.dart';
import 'package:lh2_app/domain/operations/core.dart';

class ManualMockObjectsGetOp implements ObjectsGetOp {
  final LH2Object resultObject;
  ManualMockObjectsGetOp(this.resultObject);

  @override
  String get operationId => 'mock.get';

  @override
  Future<LH2OpResult<ObjectsGetOutput>> run(ObjectsGetInput input) async {
    return execute(input);
  }

  @override
  Future<LH2OpResult<ObjectsGetOutput>> execute(ObjectsGetInput input) async {
    return LH2OpResult.ok(ObjectsGetOutput(object: resultObject));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('InfoPopupOverlay Widget Tests', () {
    testWidgets('renders nothing when closed', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: InfoPopupOverlay(),
            ),
          ),
        ),
      );

      // Check for the title which shouldn't be there
      expect(find.text('Node Information'), findsNothing);
      expect(find.text('Configure New Node'), findsNothing);
    });

    testWidgets('renders information when open', (tester) async {
      // Set larger surface size to avoid overflow
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final project = Project(
        name: 'Test Project',
        deliverablesIds: [],
        nonDeliverableTasksIds: [],
      );
      final mockGetOp = ManualMockObjectsGetOp(project);

      final container = ProviderContainer(
        overrides: [
          objectsGetOpProvider.overrideWithValue(mockGetOp),
          activeCanvasControllerProvider.overrideWithValue(
            FlowCanvasController(
              viewport: const CanvasViewport(
                pan: Offset.zero,
                zoom: 1.0,
                viewportSizePx: Size(800, 600),
              ),
              items: {
                'test_item': CanvasItem(
                  itemId: 'test_item',
                  itemType: 'node',
                  objectId: 'project-1',
                  objectType: 'project',
                  worldRect: const Rect.fromLTWH(0, 0, 100, 100),
                ),
              },
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: InfoPopupOverlay(),
            ),
          ),
        ),
      );

      container.read(infoPopupControllerProvider.notifier).openAddMode(
            itemId: 'test_item',
            anchorScreenRect: const Rect.fromLTWH(10, 10, 50, 50),
            objectType: ObjectType.project,
            templateId: 'default',
          );

      await tester.pump(); // Start future
      await tester.pump(); // Complete future

      expect(find.text('Node Information'), findsNothing);
      expect(find.text('Configure New Node'), findsOneWidget);
      // Title is now an editable TextFormField in editable mode.
      final titleField = find.byType(TextFormField);
      expect(titleField, findsAtLeast(1));
      final tf = tester.widget<TextFormField>(titleField.first);
      expect(tf.initialValue, 'Test Project');
    });
  });
}
