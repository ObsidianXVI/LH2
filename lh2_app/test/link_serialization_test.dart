import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';

void main() {
  group('CanvasLink serialization', () {
    test('CanvasLink toJson/fromJson roundtrip', () {
      const link = CanvasLink(
        linkId: 'link_123',
        fromItemId: 'item_a',
        fromPortId: 'port-out',
        toItemId: 'item_b',
        toPortId: 'port-in',
        relationType: 'outboundDependency',
      );

      final json = link.toJson();
      final decoded = CanvasLink.fromJson('link_123', json);

      expect(decoded.linkId, equals('link_123'));
      expect(decoded.fromItemId, equals(link.fromItemId));
      expect(decoded.fromPortId, equals(link.fromPortId));
      expect(decoded.toItemId, equals(link.toItemId));
      expect(decoded.toPortId, equals(link.toPortId));
      expect(decoded.relationType, equals(link.relationType));
    });
  });
}
