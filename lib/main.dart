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

//Hàng đợi chức tập mở (đã sắp xếp theo độ dài đường đi từ bé đến lớn)
  final PriorityQueue<NodeData> queue =
      PriorityQueue((curr, next) => curr.distance.compareTo(next.distance));
//List chứa tập đóng
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
    final scale = size.height / 387;
    final columns = (size.width / (4 * scale)).floor();
    final rows = (size.height / (4 * scale)).floor();

    return Scaffold(
      body: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Image.asset(
                'assets/map.png',
                // height: size.height,
                // fit: BoxFit.none,
              ),
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
                                width: (4 * scale),
                                height: (4 * scale),
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
                Positioned(
                  top: 0,
                  left: 0,
                  bottom: 0,
                  right: 0,
                  child: CustomPaint(
                    painter: LinePainter(result, scale),
                  ),
                )
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
    );
  }

  void selectFromNode(TapDownDetails details) {
    final size = MediaQuery.of(context).size;
    final scale = size.height / 392;
    final selectedFromNode = Vector2(
        (details.localPosition.dx / (4 * scale)).floor().toDouble(),
        (details.localPosition.dy / (4 * scale)).floor().toDouble());
    setState(() {
      fromNode = findNearNode(selectedFromNode);
    });
  }

  void selectToNode(TapDownDetails details) {
    final size = MediaQuery.of(context).size;
    final scale = size.height / 392;
    final selectedToNode = Vector2(
        (details.localPosition.dx / (4 * scale)).floor().toDouble(),
        (details.localPosition.dy / (4 * scale)).floor().toDouble());

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
      await file
          .writeAsString(json.encode(nodes.map((e) => e.toJson()).toList()));
    }
  }

  Future<void> readFile() async {
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
    //Add đỉnh đã duyệt vào list
    previos.add(fromNode!.toString());

    //thêm các đỉnh kề với fromNode
    final newList = getNodeFrom(fromNode!.fromNode);
    for (var edge in newList) {
      edge.distance = fromNode!.distance + edge.weight;
      //Thêm vào tập đỉnh kề của đỉnh đang xét
      fromNode!.addEdge(edge);
    }

    queue.addAll(newList);

    while (queue.isNotEmpty) {
      //Lấy ra đỉnh đầu tiên của hàng đợi (đỉnh có đường đi ngắn nhất)
      final currentNode = queue.removeFirst();
      //Xét các đỉnh kề với currentNode
      final edges = addNode(currentNode);
      queue.addAll(edges);

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
  final double scale;
  final List<NodeData> data;

  LinePainter(this.data, this.scale);
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final Path path = Path();
    if (data.isNotEmpty) {
      final first = data.first;
      path.moveTo(first.fromNode.x * 4 * scale + 2 * scale,
          (first.fromNode.y * 4 * scale) + 2 * scale);
      for (int i = 1; i < data.length; i++) {
        print(i);
        path.lineTo(data[i].toNode.x * 4 * scale + 2 * scale,
            data[i].toNode.y * 4 * scale + 2 * scale);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
