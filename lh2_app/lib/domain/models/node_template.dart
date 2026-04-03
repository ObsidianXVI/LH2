import 'package:lh2_stub/lh2_stub.dart';

class NodeTemplate {
  final String id;
  final ObjectType objectType;
  final String name;
  final int schemaVersion;
  final Map<String, dynamic> renderSpec;

  const NodeTemplate({
    required this.id,
    required this.objectType,
    required this.name,
    required this.schemaVersion,
    required this.renderSpec,
  });

  factory NodeTemplate.fromJson(Map<String, dynamic> json) {
    return NodeTemplate(
      id: json['id'] as String,
      objectType: ObjectType.values.byName(json['objectType'] as String),
      name: json['name'] as String,
      schemaVersion: json['schemaVersion'] as int,
      renderSpec: json['renderSpec'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'objectType': objectType.name,
      'name': name,
      'schemaVersion': schemaVersion,
      'renderSpec': renderSpec,
    };
  }
}
