import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart' as clu;
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

mixin ClusterItem {
  LatLng get location;

  String? _geohash;

  String get geohash => _geohash ??= clu.Geohash.encode(
        location,
        codeLength: clu.ClusterManager.precision,
      );
}
