import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart' as clu;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Place with clu.ClusterItem {
  final String name;
  final bool isClosed;
  final LatLng latLng;

  Place({required this.name, required this.latLng, this.isClosed = false});

  @override
  String toString() {
    return 'Place $name (closed : $isClosed)';
  }

  @override
  LatLng get location => latLng;
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Cluster Manager Demo',
      home: MapSample(),
    );
  }
}

// Clustering maps

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  late clu.ClusterManager _manager;
  late clu.ClusterManager _manager2;

  final Completer<GoogleMapController> _controller = Completer();

  Set<Marker> markers = {};
  Set<Marker> markers2 = {};

  final CameraPosition _parisCameraPosition = const CameraPosition(
    target: LatLng(48.856613, 2.352222),
    zoom: 12.0,
  );

  List<Place> items = [
    for (int i = 0; i < 10; i++)
      Place(
        name: 'Restaurant $i',
        isClosed: i % 2 == 0,
        latLng: LatLng(48.858265 - i * 0.001, 2.350107 + i * 0.001),
      ),
    for (int i = 0; i < 10; i++)
      Place(
        name: 'Bar $i',
        latLng: LatLng(48.858265 + i * 0.01, 2.350107 - i * 0.01),
      ),
    for (int i = 0; i < 10; i++)
      Place(
        name: 'Hotel $i',
        latLng: LatLng(48.858265 - i * 0.1, 2.350107 - i * 0.01),
      ),
  ];

  List<Place> items2 = [
    for (int i = 0; i < 10; i++)
      Place(
        name: 'Place $i',
        latLng: LatLng(48.848200 + i * 0.001, 2.319124 + i * 0.001),
      ),
    for (int i = 0; i < 10; i++)
      Place(
        name: 'Test $i',
        latLng: LatLng(48.858265 + i * 0.1, 2.350107 + i * 0.1),
      ),
    for (int i = 0; i < 10; i++)
      Place(
        name: 'Test2 $i',
        latLng: LatLng(48.858265 + i * 1, 2.350107 + i * 1),
      ),
  ];

  @override
  void initState() {
    _manager = clu.ClusterManager<Place>(
      items,
      _updateMarkers,
      markerBuilder: (dynamic cluster) => _getMarkerBuilder(Colors.red)(cluster),
    );

    _manager2 = clu.ClusterManager<Place>(
      items2,
      _updateMarkers2,
      markerBuilder: (dynamic cluster) => _getMarkerBuilder(Colors.blue)(cluster),
    );
    super.initState();
  }

  void _updateMarkers(Set<Marker> markers) {
    setState(() {
      this.markers = markers;
    });
  }

  void _updateMarkers2(Set<Marker> markers) {
    setState(() {
      markers2 = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
          zoomControlsEnabled: false,
          mapType: MapType.normal,
          initialCameraPosition: _parisCameraPosition,
          markers: markers..addAll(markers2),
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            _manager.setMapId(controller.mapId);
            _manager2.setMapId(controller.mapId);
          },
          onCameraMove: (position) {
            _manager.onCameraMove(position);
            _manager2.onCameraMove(position);
          },
          onCameraIdle: () {
            _manager.updateMap();
            _manager2.updateMap();
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _manager.setItems(<Place>[for (int i = 0; i < 30; i++) Place(name: 'New Place ${DateTime.now()} $i', latLng: LatLng(48.858265 + i * 0.01, 2.350107))]);
        },
        child: const Icon(Icons.update),
      ),
    );
  }

  Future<Marker> Function(clu.Cluster<Place>) _getMarkerBuilder(Color color) => (cluster) async {
        return Marker(
          markerId: MarkerId(cluster.getId()),
          position: cluster.location,
          onTap: () {
            print('---- $cluster');
            for (var p in cluster.items) {
              print('p $p');
            }
          },
          icon: await _getMarkerBitmap(cluster.isMultiple ? 125 : 75, color, text: cluster.isMultiple ? cluster.count.toString() : null),
        );
      };

  Future<BitmapDescriptor> _getMarkerBitmap(int size, Color color, {String? text}) async {
    if (kIsWeb) size = (size / 2).floor();

    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint1 = Paint()..color = color;
    final Paint paint2 = Paint()..color = Colors.white;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, paint1);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.2, paint2);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.8, paint1);

    if (text != null) {
      TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
      painter.text = TextSpan(
        text: text,
        style: TextStyle(fontSize: size / 3, color: Colors.white, fontWeight: FontWeight.normal),
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
      );
    }

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ImageByteFormat.png) as ByteData;

    return BitmapDescriptor.bytes(data.buffer.asUint8List(), width: 40, height: 40);
  }
}
