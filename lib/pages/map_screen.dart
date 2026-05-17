// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class PolygonMapScreen extends StatefulWidget {
//   final List<LatLng> initialPolygon;

//   const PolygonMapScreen({Key? key, this.initialPolygon = const []}) : super(key: key);

//   @override
//   _PolygonMapScreenState createState() => _PolygonMapScreenState();
// }

// class _PolygonMapScreenState extends State<PolygonMapScreen> {
//   late GoogleMapController _mapController;
//   List<LatLng> _polygonPoints = [];

//   @override
//   void initState() {
//     super.initState();
//     _polygonPoints = List.from(widget.initialPolygon);
//   }

//   void _onMapTap(LatLng position) {
//     setState(() {
//       _polygonPoints.add(position);
//     });
//   }

//   void _onDone() {
//     Navigator.pop(context, _polygonPoints);
//   }

//   void _clearPolygon() {
//     setState(() {
//       _polygonPoints.clear();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     Set<Polygon> polygons = {
//       if (_polygonPoints.length > 2)
//         Polygon(
//           polygonId: PolygonId('selected_polygon'),
//           points: _polygonPoints,
//           strokeWidth: 2,
//           fillColor: Colors.blue.withOpacity(0.3),
//           strokeColor: Colors.blue,
//         )
//     };

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Draw Polygon'),
//         actions: [
//           IconButton(icon: Icon(Icons.check), onPressed: _onDone),
//           IconButton(icon: Icon(Icons.clear), onPressed: _clearPolygon),
//         ],
//       ),
//       body: GoogleMap(
//         initialCameraPosition: CameraPosition(
//           target: _polygonPoints.isNotEmpty ? _polygonPoints.first : LatLng(37.7749, -122.4194),
//           zoom: 12,
//         ),
//         polygons: polygons,
//         onTap: _onMapTap,
//         onMapCreated: (controller) => _mapController = controller,
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'dart:ui' as ui;

String googleApiKey = Config().googleAPIKey;

class MapPolygonPage extends StatefulWidget {
  @override
  _MapPolygonPageState createState() => _MapPolygonPageState();
}

