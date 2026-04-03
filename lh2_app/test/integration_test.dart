import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/domain/operations/canvas.dart';
import 'package:lh2_app/data/workspace_repository.dart';

// Manual Mock for integration testing
class MockWorkspaceRepository implements WorkspaceRepository {
  WorkspaceTab? nextTab;
  WorkspaceTabPatch? lastPatch;

  @override
  Future<WorkspaceTab> getTab(String workspaceId, String tabId) async {
    return nextTab!;
  }

  @override
  Future<void> updateTab(
      String workspaceId, String tabId, WorkspaceTabPatch patch) async {
    lastPatch = patch;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Integration Test - Complete Link Flow', () {
    test('Complete link creation and persistence flow', () async {
      // Setup
      final mockRepo = MockWorkspaceRepository();
      final controller = FlowCanvasController(
        viewport: const CanvasViewport(
          pan: Offset(0, 0),
          zoom: 1.0,
          viewportSizePx: Size(800, 600),
        ),
      );

      final addLinkOp = CanvasAddLinkOp(mockRepo);
      final deleteLinkOp = CanvasDeleteLinkOp(mockRepo);

      // Initial state - empty canvas
      expect(controller.items.isEmpty, isTrue);
      expect(controller.links.isEmpty, isTrue);

      // Add some nodes
      controller.addItem(const CanvasItem(
        itemId: 'node1',
        itemType: 'node',
        worldRect: Rect.fromLTWH(100, 100, 120, 80),
        objectId: 'project-1',
      ));

      controller.addItem(const CanvasItem(
        itemId: 'node2',
        itemType: 'node',
        worldRect: Rect.fromLTWH(300, 200, 120, 80),
        objectId: 'task-1',
      ));

      expect(controller.items.length, equals(2));

      // Test linking mode
      controller.startLinking('node1', 'port-out');
      expect(controller.pendingFromItemId, equals('node1'));
      expect(controller.pendingFromPortId, equals('port-out'));

      // Test validation
      expect(controller.isValidLinkTarget('node2'), isTrue);
      expect(controller.isValidLinkTarget('node1'), isFalse); // can't link to self

      // Create link via operation
      mockRepo.nextTab = const WorkspaceTab(
        schemaVersion: 1,
        kind: 'flow',
        title: 'Test Tab',
        controller: {},
        items: {
          'node1': {'itemId': 'node1', 'itemType': 'node'},
          'node2': {'itemId': 'node2', 'itemType': 'node'},
        },
        links: {},
      );

      final result = await addLinkOp.execute(const CanvasAddLinkInput(
        workspaceId: 'test-workspace',
        tabId: 'test-tab',
        fromItemId: 'node1',
        fromPortId: 'port-out',
        toItemId: 'node2',
        toPortId: 'port-in',
        relationType: 'outboundDependency',
      ));

      expect(result.ok, isTrue);
      expect(result.value?.linkId, isNotNull);

      // Simulate updating controller with new link
      controller.addLink(CanvasLink(
        linkId: result.value!.linkId,
        fromItemId: 'node1',
        fromPortId: 'port-out',
        toItemId: 'node2',
        toPortId: 'port-in',
        relationType: 'outboundDependency',
      ));

      expect(controller.links.length, equals(1));

      // Test link deletion
      mockRepo.nextTab = const WorkspaceTab(
        schemaVersion: 1,
        kind: 'flow',
        title: 'Test Tab',
        controller: {},
        items: {},
        links: {
          'link1': {
            'linkId': 'link1',
            'fromItemId': 'node1',
            'fromPortId': 'port-out',
            'toItemId': 'node2',
            'toPortId': 'port-in',
            'relationType': 'outboundDependency',
          },
        },
      );

      final deleteResult = await deleteLinkOp.execute(const CanvasDeleteLinkInput(
        workspaceId: 'test-workspace',
        tabId: 'test-tab',
        linkId: 'link1',
      ));

      expect(deleteResult.ok, isTrue);

      // Test cancel linking
      controller.startLinking('node1', 'port-out');
      expect(controller.pendingFromItemId, isNotNull);
      controller.cancelLinking();
      expect(controller.pendingFromItemId, isNull);
      expect(controller.pendingFromPortId, isNull);
    });

    test('Node greying out during linking', () {
      final controller = FlowCanvasController(
        viewport: const CanvasViewport(
          pan: Offset(0, 0),
          zoom: 1.0,
          viewportSizePx: Size(800, 600),
        ),
      );

      // Add nodes and widget
      controller.addItem(const CanvasItem(
        itemId: 'node1',
        itemType: 'node',
        worldRect: Rect.fromLTWH(100, 100, 120, 80),
      ));

      controller.addItem(const CanvasItem(
        itemId: 'node2',
        itemType: 'node',
        worldRect: Rect.fromLTWH(300, 200, 120, 80),
      ));

      controller.addItem(const CanvasItem(
        itemId: 'widget1',
        itemType: 'widget',
        worldRect: Rect.fromLTWH(500, 300, 150, 100),
      ));

      // Start linking from node1
      controller.startLinking('node1', 'port-out');

      // Test validation (this would be used for greying out in UI)
      expect(controller.isValidLinkTarget('node1'), isFalse); // self
      expect(controller.isValidLinkTarget('node2'), isTrue);  // valid node
      expect(controller.isValidLinkTarget('widget1'), isFalse); // widget not valid

      controller.cancelLinking();
    });
  });
}