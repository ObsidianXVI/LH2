import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lh2_stub/lh2_stub.dart';
import 'package:lh2_app/ui/theme/tokens.dart';
import 'package:lh2_app/app/theme.dart';
import 'package:lh2_app/domain/operations/objects.dart';
import 'package:lh2_app/domain/operations/canvas.dart';
import 'package:lh2_app/domain/notifiers/workspace_controller.dart';
import 'package:lh2_app/app/providers.dart';
import 'package:lh2_app/data/cache.dart';
import 'package:intl/intl.dart';

/// A set of form-like widgets for editing LH2 domain objects in the information overlay.
class NodeFormOverlay extends ConsumerStatefulWidget {
  final LH2Object object;

  /// Firestore object document id.
  ///
  /// If null, the form can still render (placeholder mode) but cannot persist.
  final String? objectId;

  /// Canvas item id (used to attach a newly created objectId back onto the canvas item).
  final String? canvasItemId;
  final bool isEditable;
  final VoidCallback? onSave;

  const NodeFormOverlay({
    super.key,
    required this.object,
    this.objectId,
    this.canvasItemId,
    this.isEditable = true,
    this.onSave,
  });

  @override
  ConsumerState<NodeFormOverlay> createState() => _NodeFormOverlayState();
}

class _NodeFormOverlayState extends ConsumerState<NodeFormOverlay> {
  late Map<String, dynamic> _formData;
  final _formKey = GlobalKey<FormState>();

