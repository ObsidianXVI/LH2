import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/domain/operations/canvas.dart';
import 'package:lh2_app/data/workspace_repository.dart';

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
  group('CanvasAddLinkOp', () {
    late MockWorkspaceRepository mockRepo;
    late CanvasAddLinkOp addLinkOp;

    setUp(() {
      mockRepo = MockWorkspaceRepository();
      addLinkOp = CanvasAddLinkOp(mockRepo);
    });

    test('adds link successfully', () async {
      const workspaceId = 'w1';
      const tabId = 't1';

      mockRepo.nextTab = const WorkspaceTab(
        schemaVersion: 1,
        kind: 'flow',
        title: 'Tab',
        controller: {},
        items: {
          'item1': {'itemId': 'item1', 'itemType': 'node'},
          'item2': {'itemId': 'item2', 'itemType': 'node'},
        },
        links: {},
      );

      final result = await addLinkOp.execute(const CanvasAddLinkInput(
        workspaceId: workspaceId,
        tabId: tabId,
        fromItemId: 'item1',
        fromPortId: 'port-out',
        toItemId: 'item2',
        toPortId: 'port-in',
        relationType: 'outboundDependency',
      ));

      expect(result.ok, true);
      expect(result.value?.linkId, isNotNull);
      expect(mockRepo.lastPatch!.links!.length, equals(1));

      final linkData =
          mockRepo.lastPatch!.links!.values.first as Map<String, Object?>;
      expect(linkData['fromItemId'], equals('item1'));
      expect(linkData['fromPortId'], equals('port-out'));
      expect(linkData['toItemId'], equals('item2'));
      expect(linkData['toPortId'], equals('port-in'));
      expect(linkData['relationType'], equals('outboundDependency'));
    });

    test('returns error when workspaceId or tabId is empty', () async {
      final result = await addLinkOp.execute(const CanvasAddLinkInput(
        workspaceId: '',
        tabId: '',
        fromItemId: 'item1',
        fromPortId: 'port-out',
        toItemId: 'item2',
        toPortId: 'port-in',
        relationType: 'outboundDependency',
      ));

      expect(result.ok, false);
      expect(result.error!.errorCode, 'INVALID_INPUT');
    });
  });

  group('CanvasDeleteLinkOp', () {
    late MockWorkspaceRepository mockRepo;
    late CanvasDeleteLinkOp deleteLinkOp;

    setUp(() {
      mockRepo = MockWorkspaceRepository();
      deleteLinkOp = CanvasDeleteLinkOp(mockRepo);
    });

    test('deletes link successfully', () async {
      const workspaceId = 'w1';
      const tabId = 't1';

      mockRepo.nextTab = const WorkspaceTab(
        schemaVersion: 1,
        kind: 'flow',
        title: 'Tab',
        controller: {},
        items: {},
        links: {
          'link1': {
            'fromItemId': 'item1',
            'fromPortId': 'port-out',
            'toItemId': 'item2',
            'toPortId': 'port-in',
            'relationType': 'outboundDependency',
          },
          'link2': {
            'fromItemId': 'item2',
            'fromPortId': 'port-out',
            'toItemId': 'item3',
            'toPortId': 'port-in',
            'relationType': 'outboundDependency',
          },
        },
      );

      final result = await deleteLinkOp.execute(const CanvasDeleteLinkInput(
        workspaceId: workspaceId,
        tabId: tabId,
        linkId: 'link1',
      ));

      expect(result.ok, true);
      expect(mockRepo.lastPatch!.links!.containsKey('link1'), false);
      expect(mockRepo.lastPatch!.links!.containsKey('link2'), true);
    });

    test('returns error when required fields are empty', () async {
      final result = await deleteLinkOp.execute(const CanvasDeleteLinkInput(
        workspaceId: '',
        tabId: '',
        linkId: '',
      ));

      expect(result.ok, false);
      expect(result.error!.errorCode, 'INVALID_INPUT');
    });
  });
}
