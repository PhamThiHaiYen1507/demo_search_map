import 'package:vector_math/vector_math_64.dart';

class NodeData {
  final Vector2 fromNode;
  final Vector2 toNode;
  double get distance => fromNode.distanceTo(toNode);

  NodeData(this.fromNode, this.toNode);
}
//VD: (node đi, node đến, trọng số)
