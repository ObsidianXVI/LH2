import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/domain/operations/canvas.dart';
import 'package:lh2_app/data/workspace_repository.dart';
import 'dart:async';

// Manual Mock
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
  late MockWorkspaceRepository mockRepo;
  late CanvasRemoveItemsOp op;

  setUp(() {
    mockRepo = MockWorkspaceRepository();
    op = CanvasRemoveItemsOp(mockRepo);
  });

  group('CanvasRemoveItemsOp', () {
    test('removes items successfully', () async {
      const workspaceId = 'w1';
      const tabId = 't1';

      mockRepo.nextTab = const WorkspaceTab(
        schemaVersion: 1,
        kind: 'flow',
        title: 'Tab',
        controller: {},
        items: {
          'node1': {'itemId': 'node1'},
          'node2': {'itemId': 'node2'},
          'node3': {'itemId': 'node3'},
        },
        links: {},
      );

      final result = await op.execute(const CanvasRemoveItemsInput(
        workspaceId: workspaceId,
        tabId: tabId,
        itemIds: ['node1', 'node2'],
      ));

      expect(result.ok, true);
      expect(mockRepo.lastPatch!.items!.containsKey('node1'), false);
      expect(mockRepo.lastPatch!.items!.containsKey('node2'), false);
      expect(mockRepo.lastPatch!.items!.containsKey('node3'), true);
    });

    test('returns error when workspaceId or tabId is empty', () async {
      final result = await op.execute(const CanvasRemoveItemsInput(
        workspaceId: '',
        tabId: '',
        itemIds: ['node1'],
      ));

      expect(result.ok, false);
      expect(result.error!.errorCode, 'INVALID_INPUT');
    });
  });
}
