import 'dart:collection';

class GraphEdge {
  final String targetNodeId;
  final double distanceMeters;
  final double speedLimitKmh;

  const GraphEdge({
    required this.targetNodeId,
    required this.distanceMeters,
    this.speedLimitKmh = 40.0,
  });

  double get travelTimeSeconds => (distanceMeters / (speedLimitKmh * 1000.0 / 3600.0));
}

class GraphNode {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  const GraphNode({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

class DijkstraResult {
  final List<String> pathNodeIds;
  final double totalDistanceMeters;
  final double estimatedTimeSeconds;
  final int exploredNodes;
  final int executionTimeMicros;

  const DijkstraResult({
    required this.pathNodeIds,
    required this.totalDistanceMeters,
    required this.estimatedTimeSeconds,
    required this.exploredNodes,
    required this.executionTimeMicros,
  });
}

class DijkstraRouter {
  final Map<String, GraphNode> nodes;
  final Map<String, List<GraphEdge>> adjacencyList;

  DijkstraRouter({
    required this.nodes,
    required this.adjacencyList,
  });

  /// Computes shortest path from startNodeId to targetNodeId using Dijkstra's algorithm
  DijkstraResult findShortestPath(String startNodeId, String targetNodeId) {
    final stopwatch = Stopwatch()..start();
    int exploredNodesCount = 0;

    final distances = <String, double>{};
    final times = <String, double>{};
    final previous = <String, String?>{};
    final visited = <String>{};

    for (final nodeId in nodes.keys) {
      distances[nodeId] = double.infinity;
      times[nodeId] = double.infinity;
      previous[nodeId] = null;
    }

    distances[startNodeId] = 0.0;
    times[startNodeId] = 0.0;

    // Priority queue simulation
    final unvisited = SplayTreeSet<String>((a, b) {
      final distCompare = (distances[a] ?? double.infinity).compareTo(distances[b] ?? double.infinity);
      if (distCompare != 0) return distCompare;
      return a.compareTo(b);
    });

    unvisited.add(startNodeId);

    while (unvisited.isNotEmpty) {
      final current = unvisited.first;
      unvisited.remove(current);
      visited.add(current);
      exploredNodesCount++;

      if (current == targetNodeId) {
        break; // Destination reached
      }

      final edges = adjacencyList[current] ?? [];
      for (final edge in edges) {
        if (visited.contains(edge.targetNodeId)) continue;

        final newDist = distances[current]! + edge.distanceMeters;
        if (newDist < (distances[edge.targetNodeId] ?? double.infinity)) {
          unvisited.remove(edge.targetNodeId); // Re-order in sorted set
          distances[edge.targetNodeId] = newDist;
          times[edge.targetNodeId] = (times[current] ?? 0.0) + edge.travelTimeSeconds;
          previous[edge.targetNodeId] = current;
          unvisited.add(edge.targetNodeId);
        }
      }
    }

    stopwatch.stop();

    // Reconstruct path
    final path = <String>[];
    String? curr = targetNodeId;
    if (distances[targetNodeId] != double.infinity) {
      while (curr != null) {
        path.insert(0, curr);
        curr = previous[curr];
      }
    }

    return DijkstraResult(
      pathNodeIds: path,
      totalDistanceMeters: distances[targetNodeId] ?? double.infinity,
      estimatedTimeSeconds: times[targetNodeId] ?? double.infinity,
      exploredNodes: exploredNodesCount,
      executionTimeMicros: stopwatch.elapsedMicroseconds,
    );
  }
}

