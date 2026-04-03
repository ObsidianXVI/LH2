import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/domain/models/node_template_ports.dart';

void main() {
  group('Port Validation Tests', () {
    test('CanvasController isValidLinkTarget works correctly', () {
      final controller = FlowCanvasController(
        viewport: const CanvasViewport(
          pan: Offset(0, 0),
          zoom: 1.0,
          viewportSizePx: Size(800, 600),
        ),
      );

      // Add test items
      controller.addItem(const CanvasItem(
        itemId: 'item1',
        itemType: 'node',
        worldRect: Rect.fromLTWH(10, 20, 100, 50),
      ));

      controller.addItem(const CanvasItem(
        itemId: 'item2',
        itemType: 'node',
        worldRect: Rect.fromLTWH(200, 100, 100, 50),
      ));

      controller.addItem(const CanvasItem(
        itemId: 'item3',
        itemType: 'widget',
        worldRect: Rect.fromLTWH(300, 200, 100, 50),
      ));

      // Test without linking mode
      expect(controller.isValidLinkTarget('item1'), isFalse);
      expect(controller.isValidLinkTarget('item2'), isFalse);

      // Start linking from item1
      controller.startLinking('item1', 'port-out');

      // Test valid targets
      expect(controller.isValidLinkTarget('item2'), isTrue); // node is valid
      expect(controller.isValidLinkTarget('item3'), isFalse); // widget is not valid
      expect(controller.isValidLinkTarget('item1'), isFalse); // self is not valid

      // Cancel linking
      controller.cancelLinking();
      expect(controller.isValidLinkTarget('item1'), isFalse);
      expect(controller.isValidLinkTarget('item2'), isFalse);
    });

    test('NodeTemplatePorts arePortsCompatible works correctly', () {
      const portOutDependency = CanvasPortSpec(
        portId: 'port-out',
        direction: 'out',
        portType: 'dependency',
      );

      const portInDependency = CanvasPortSpec(
        portId: 'port-in',
        direction: 'in',
        portType: 'dependency',
      );

      const portInData = CanvasPortSpec(
        portId: 'port-in',
        direction: 'in',
        portType: 'data',
      );

      const portOutData = CanvasPortSpec(
        portId: 'port-out',
        direction: 'out',
        portType: 'data',
      );

      // Valid connections
      expect(
        NodeTemplatePorts.arePortsCompatible(portOutDependency, portInDependency),
        isTrue,
      );

      expect(
        NodeTemplatePorts.arePortsCompatible(portOutData, portInData),
        isTrue,
      );

      // Invalid connections
      expect(
        NodeTemplatePorts.arePortsCompatible(portOutDependency, portInData),
        isFalse, // different port types
      );

      expect(
        NodeTemplatePorts.arePortsCompatible(portInDependency, portOutDependency),
        isFalse, // wrong direction
      );

      expect(
        NodeTemplatePorts.arePortsCompatible(portOutDependency, portOutData),
        isFalse, // both out ports
      );
    });

    test('NodeTemplatePorts getPortsForObjectType returns correct ports', () {
      final projectPorts = NodeTemplatePorts.getPortsForObjectType('project');
      expect(projectPorts.length, equals(2));
      expect(projectPorts[0].portId, equals('port-in'));
      expect(projectPorts[0].direction, equals('in'));
      expect(projectPorts[0].portType, equals('dependency'));
      expect(projectPorts[1].portId, equals('port-out'));
      expect(projectPorts[1].direction, equals('out'));
      expect(projectPorts[1].portType, equals('dependency'));

      final taskPorts = NodeTemplatePorts.getPortsForObjectType('task');
      expect(taskPorts.length, equals(2));
      expect(taskPorts[0].portType, equals('dependency'));
      expect(taskPorts[1].portType, equals('dependency'));

      final defaultPorts = NodeTemplatePorts.getPortsForObjectType('unknown');
      expect(defaultPorts.length, equals(2));
      expect(defaultPorts[0].portType, equals('dependency'));
      expect(defaultPorts[1].portType, equals('dependency'));
    });

    test('NodeTemplatePorts extractPortsFromRenderSpec works correctly', () {
      // Test with ports specified
      final renderSpecWithPorts = {
        'color': '#4CAF50',
        'ports': [
          {
            'portId': 'custom-in',
            'direction': 'in',
            'portType': 'custom',
          },
          {
            'portId': 'custom-out',
            'direction': 'out',
            'portType': 'custom',
          },
        ],
      };

      final extractedPorts = NodeTemplatePorts.extractPortsFromRenderSpec(renderSpecWithPorts);
      expect(extractedPorts.length, equals(2));
      expect(extractedPorts[0].portId, equals('custom-in'));
      expect(extractedPorts[0].direction, equals('in'));
      expect(extractedPorts[0].portType, equals('custom'));
      expect(extractedPorts[1].portId, equals('custom-out'));
      expect(extractedPorts[1].direction, equals('out'));
      expect(extractedPorts[1].portType, equals('custom'));

      // Test without ports (should return default)
      final renderSpecWithoutPorts = {
        'color': '#4CAF50',
        'icon': 'folder',
      };

      final defaultPorts = NodeTemplatePorts.extractPortsFromRenderSpec(renderSpecWithoutPorts);
      expect(defaultPorts.length, equals(2));
      expect(defaultPorts[0].portId, equals('port-in'));
      expect(defaultPorts[1].portId, equals('port-out'));
    });
  });
}
