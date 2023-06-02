import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_position/data/node_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import 'map_position.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  NodeData? fromNode;

  NodeData? toNode;

  final List<NodeData> nodes = [];

  final PriorityQueue<NodeData> queue =
      PriorityQueue((curr, next) => curr.distance.compareTo(next.distance));

  final List<String> previos = [];

  final List<NodeData> result = [];
  bool isLoading = false;

  bool isSuccess = false;
  @override
  void initState() {
    readFile();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final columns = (size.width / 4).floor();
    final rows = (size.height / 4).floor();

    return Scaffold(
      body: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Stack(
            children: [
              Image.asset('assets/map.png'),
              GestureDetector(
                onDoubleTapDown: (details) {
                  if (fromNode == null) {
                    selectFromNode(details);
                  } else {
                    selectToNode(details);
                  }
                },
                child: Column(
                  children: List.generate(
                      rows,
                      (row) => Row(
                            children: List.generate(columns, (column) {
                              final point =
                                  Vector2(column.toDouble(), row.toDouble());
                              return Container(
                                width: 4,
                                height: 4,
                                color: point == fromNode?.fromNode
                                    ? Colors.red
                                    : point == toNode?.fromNode
                                        ? Colors.amber
                                        : Colors.transparent,
                                // decoration: BoxDecoration(
                                //     border: Border.all(
                                //         width: 0.1,
                                //         color: Colors.red.withOpacity(0.3)),
                                //     color: fromNode != null && fromNode == point
                                //         ? Colors.red
                                //         : toNode != null && toNode == point
                                //             ? Colors.amber
                                //             : nodes.firstWhereOrNull(
                                //                         (element) =>
                                //                             element.fromNode ==
                                //                             point) !=
                                //                     null
                                //                 ? Colors.green
                                //                 : null),
                              );
                            }),
                          )),
                ),
              ),
              if (isSuccess)
                ...result
                    .map((e) => Positioned(
                          child: Center(
                            child: CustomPaint(
                              size: const Size(300, 200),
                              painter: LinePainter(e),
                            ),
                          ),
                        ))
                    .toList()
            ],
          )),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (fromNode != null || toNode != null)
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  fromNode = null;
                  toNode = null;
                  isSuccess = false;
                });
              },
              child: const Icon(Icons.cancel),
            ),
          if (fromNode != null && toNode != null)
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  isSuccess = false;
                });
                dijkstra();
              },
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.red),
                    )
                  : const Icon(Icons.search),
            ),
        ],
      ),
      // floatingActionButton: Column(
      //   mainAxisSize: MainAxisSize.min,
      //   children: [
      //     if (fromNode != null && toNode != null)
      //       FloatingActionButton(
      //         onPressed: () {
      //           setState(() {
      //             fromNode = null;
      //             toNode = null;
      //           });
      //         },
      //         child: const Icon(Icons.cancel),
      //       ),
      //     if (fromNode != null && toNode != null)
      //       FloatingActionButton(
      //         onPressed: () {
      //           setState(() {
      //             nodes.add(NodeData(fromNode!, toNode!));
      //             nodes.add(NodeData(toNode!, fromNode!));
      //             fromNode = null;
      //             toNode = null;
      //           });
      //         },
      //         child: const Text('x2'),
      //       ),
      //     FloatingActionButton(
      //       onPressed: () {
      //         if (fromNode != null && toNode == null) {
      //           setState(() {
      //             fromNode = null;
      //             toNode = null;
      //           });
      //         } else if (fromNode != null && toNode != null) {
      //           setState(() {
      //             nodes.add(NodeData(fromNode!, toNode!));
      //             fromNode = null;
      //             toNode = null;
      //           });
      //         } else {
      //           saveFile();
      //         }
      //       },
      //       child: Icon(
      //         fromNode != null && toNode == null
      //             ? Icons.cancel
      //             : fromNode != null && toNode != null
      //                 ? Icons.check
      //                 : Icons.save,
      //       ),
      //     ),
      //   ],
      // ),
    );
  }

  void selectFromNode(TapDownDetails details) {
    final selectedFromNode = Vector2(
        (details.localPosition.dx / 4).floor().toDouble(),
        (details.localPosition.dy / 4).floor().toDouble());
    print(fromNode);
    setState(() {
      fromNode = findNearNode(selectedFromNode);
    });
  }

  void selectToNode(TapDownDetails details) {
    final selectedToNode = Vector2(
        (details.localPosition.dx / 4).floor().toDouble(),
        (details.localPosition.dy / 4).floor().toDouble());

    setState(() {
      toNode = findNearNode(selectedToNode);
    });
  }

  NodeData findNearNode(Vector2 node) {
    return nodes.reduce((curr, next) =>
        curr.fromNode.distanceTo(node) < next.fromNode.distanceTo(node)
            ? curr
            : next);
  }

  Future<void> saveFile() async {
    final dir = await getExternalStorageDirectory();
    if (dir != null) {
      final File file = File('${dir.path}/map_point.txt');
      // log(json.encode(nodes.map((e) => e.toJson()).toList()));
      await file
          .writeAsString(json.encode(nodes.map((e) => e.toJson()).toList()));
      // print('save success');
    }
  }

  Future<void> readFile() async {
    // final dir = await getExternalStorageDirectory();
    // if (dir != null) {
    //   final File file = File('${dir.path}/map_point.txt');
    //   if (!file.existsSync()) return;
    //   final data = json.decode(await file.readAsString());
    //   nodes.addAll((data as List).map((e) => NodeData.fromJson(e)));
    //   setState(() {});
    //   print('read success');
    // }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      nodes.addAll(mapPosition.map((e) => NodeData.fromJson(e)));
      setState(() {});
    });
  }

  void dijkstra() {
    queue.clear();
    previos.clear();
    result.clear();
    setState(() {
      isLoading = true;
    });

    previos.add(fromNode!.toString());
    //thêm các đỉnh kề với fromNode

    final newList = getNodeFrom(fromNode!.fromNode);
    for (var edge in newList) {
      edge.distance = fromNode!.distance + edge.weight;
      fromNode!.addEdge(edge);
    }

    queue.addAll(newList);

    // print('============start==============');
    // print(queue.toList().map((e) => e.toString()));
    while (queue.isNotEmpty) {
      final currentNode = queue.removeFirst();
      // print('============removeFirst==============');
      // print(queue.toList().map((e) => e.toString()));

      final edges = addNode(currentNode);

      // print('============getEdges==============');
      // print(queue.toList().map((e) => e.toString()));
      // print(edges.map((e) => e.toString()));

      queue.addAll(edges);
      // print('============addEdges==============');
      // print(queue.toList().map((e) => e.toString()));

      final targetNode = edges
          .firstWhereOrNull((element) => element.toNode == toNode!.fromNode);
      if (targetNode != null) {
        NodeData? n = targetNode.previosNode;

        while (n != null) {
          result.add(n);

          n = n.previosNode;
        }
        print(result);
        result.add(NodeData(fromNode!.fromNode, result.last.fromNode));
        List<NodeData> result2 = result.reversed.toList();
        result2.add(NodeData(toNode!.fromNode, result2.last.toNode));
        result.clear();
        result.addAll(result2.reversed.toList());
        print(result);
        setState(() {
          isSuccess = true;
          isLoading = false;
        });

        return;
      } else {
        print('============không tìm thấy đường đi==============');
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  List<NodeData> addNode(NodeData node) {
    final edges = getNodeFrom(node.toNode);

    previos.add(node.toString());

    for (NodeData edge in edges) {
      edge.previosNode = node;
      edge.distance = node.distance + edge.weight;
      node.addEdge(edge);
    }

    //xóa đỉnh đã được xét
    edges.removeWhere((edge) => previos.contains(edge.toString()));

    return edges;
  }

  List<NodeData> getNodeFrom(Vector2 from) {
    return nodes
        .where((element) => from == element.fromNode)
        .map((e) => NodeData.clone(e))
        .toList();
  }
}

class LinePainter extends CustomPainter {
  final NodeData data;

  LinePainter(this.data);
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 3;

    Offset start = Offset(data.fromNode.x * 4, data.fromNode.y * 4);
    Offset end = Offset(data.toNode.x * 4, data.toNode.y * 4);

    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
