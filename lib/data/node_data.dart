import 'package:vector_math/vector_math_64.dart';

class NodeData {
  late final Vector2 fromNode;
  late final Vector2 toNode;
  //Khai báo tập gamma (Các đỉnh kề của đỉnh đang được xét)
  late final List<NodeData> edges;
  NodeData? previosNode;
  double distance = 0;

  NodeData(this.fromNode, this.toNode) {
    edges = [];
  }

  static NodeData clone(NodeData value) {
    return NodeData(value.fromNode, value.toNode);
  }

  NodeData.fromJson(Map json) {
    fromNode = Vector2(json['fromX'], json['fromY']);
    toNode = Vector2(json['toX'], json['toY']);
    edges = [];
  }

  Map<String, dynamic> toJson() {
    return {
      'fromX': fromNode.x,
      'fromY': fromNode.y,
      'toX': toNode.x,
      'toY': toNode.y,
    };
  }

  double get weight => fromNode.distanceTo(toNode);

  void addEdge(NodeData node) {
    edges.add(node);
  }

  @override
  bool operator ==(Object other) =>
      (other is NodeData) && toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() =>
      'from:${fromNode.x.floor()}-${fromNode.y.floor()}  to:${toNode.x.floor()}-${toNode.y.floor()}';
}
