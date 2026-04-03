import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';

/// Port specifications for node templates
class NodeTemplatePorts {
  /// Validates port compatibility between two ports
  static bool arePortsCompatible(CanvasPortSpec fromPort, CanvasPortSpec toPort) {
    // Basic validation: out port can connect to in port of same type
    return fromPort.direction == 'out' && 
           toPort.direction == 'in' && 
           fromPort.portType == toPort.portType;
  }

  /// Gets port specifications for a node template based on object type
  static List<CanvasPortSpec> getPortsForObjectType(String objectType) {
    switch (objectType) {
      case 'project':
        return [
          const CanvasPortSpec(portId: 'port-in', direction: 'in', portType: 'dependency'),
          const CanvasPortSpec(portId: 'port-out', direction: 'out', portType: 'dependency'),
        ];
      case 'task':
        return [
          const CanvasPortSpec(portId: 'port-in', direction: 'in', portType: 'dependency'),
          const CanvasPortSpec(portId: 'port-out', direction: 'out', portType: 'dependency'),
        ];
      case 'deliverable':
        return [
          const CanvasPortSpec(portId: 'port-in', direction: 'in', portType: 'dependency'),
          const CanvasPortSpec(portId: 'port-out', direction: 'out', portType: 'dependency'),
        ];
      case 'session':
        return [
          const CanvasPortSpec(portId: 'port-in', direction: 'in', portType: 'dependency'),
          const CanvasPortSpec(portId: 'port-out', direction: 'out', portType: 'dependency'),
        ];
      case 'event':
        return [
          const CanvasPortSpec(portId: 'port-in', direction: 'in', portType: 'dependency'),
          const CanvasPortSpec(portId: 'port-out', direction: 'out', portType: 'dependency'),
        ];
      case 'contextRequirement':
        return [
          const CanvasPortSpec(portId: 'port-in', direction: 'in', portType: 'dependency'),
          const CanvasPortSpec(portId: 'port-out', direction: 'out', portType: 'dependency'),
        ];
      case 'actualContext':
        return [
          const CanvasPortSpec(portId: 'port-in', direction: 'in', portType: 'dependency'),
          const CanvasPortSpec(portId: 'port-out', direction: 'out', portType: 'dependency'),
        ];
      default:
        return [
          const CanvasPortSpec(portId: 'port-in', direction: 'in', portType: 'dependency'),
          const CanvasPortSpec(portId: 'port-out', direction: 'out', portType: 'dependency'),
        ];
    }
  }

  /// Extracts port specifications from a node template's renderSpec
  static List<CanvasPortSpec> extractPortsFromRenderSpec(Map<String, dynamic> renderSpec) {
    final portsJson = renderSpec['ports'] as List<dynamic>?;
    if (portsJson == null) {
      // Default ports if none specified
      return getPortsForObjectType('default');
    }

    return portsJson.map((portJson) {
      return CanvasPortSpec(
        portId: portJson['portId'] as String,
        direction: portJson['direction'] as String,
        portType: portJson['portType'] as String,
      );
    }).toList();
  }
}