import 'dart:js_interop';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

@JS('_initFlutterMap')
external void _jsInitMap(String viewId, double lat, double lng);

@JS('_updateFlutterMap')
external void _jsUpdateMap(String viewId, double lat, double lng);

@JS('google')
external JSObject? get _googleJs;

class GoogleMapWidget extends StatefulWidget {
  final double lat;
  final double lng;
  final double height;

  const GoogleMapWidget({
    super.key,
    required this.lat,
    required this.lng,
    this.height = 240,
  });

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'flutter-map-${DateTime.now().microsecondsSinceEpoch}';
    ui.platformViewRegistry.registerViewFactory(_viewId, (int id) {
      final div = web.document.createElement('div') as web.HTMLDivElement;
      div.id = _viewId;
      div.style.width = '100%';
      div.style.height = '100%';
      Future.delayed(const Duration(milliseconds: 300), () {
        try {
          _jsInitMap(_viewId, widget.lat, widget.lng);
        } catch (_) {}
      });
      return div;
    });
  }

  @override
  void didUpdateWidget(GoogleMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat || oldWidget.lng != widget.lng) {
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          _jsUpdateMap(_viewId, widget.lat, widget.lng);
        } catch (_) {}
      });
    }
  }

  bool get _mapsAvailable {
    try {
      return _googleJs != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_mapsAvailable) {
      return _StaticMapFallback(
          lat: widget.lat, lng: widget.lng, height: widget.height);
    }

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: HtmlElementView(viewType: _viewId),
      ),
    );
  }
}

class _StaticMapFallback extends StatelessWidget {
  final double lat;
  final double lng;
  final double height;

  const _StaticMapFallback({
    required this.lat,
    required this.lng,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final url =
        'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=16&size=640x320&markers=color:red%7C$lat,$lng&key=AIzaSyBUxNIZ4yXZZA752jhoEXLI0vBbXZwaaw0';
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => Container(
            height: height,
            color: const Color(0xFFF7F8FA),
            child: const Center(
              child: Icon(Icons.map_outlined, size: 40, color: Color(0xFFA5A8B5)),
            ),
          ),
        ),
      ),
    );
  }
}
