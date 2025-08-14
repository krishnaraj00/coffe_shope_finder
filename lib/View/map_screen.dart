import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../Controller/fav_controller.dart';
import '../Model/model_class.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final FavoritesController favC = Get.put(FavoritesController());

  static const CameraPosition _initialCamera =
  CameraPosition(target: LatLng(10.7813, 75.9980), zoom: 4);

  LatLng? _currentLatLng;
  Set<Marker> _markers = {};
  StreamSubscription<Position>? _positionStream;
  bool _isCameraFollowing = true; // ✅ track if we should follow the user

  final List<CoffeeShop> shops = [
    CoffeeShop(id: 'cs1', name: 'Bean & Brew', lat: 10.7837, lng: 76.0076),
    CoffeeShop(id: 'cs2', name: 'Caffeine Corner', lat: 10.7677, lng: 75.9259),
    CoffeeShop(id: 'cs3', name: 'Mocha Magic', lat: 10.8423, lng: 76.0299),
  ];

  @override
  void initState() {
    super.initState();
    _setupLocation();
    ever(favC.favorites, (_) => _updateMarkers());
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _setupLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Permission', 'Location permission denied');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Get.snackbar('Permission', 'Location permission permanently denied');
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _onLocationUpdated(pos);

    _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 10))
        .listen(_onLocationUpdated);
  }

  void _onLocationUpdated(Position pos) async {
    _currentLatLng = LatLng(pos.latitude, pos.longitude);
    _updateMarkers();

    if (_isCameraFollowing && _currentLatLng != null) {
      final controller = await _controller.future;
      controller.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLatLng!, 16));
    }
  }

  void _updateMarkers() {
    final Set<Marker> newMarkers = {};

    // ✅ Only shop markers (blue dot is shown by Google Maps)
    for (final s in shops) {
      final isFav = favC.contains(s.id);
      final hue = isFav ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed;
      newMarkers.add(Marker(
        markerId: MarkerId(s.id),
        position: LatLng(s.lat, s.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(title: s.name),
        onTap: () => _onShopTap(s),
      ));
    }
    setState(() => _markers = newMarkers);
  }

  void _onShopTap(CoffeeShop shop) async {
    final userLat = _currentLatLng?.latitude;
    final userLng = _currentLatLng?.longitude;
    double? distanceMeters;
    if (userLat != null && userLng != null) {
      distanceMeters =
          Geolocator.distanceBetween(userLat, userLng, shop.lat, shop.lng);
    }
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shop.name,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            if (distanceMeters != null)
              Text('Distance: ${_formatDistance(distanceMeters)}'),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    child: Text(favC.contains(shop.id)
                        ? 'Added'
                        : 'Add to Favorites'),
                    onPressed: favC.contains(shop.id)
                        ? null
                        : () async {
                      await favC.add(shop);
                      Get.back();
                      Get.snackbar(
                          'Favorites', '${shop.name} added to favorites');
                    },
                  ),
                ),
                SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.directions),
                  onPressed: () {
                    final url =
                        'https://www.google.com/maps/dir/?api=1&destination=${shop.lat},${shop.lng}';
                    Get.snackbar('Directions URL', url,
                        snackPosition: SnackPosition.BOTTOM);
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  Future<double?> _calcDistanceToShop(CoffeeShop s) async {
    if (_currentLatLng == null) return null;
    return Geolocator.distanceBetween(
        _currentLatLng!.latitude, _currentLatLng!.longitude, s.lat, s.lng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearest Coffee Shop Finder'),
        actions: [
          IconButton(
              icon: Icon(Icons.favorite),
              onPressed: () => Get.toNamed('/favorites')),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCamera,
            myLocationEnabled: true, // ✅ blue dot
            myLocationButtonEnabled: true, // ✅ recenter button
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) _controller.complete(controller);
            },
            zoomControlsEnabled: false,
            onCameraMove: (_) {
              _isCameraFollowing = false; // stop following when user moves map
            },
          ),
          Positioned(
            right: 12,
            bottom: 80,
            child: FloatingActionButton(
              mini: true,
              child: Icon(Icons.my_location),
              onPressed: () async {
                if (_currentLatLng != null) {
                  _isCameraFollowing = true; // resume following
                  final ctrl = await _controller.future;
                  ctrl.animateCamera(
                      CameraUpdate.newLatLngZoom(_currentLatLng!, 16));
                } else {
                  Get.snackbar('Location', 'Waiting for location...');
                }
              },
            ),
          ),
          Positioned(
            left: 12,
            bottom: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 6)
                  ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shops', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  ...shops.map((s) {
                    return GestureDetector(
                      onTap: () async {
                        final ctrl = await _controller.future;
                        ctrl.animateCamera(CameraUpdate.newLatLngZoom(
                            LatLng(s.lat, s.lng), 16));
                        _onShopTap(s);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Obx(() {
                              final isFav = favC.contains(s.id);
                              return Icon(
                                  isFav ? Icons.star : Icons.local_cafe,
                                  size: 18,
                                  color: isFav
                                      ? Colors.orange
                                      : Colors.brown);
                            }),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name, style: TextStyle(fontSize: 14)),
                                SizedBox(height: 2),
                                FutureBuilder<double?>(
                                  future: _calcDistanceToShop(s),
                                  builder: (context, snap) {
                                    if (!snap.hasData) return SizedBox();
                                    return Text(
                                        _formatDistance(snap.data!),
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700]));
                                  },
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