class _MapPolygonPageState extends State<MapPolygonPage> {
  final Completer<GoogleMapController> _controller = Completer();
  MapType _currentMapType = MapType.satellite;

  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};
  List<LatLng> polygonLatLngs = [];

  final TextEditingController _searchController = TextEditingController();

  double _polygonAreaM2 = 0.0;
  double _polygonAreaAcres = 0.0;
  double _polygonAreaHectares = 0.0;

  String country = "";
  String state = "";
  String village = "";

  LatLng? _currentLatLng;

  /// RepaintBoundary key
  final GlobalKey _repaintKey = GlobalKey();
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determinePosition();
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services disabled");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        print("Location permissions denied");
        return;
      }
    }

    Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _currentLatLng = LatLng(pos.latitude, pos.longitude);

    final GoogleMapController mapController = await _controller.future;
    mapController.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: _currentLatLng!, zoom: 17.0),
    ));

    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId("current_location"),
          position: _currentLatLng!,
          infoWindow: InfoWindow(title: "You are here"),
        ),
      );
    });
  }

  void _onMapTapped(LatLng latLng) {
    setState(() {
      final markerId = MarkerId(polygonLatLngs.length.toString());
      _markers.add(Marker(markerId: markerId, position: latLng));
      polygonLatLngs.add(latLng);

      if (polygonLatLngs.length > 2) {
        _polygons.clear();
        _polygons.add(Polygon(
          polygonId: PolygonId("polygon_1"),
          points: polygonLatLngs,
          strokeColor: Colors.blue,
          fillColor: Colors.blue.withOpacity(0.2),
          strokeWidth: 2,
        ));

        _polygonAreaM2 = _computePolygonArea(polygonLatLngs);
        _polygonAreaAcres = _polygonAreaM2 / 4046.86;
        _polygonAreaHectares = _polygonAreaM2 / 10000;

        LatLng center = _getPolygonCenter(polygonLatLngs);
        _getAddressFromLatLng(center);
      }
    });
  }

  double _computePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      LatLng p1 = points[i];
      LatLng p2 = points[(i + 1) % points.length];
      area += (p1.longitude * p2.latitude) - (p2.longitude * p1.latitude);
    }
    return area.abs() / 2.0 * 111319.9 * 111319.9;
  }

  LatLng _getPolygonCenter(List<LatLng> points) {
    double lat = 0;
    double lng = 0;
    for (var p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          country = place.country ?? "";
          state = place.administrativeArea ?? "";
          village = place.locality ?? place.subLocality ?? "";
        });
      }
    } catch (e) {
      print("Error in reverse geocoding: $e");
    }
  }

  void _onPlaceSelected(dynamic prediction) async {
    final placeId = prediction.placeId ?? prediction.placeId ?? prediction.id;

    if (placeId == null) {
      print("Place ID not found");
      return;
    }

    final url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleApiKey";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final location = data['result']['geometry']['location'];
      if (location == null) {
        print("No geometry in place details.");
        return;
      }
      final LatLng selectedLatLng = LatLng(location['lat'], location['lng']);

      final GoogleMapController mapController = await _controller.future;
      mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: selectedLatLng, zoom: 17.0),
      ));

      setState(() {
        _markers.removeWhere((m) => m.markerId.value == "searched_location");
        _markers.add(
          Marker(
            markerId: MarkerId("searched_location"),
            position: selectedLatLng,
            infoWindow: InfoWindow(title: prediction.description ?? "Selected Location"),
          ),
        );
      });
    } else {
      print("Failed to fetch place details, status: ${response.statusCode}");
    }
  }

  Future<PolygonCaptureResult?> _onSavePolygon() async {
    if (polygonLatLngs.length < 3  && !isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Draw a polygon with at least 3 points first")),
      );
      setState(() {
             isLoading = false;
       });
      return null;
    }

    try {
      setState(() {
          isLoading = true;
       });
      await WidgetsBinding.instance.endOfFrame;

      RenderRepaintBoundary boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      // if (boundary.debugNeedsPaint) {
      //   await Future.delayed(Duration(milliseconds: 300));
      //   return await _onSavePolygon(); // Retry
      // }

      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      String base554Image = base64Encode(pngBytes);

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/map_capture_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(pngBytes);
      
      //print("📸 Captured image saved to: $path");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Map Captured!")),
      );

      final result = PolygonCaptureResult(
        imagePath: path,
        points: List.from(polygonLatLngs),
        areaM2: _polygonAreaM2,
        areaHectares: _polygonAreaHectares,
        areaAcres: _polygonAreaAcres,
        country: country,
        state: state,
        village: village,
        base54Image:base554Image,
      );

      Navigator.pop(context, result);

    } catch (e) {
      print("Error capturing screenshot: $e");
            setState(() {
              isLoading = false;
            });
      return null;
    }
  }


  void _onClearMap() {
    setState(() {
      _markers.clear();
      _polygons.clear();
      polygonLatLngs.clear();
      _polygonAreaM2 = 0.0;
      _polygonAreaAcres = 0.0;
      _polygonAreaHectares = 0.0;
      country = "";
      state = "";
      village = "";
      _searchController.clear();
      if (_currentLatLng != null) {
        _markers.add(
          Marker(
            markerId: MarkerId("current_location"),
            position: _currentLatLng!,
            infoWindow: InfoWindow(title: "You are here"),
          ),
        );
      }
    });
  }

  Future<void> _goToLocation(LatLng latLng) async {
    final GoogleMapController mapController = await _controller.future;
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: latLng, zoom: 17.0)),
    );
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId("current_location"),
          position: latLng,
          infoWindow: InfoWindow(title: "You are here"),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Map Farm with Polygon & Capture"),
        actions: [
          IconButton(
            icon: Icon(_currentMapType == MapType.normal ? Icons.satellite : Icons.map),
            onPressed: () {
              setState(() {
                _currentMapType = (_currentMapType == MapType.normal ? MapType.satellite : MapType.normal);
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.clear),
            tooltip: "Clear Map",
            onPressed: _onClearMap,
          ),
        ],
      ),
      body: Stack(
        children: [
          RepaintBoundary(
            key: _repaintKey,
            child: GoogleMap(
              mapType: _currentMapType,
              initialCameraPosition: CameraPosition(target: LatLng(0, 0), zoom: 2.0),
              markers: _markers,
              polygons: _polygons,
              onTap: _onMapTapped,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              zoomControlsEnabled: true,
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 60,
            child: GooglePlaceAutoCompleteTextField(
              textEditingController: _searchController,
              googleAPIKey: googleApiKey,
              itemBuilder: (context, index, prediction) {
                return Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.black54),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          prediction.description ?? "",
                          style: const TextStyle(color: Colors.black),
                        ),
                      )
                    ],
                  ),
                );
              },
              inputDecoration: InputDecoration(
                hintText: "Search Location",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              debounceTime: 800,
              countries: ["ug","ke"],
              isLatLngRequired: false,
              itemClick: (prediction) {
                _searchController.text = prediction.description ?? "";
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _searchController.text.length),
                );
                _onPlaceSelected(prediction);
              },
            ),
          ),
          Positioned(
            bottom: 90,
            left: 10,
            right: 10,
            child: Container(
              padding: EdgeInsets.all(8),
              color: Colors.white.withOpacity(0.8),
              child: Text(
                "Country: $country\n"
                "State: $state\n"
                "Village: $village\n"
                "Area: ${_polygonAreaM2.toStringAsFixed(2)} m² | "
                "${_polygonAreaAcres.toStringAsFixed(4)} acres | "
                "${_polygonAreaHectares.toStringAsFixed(4)} ha",
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 10,
            right: 70,
            child:isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                        backgroundColor: Colors.green,
                                      )
                                    : ElevatedButton.icon(
              onPressed: _onSavePolygon,
              icon: Icon(Icons.save),
              label: Text("Save"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 14),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 10,
            width: 40,
            child: FloatingActionButton(
              onPressed: () {
                if (_currentLatLng != null) {
                  _goToLocation(_currentLatLng!);
                } else {
                  _determinePosition();
                }
              },
              child: Icon(Icons.my_location),
              tooltip: "Go to current location",
            ),
          ),
        ],
      ),
    );
  }
}
class PolygonCaptureResult {
  final String imagePath;
  final List<LatLng> points;
  final double areaM2;
  final double areaHectares;
  final double areaAcres;
  final String country;
  final String state;
  final String village;
  final String base54Image;

  PolygonCaptureResult({
    required this.imagePath,
    required this.points,
    required this.areaM2,
    required this.areaHectares,
    required this.areaAcres,
    required this.country,
    required this.state,
    required this.village,
    required this.base54Image,
  });
}
