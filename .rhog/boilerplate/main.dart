library lh2.app;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lh2_stub/lh2_stub.dart';
import 'package:vs_node_view/vs_node_view.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part './db_interface/firestore.dart';
part './db_interface/firestore_db_interface.dart';

final FirestoreDBInterface firestoreDBInterface = FirestoreDBInterface();
final LH2API lh2 = LH2API(databaseInterface: firestoreDBInterface);
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    BrowserContextMenu.disableContextMenu();
  }
  runApp(const LH2App());
}

class LH2App extends StatelessWidget {
  const LH2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: LH2NodeCanvas());
  }
}

class LH2NodeCanvas extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LH2NodeCanvasState();
}

class LH2NodeCanvasState extends State<LH2NodeCanvas> {
  late final VSNodeDataProvider nodeDataProvider = VSNodeDataProvider(
    nodeManager: VSNodeManager(
      nodeBuilders: [
        textInputNode,

        outputNode,
        (offset, _) => VSNodeData(
          title: 'nigga',
          type: 'type',
          widgetOffset: offset,
          inputData: [],
          outputData: [],
        ),
      ],
    ),
  );
  @override
  void initState() {
    super.initState();
  }

  VSWidgetNode textInputNode(Offset offset, VSOutputData? ref) {
    final controller = TextEditingController();
    final inputWidget = TextField(
      controller: controller,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      ),
    );

    return VSWidgetNode(
      type: "Input",
      widgetOffset: offset,
      outputData: VSStringOutputData(
        type: "Output",
        outputFunction: (data) => controller.text,
      ),
      child: Expanded(
        child: Container(color: Colors.red, child: inputWidget),
      ),
      setValue: (value) => controller.text = value,
      getValue: () => controller.text,
    );
  }

  VSOutputNode outputNode(Offset offset, VSOutputData? ref) {
    return VSOutputNode(type: "Output", widgetOffset: offset, ref: ref);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          GridPaper(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),
          InteractiveVSNodeView(
            width: 5000,
            height: 5000,
            nodeDataProvider: nodeDataProvider,
            baseNodeView: VSNodeView(
              nodeDataProvider: nodeDataProvider,
              nodeBuilder: (context, data) => Container(
                width: 100,
                height: 100,
                color: Colors.green,
                child: Text(data.title),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