  String? _resolvedObjectId;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _formData = Map<String, dynamic>.from(widget.object.toJson());
    _resolvedObjectId = widget.objectId;
  }

  @override
  void didUpdateWidget(NodeFormOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.object != widget.object) {
      setState(() {
        _formData = Map<String, dynamic>.from(widget.object.toJson());
        _resolvedObjectId = widget.objectId;
      });
    }
  }

  Future<void> _save({required bool closeAfter}) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      // 1) Create object if needed
      if (_resolvedObjectId == null || _resolvedObjectId!.isEmpty) {
        final createOp = ref.read(objectsCreateOpProvider);
        final result = await createOp.execute(
          ObjectsCreateInput(
            objectType: widget.object.type,
            data: _formData,
          ),
        );
        if (!result.ok) {
          throw StateError(result.error?.message ?? 'Create failed');
        }
        final newId = result.value!.objectId;
        _resolvedObjectId = newId;

        // 2) Attach objectId back to canvas item (if we know it)
        final ws = ref.read(workspaceControllerProvider);
        final tabId = ws.activeTabId;
        final itemId = widget.canvasItemId;
        if (ws.workspaceId.isNotEmpty && tabId != null && itemId != null) {
          final patchOp = ref.read(canvasPatchItemOpProvider);
          await patchOp.execute(CanvasPatchItemInput(
            workspaceId: ws.workspaceId,
            tabId: tabId,
            itemId: itemId,
            patch: {
              'objectId': newId,
              'objectType': widget.object.type.name,
            },
          ));
        }
      }

      // 3) Upsert update
      final updateOp = ref.read(objectsUpdateOpProvider);
      final updateResult = await updateOp.execute(ObjectsUpdateInput(
        objectId: _resolvedObjectId!,
        objectType: widget.object.type,
        data: _formData,
      ));
      if (!updateResult.ok) {
        throw StateError(updateResult.error?.message ?? 'Update failed');
      }

      // 4) Invalidate the cache for this object so nodes on canvas refresh
      _invalidateObjectCache(ref, widget.object.type, _resolvedObjectId!);
      
      // 5) Also refresh the objectProvider to force a rebuild of NodeCanvasItem
      ref.invalidate(objectProvider((widget.object.type, _resolvedObjectId!)));

      if (closeAfter) {
        widget.onSave?.call();
      }
    } catch (e) {
      setState(() {
        _saveError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          if (_saveError != null) ...[
            const SizedBox(height: 8),
            Text(
              _saveError!,
              style: LH2Theme.body.copyWith(color: LH2Colors.dangerRed),
            ),
          ],
          const SizedBox(height: 16),
          _buildFormFields(),
          if (widget.isEditable) ...[
            const SizedBox(height: 24),
            _buildActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final String? titleKey = switch (widget.object.type) {
      ObjectType.project => 'name',
      ObjectType.projectGroup => 'name',
      ObjectType.task => 'name',
      ObjectType.deliverable => 'name',
      ObjectType.event => 'name',
      ObjectType.session => 'description',
      _ => null,
    };

    final title = titleKey != null
        ? (_formData[titleKey] as String?)
        : widget.object.type.name;

    if (!widget.isEditable || titleKey == null) {
      return Text(
        title ?? widget.object.type.name,
        style: LH2Theme.nodeTitle.copyWith(fontSize: 18),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return TextFormField(
      initialValue: title ?? '',
      maxLines: 1,
      textInputAction: TextInputAction.done,
      style: LH2Theme.nodeTitle.copyWith(fontSize: 18),
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: (val) => _formData[titleKey] = val,
      onFieldSubmitted: (_) => _save(closeAfter: false),
    );
  }

  Widget _buildFormFields() {
    switch (widget.object.type) {
      case ObjectType.event:
        return _buildEventFields();
      case ObjectType.task:
        return _buildTaskFields();
      case ObjectType.project:
        return _buildProjectFields();
      case ObjectType.session:
        return _buildSessionFields();
      case ObjectType.contextRequirement:
        return _buildContextRequirementFields();
      default:
        return _buildGenericFields();
    }
  }

  Widget _buildEventFields() {
    final start =
        DateTime.fromMillisecondsSinceEpoch(_formData['startTs'] ?? 0);
    final end = DateTime.fromMillisecondsSinceEpoch(_formData['endTs'] ?? 0);
    final duration = end.difference(start);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTag('Work', LH2Colors.accentBlue),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildTimeBox(DateFormat('HHmm').format(start)),
            _buildDurationArrow('${duration.inHours}h'),
            _buildTimeBox(DateFormat('HHmm').format(end)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildDateBox(DateFormat('dd/MM').format(start)),
            const Expanded(child: SizedBox()),
            _buildDateBox(DateFormat('dd/MM').format(end)),
          ],
        ),
        const SizedBox(height: 16),
        _buildDescriptionField('description'),
        const SizedBox(height: 16),
        _buildSectionTitle('Preset Contexts'),
        _buildReadOnlyBox('None'),
        const SizedBox(height: 16),
        _buildSectionTitle('Custom Context'),
        _buildContextBox(),
      ],
    );
  }

  Widget _buildTaskFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownField(
            'taskStatus', TaskStatus.values.map((e) => e.name).toList()),
        const SizedBox(height: 16),
        _buildSectionTitle('Dependencies'),
        _buildReadOnlyBox(
            '${(_formData['outboundDependenciesIds'] as List?)?.length ?? 0} outbound'),
      ],
    );
  }

  Widget _buildProjectFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Stats'),
        _buildReadOnlyBox(
            '${(_formData['deliverablesIds'] as List?)?.length ?? 0} Deliverables'),
        _buildReadOnlyBox(
            '${(_formData['nonDeliverableTasksIds'] as List?)?.length ?? 0} Tasks'),
      ],
    );
  }

  Widget _buildSessionFields() {
    final scheduled =
        DateTime.fromMillisecondsSinceEpoch(_formData['scheduledTs'] ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Scheduled At'),
        _buildReadOnlyBox(DateFormat('yyyy-MM-dd HH:mm').format(scheduled)),
      ],
    );
  }

  Widget _buildContextRequirementFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Requirements'),
        _buildInfoRow(
            'Focus Level', _formData['focusLevel']?.toString() ?? '0.0'),
        _buildInfoRow(
            'Duration', '${_formData['contiguousMinutesNeeded'] ?? 0} min'),
      ],
    );
  }

  Widget _buildGenericFields() {
    return Column(
      children: _formData.entries.where((e) => e.key != 'type').map((e) {
        return _buildInfoRow(e.key, e.value.toString());
      }).toList(),
    );
  }

  // Helper Widgets

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTimeBox(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: LH2Colors.border.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(time,
          style: LH2Theme.body.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDateBox(String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: LH2Colors.border.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(date,
          style: LH2Theme.body
              .copyWith(fontSize: 11, color: LH2Colors.textSecondary)),
    );
  }

  Widget _buildDurationArrow(String duration) {
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Divider(
              color: LH2Colors.textSecondary.withOpacity(0.3),
              indent: 8,
              endIndent: 8),
          Positioned(
            top: -10,
            child: Text(duration,
                style: LH2Theme.body
                    .copyWith(fontSize: 10, color: LH2Colors.textSecondary)),
          ),
          const Positioned(
            right: 4,
            child: Icon(Icons.chevron_right,
                size: 14, color: LH2Colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: LH2Theme.body.copyWith(
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          color: LH2Colors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildReadOnlyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: LH2Colors.border.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: LH2Theme.body),
    );
  }

  Widget _buildContextBox() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        border: Border.all(color: LH2Colors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.close, size: 40, color: LH2Colors.border),
            Text(
              'Information Dialog for Context\nRequirement Node',
              textAlign: TextAlign.center,
              style: LH2Theme.body
                  .copyWith(fontSize: 10, color: LH2Colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField(String key, {String? label}) {
    return TextFormField(
      initialValue: _formData[key]?.toString() ?? '',
      style: LH2Theme.body,
      maxLines: null,
      enabled: widget.isEditable,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: LH2Theme.body.copyWith(color: LH2Colors.textSecondary),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: LH2Colors.border)),
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: LH2Colors.accentBlue)),
      ),
      onChanged: (val) => _formData[key] = val,
    );
  }

  Widget _buildDropdownField(String key, List<String> options) {
    return DropdownButtonFormField<String>(
      value: _formData[key]?.toString(),
      items: options
          .map((o) =>
              DropdownMenuItem(value: o, child: Text(o, style: LH2Theme.body)))
          .toList(),
      onChanged: widget.isEditable
          ? (val) => setState(() => _formData[key] = val)
          : null,
      decoration: InputDecoration(
        labelText: key,
        labelStyle: LH2Theme.body.copyWith(color: LH2Colors.textSecondary),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: LH2Theme.body.copyWith(color: LH2Colors.textSecondary)),
          Text(value, style: LH2Theme.body),
        ],
      ),
    );
  }

  void _invalidateObjectCache(WidgetRef ref, ObjectType type, String id) {
    switch (type) {
      case ObjectType.project:
        ref.read(projectCacheProvider).invalidate(id);
      case ObjectType.task:
        ref.read(taskCacheProvider).invalidate(id);
      case ObjectType.deliverable:
        ref.read(deliverableCacheProvider).invalidate(id);
      case ObjectType.session:
        ref.read(sessionCacheProvider).invalidate(id);
      case ObjectType.event:
        ref.read(eventCacheProvider).invalidate(id);
      case ObjectType.contextRequirement:
        ref.read(contextRequirementCacheProvider).invalidate(id);
      case ObjectType.actualContext:
        ref.read(actualContextCacheProvider).invalidate(id);
      case ObjectType.projectGroup:
        ref.read(projectGroupCacheProvider).invalidate(id);
    }
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => widget.onSave?.call(), // Just close
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isSaving ? null : () => _save(closeAfter: true),
          style: ElevatedButton.styleFrom(
            backgroundColor: LH2Colors.accentBlue,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
