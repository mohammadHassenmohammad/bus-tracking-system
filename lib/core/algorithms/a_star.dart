import 'dart:collection';
import 'dijkstra.dart';
import 'haversine.dart';

class AStarResult {
  final List<String> pathNodeIds;
  final double totalDistanceMeters;
  final double estimatedTimeSeconds;
  final int exploredNodes;
  final int executionTimeMicros;

  const AStarResult({
    required this.pathNodeIds,
    required this.totalDistanceMeters,
    required this.estimatedTimeSeconds,
    required this.exploredNodes,
    required this.executionTimeMicros,
  });
}

class AStarRouter {
  final Map<String, GraphNode> nodes;
  final Map<String, List<GraphEdge>> adjacencyList;

  AStarRouter({
    required this.nodes,
    required this.adjacencyList,
  });

  /// Computes optimal route using A* heuristic pathfinding
  AStarResult findOptimalPath(String startNodeId, String targetNodeId) {
    final stopwatch = Stopwatch()..start();
    int exploredNodesCount = 0;

    final targetNode = nodes[targetNodeId];
    if (targetNode == null || !nodes.containsKey(startNodeId)) {
      return const AStarResult(
        pathNodeIds: [],
        totalDistanceMeters: double.infinity,
        estimatedTimeSeconds: double.infinity,
        exploredNodes: 0,
        executionTimeMicros: 0,
      );
    }

    // gScore: Cost from start to n
    final gScore = <String, double>{};
    // fScore: gScore + heuristic
    final fScore = <String, double>{};
    final cameFrom = <String, String?>{};
    final closedSet = <String>{};

    for (final nodeId in nodes.keys) {
      gScore[nodeId] = double.infinity;
      fScore[nodeId] = double.infinity;
    }

    gScore[startNodeId] = 0.0;
    fScore[startNodeId] = _heuristic(startNodeId, targetNodeId);

    final openSet = SplayTreeSet<String>((a, b) {
      final fCompare = (fScore[a] ?? double.infinity).compareTo(fScore[b] ?? double.infinity);
      if (fCompare != 0) return fCompare;
      return a.compareTo(b);
    });

    openSet.add(startNodeId);

    while (openSet.isNotEmpty) {
      final current = openSet.first;
      openSet.remove(current);
      closedSet.add(current);
      exploredNodesCount++;

      if (current == targetNodeId) {
        break; // Goal reached
      }

      final edges = adjacencyList[current] ?? [];
      for (final edge in edges) {
        if (closedSet.contains(edge.targetNodeId)) continue;

        final tentativeGScore = gScore[current]! + edge.distanceMeters;

        if (tentativeGScore < (gScore[edge.targetNodeId] ?? double.infinity)) {
          cameFrom[edge.targetNodeId] = current;
          gScore[edge.targetNodeId] = tentativeGScore;

          final h = _heuristic(edge.targetNodeId, targetNodeId);
          openSet.remove(edge.targetNodeId); // Re-index
          fScore[edge.targetNodeId] = tentativeGScore + h;
          openSet.add(edge.targetNodeId);
        }
      }
    }

    stopwatch.stop();

    // Reconstruct path
    final path = <String>[];
    String? curr = targetNodeId;
    if (gScore[targetNodeId] != double.infinity) {
      while (curr != null) {
        path.insert(0, curr);
        curr = cameFrom[curr];
      }
    }

    return AStarResult(
      pathNodeIds: path,
      totalDistanceMeters: gScore[targetNodeId] ?? double.infinity,
      estimatedTimeSeconds: (gScore[targetNodeId] ?? double.infinity) / (40.0 * 1000.0 / 3600.0),
      exploredNodes: exploredNodesCount,
      executionTimeMicros: stopwatch.elapsedMicroseconds,
    );
  }

  /// Admissible Euclidean / Haversine straight-line heuristic in meters
  double _heuristic(String fromNodeId, String toNodeId) {
    final fromNode = nodes[fromNodeId];
    final toNode = nodes[toNodeId];
    if (fromNode == null || toNode == null) return 0.0;

    return Haversine.distanceMeters(
      fromNode.latitude, fromNode.longitude,
      toNode.latitude, toNode.longitude,
    );
  }
}

