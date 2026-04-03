import 'package:flutter/material.dart';
import 'package:lh2_stub/lh2_stub.dart';
import 'package:lh2_app/domain/models/node_template.dart';
import 'package:lh2_app/domain/notifiers/canvas_controller_impl.dart';
import 'package:lh2_app/ui/theme/tokens.dart';

class BaseNodeWidget extends StatelessWidget {
  final LH2Object object;
  final NodeTemplate template;
  final CanvasItem item;
  final Widget child;

  const BaseNodeWidget({
    super.key,
    required this.object,
    required this.template,
    required this.item,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final spec = template.renderSpec;
    final style = spec['style'] as Map<String, dynamic>? ?? {};

    var backgroundColor =
        _parseColor(style['backgroundColor']) ?? LH2Colors.panel;
    final borderColor = _parseColor(style['borderColor']) ?? LH2Colors.border;
    final textColor = _parseColor(style['textColor']) ?? LH2Colors.textPrimary;

    final size = spec['size'] as Map<String, dynamic>? ?? {};
    final width = (size['width'] as num?)?.toDouble();
    final height = (size['height'] as num?)?.toDouble();

    if (item.disabledByScenario) {
      backgroundColor = backgroundColor.withOpacity(0.5);
    }

    return Container(
      width: width,
      height: height,
      foregroundDecoration: item.disabledByScenario
          ? BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: item.disabledByScenario ? Colors.grey : borderColor,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: IgnorePointer(
        ignoring: item.disabledByScenario,
        child: Opacity(
          opacity: item.disabledByScenario ? 0.5 : 1.0,
          child: DefaultTextStyle(
            style: TextStyle(
              color: textColor,
              fontFamily: 'Menlo',
              fontSize: 12,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Color? _parseColor(dynamic value) {
    if (value == null) return null;
    if (value is int) return Color(value);
    if (value is String) {
      if (value.startsWith('#')) {
        final hex = value.substring(1);
        if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
        if (hex.length == 8) return Color(int.parse(hex, radix: 16));
      }
    }
    return null;
  }
}

class GenericNodeRenderer extends StatelessWidget {
  final LH2Object object;
  final NodeTemplate template;
  final CanvasItem item;

  const GenericNodeRenderer({
    super.key,
    required this.object,
    required this.template,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final spec = template.renderSpec;
    final header = spec['header'] as Map<String, dynamic>? ?? {};
    final showTitle = header['showTitle'] as bool? ?? true;
    final bodyFields = spec['bodyFields'] as List<dynamic>? ?? [];

    return BaseNodeWidget(
      object: object,
      template: template,
      item: item,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: LH2Colors.border)),
              ),
              child: Text(
                _getDisplayName(),
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: bodyFields.map((field) {
                  final value = _getFieldValue(field.toString());
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('$field: $value'),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayName() {
    final json = object.toJson();
    return (json['name'] ?? json['description'] ?? object.type.name).toString();
  }

  String _getFieldValue(String field) {
    final json = object.toJson();
    final value = json[field];
    if (value == null) return 'N/A';
    return value.toString();
  }
}
