import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../firebase/repository.dart';

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../firebase/repository.dart'; // your nearbyMarkersProvider

class HomeState {
  final LatLng? currentLatLng;
  final Set<Marker> markers;
  final bool loading;
  final String? error;

  HomeState({
    this.currentLatLng,
    this.markers = const {},
    this.loading = true,
    this.error,
  });

  HomeState copyWith({
    LatLng? currentLatLng,
    Set<Marker>? markers,
    bool? loading,
    String? error,
  }) {
    return HomeState(
      currentLatLng: currentLatLng ?? this.currentLatLng,
      markers: markers ?? this.markers,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final Ref ref;
  final Location _location = Location();
  StreamSubscription<LatLng>? _locationSub;
  StreamSubscription<Set<Marker>>? _markerSub;

  HomeNotifier(this.ref) : super(HomeState());

  Future<void> initialize() async {
    try {

      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          throw Exception("Location service is required.");
        }
      }

      // Check location permission
      PermissionStatus permission = await _location.hasPermission();

      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission != PermissionStatus.granted) {
          throw Exception("Location permission is required.");
        }
      } else if (permission == PermissionStatus.deniedForever) {
        throw Exception("Location permission permanently denied. Enable it from app settings.");
      }

      // 2. Get current location
      final loc = await _location.getLocation();
      final LatLng currentLatLng = LatLng(loc.latitude!, loc.longitude!);

      // 3. Listen to Firestore markers
      _markerSub?.cancel();
      _markerSub = ref.read(nearbyMarkersProvider(currentLatLng).stream).listen((markers) {
        state = state.copyWith(markers: markers);
      });

      // 4. Update state with initial location
      state = state.copyWith(
        currentLatLng: currentLatLng,
        loading: false,
      );

      // 5. Listen to location changes
      _location.changeSettings(
          accuracy: LocationAccuracy.navigation,
          interval: 2000,   // 2 seconds
          distanceFilter: 1
      );

      _locationSub = _location.onLocationChanged.map((loc) {
        return LatLng(loc.latitude!, loc.longitude!);
      }).listen((latLng) {
        state = state.copyWith(currentLatLng: latLng);
      });
    } catch (e) {
      state = state.copyWith(error: e.toString(), loading: false);
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _markerSub?.cancel();
    super.dispose();
  }
}

// Provider
final homeStateProvider =
StateNotifierProvider<HomeNotifier, HomeState>((ref) => HomeNotifier(ref));
