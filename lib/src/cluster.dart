import 'package:google_maps_cluster_manager/src/cluster_item.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

class Cluster<T extends ClusterItem> {
  final LatLng location;
  final Iterable<T> items;

  Cluster(this.items, this.location);

  Cluster.fromItems(this.items)
      : location = LatLng(
          items.fold<double>(0.0, (p, c) => p + c.location.latitude) / items.length,
          items.fold<double>(0.0, (p, c) => p + c.location.longitude) / items.length,
        );

  //location becomes weighted average lat lon
  Cluster.fromClusters(Cluster<T> cluster1, Cluster<T> cluster2)
      : items = cluster1.items.toSet()..addAll(cluster2.items.toSet()),
        location = LatLng(
          (cluster1.location.latitude * cluster1.count + cluster2.location.latitude * cluster2.count) / (cluster1.count + cluster2.count),
          (cluster1.location.longitude * cluster1.count + cluster2.location.longitude * cluster2.count) / (cluster1.count + cluster2.count),
        );

  /// Get number of clustered items
  int get count => items.length;

  /// True if cluster is not a single item cluster
  bool get isMultiple => items.length > 1;

  /// Basic cluster marker id
  String getId() {
    return '${location.latitude}_${location.longitude}_$count';
  }

  @override
  String toString() {
    return 'Cluster of $count $T (${location.latitude}, ${location.longitude})';
  }

  @override
  bool operator ==(other) => other is Cluster && items == other.items;

  @override
  int get hashCode => items.hashCode;
}
