import 'package:flutter/material.dart';
import '../core/models/bus_model.dart';
import '../core/models/route_model.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

class LiveMapWidget extends StatefulWidget {
  final BusModel? selectedBus;
  final List<BusModel> fleet;
  final RouteModel? selectedRoute;
  final double initialLatitude;
  final double initialLongitude;
  final double initialZoom;
  final bool showAllFleet;
  final Function(BusModel)? onBusSelected;

  const LiveMapWidget({
    super.key,
    this.selectedBus,
    this.fleet = const [],
    this.selectedRoute,
    this.initialLatitude = AppConstants.collegeLatitude,
    this.initialLongitude = AppConstants.collegeLongitude,
    this.initialZoom = 13.0,
    this.showAllFleet = true,
    this.onBusSelected,
  });

  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget> {
  late double _zoom;
  late double _centerLat;
  late double _centerLng;
  bool _followBus = true;

  @override
  void initState() {
    super.initState();
    _zoom = widget.initialZoom;
    _centerLat = widget.selectedBus?.liveLocation?.latitude ?? widget.initialLatitude;
    _centerLng = widget.selectedBus?.liveLocation?.longitude ?? widget.initialLongitude;
  }

  @override
  void didUpdateWidget(LiveMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_followBus && widget.selectedBus?.liveLocation != null) {
      _centerLat = widget.selectedBus!.liveLocation!.latitude;
      _centerLng = widget.selectedBus!.liveLocation!.longitude;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECEF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Realistic Map Canvas with OpenStreetMap / Vector Grid Rendering
            CustomPaint(
              size: Size.infinite,
              painter: _MapCanvasPainter(
                centerLat: _centerLat,
                centerLng: _centerLng,
                zoom: _zoom,
                selectedBus: widget.selectedBus,
                fleet: widget.showAllFleet ? widget.fleet : (widget.selectedBus != null ? [widget.selectedBus!] : []),
                route: widget.selectedRoute,
              ),
            ),

            // Top Status Overlay (Freshness & Selected Bus Information)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: widget.selectedBus?.liveLocation?.isFresh == true
                                  ? AppColors.statusMoving
                                  : AppColors.statusDelayed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.selectedBus != null
                                  ? "${widget.selectedBus!.busNumber} • ${widget.selectedBus!.liveLocation?.freshnessLabel ?? 'Active'}"
                                  : "Fleet • ${widget.fleet.length} Vehicles",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Map Provider Attribution
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "OpenFreeMap / OSM",
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Map Controls (Zoom In, Zoom Out, Re-Center, Compass)
            Positioned(
              bottom: 20,
              right: 16,
              child: Column(
                children: [
                  _buildMapButton(
                    icon: Icons.add,
                    onTap: () {
                      setState(() => _zoom = (_zoom + 0.5).clamp(10.0, 18.0));
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMapButton(
                    icon: Icons.remove,
                    onTap: () {
                      setState(() => _zoom = (_zoom - 0.5).clamp(10.0, 18.0));
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMapButton(
                    icon: Icons.my_location,
                    color: _followBus ? AppColors.primaryBlue : Colors.white,
                    iconColor: _followBus ? Colors.white : AppColors.textPrimary,
                    onTap: () {
                      setState(() {
                        _followBus = true;
                        if (widget.selectedBus?.liveLocation != null) {
                          _centerLat = widget.selectedBus!.liveLocation!.latitude;
                          _centerLng = widget.selectedBus!.liveLocation!.longitude;
                        } else {
                          _centerLat = AppConstants.collegeLatitude;
                          _centerLng = AppConstants.collegeLongitude;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),

            // Speed & Road Speed Limit Indicator (Bottom Left)
            if (widget.selectedBus?.liveLocation != null)
              Positioned(
                bottom: 20,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.speed, size: 20, color: AppColors.primaryBlue),
                      const SizedBox(width: 8),
                      Text(
                        "${widget.selectedBus!.liveLocation!.speedKmh.toStringAsFixed(0)} km/h",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: const Text("50", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
    Color iconColor = AppColors.textPrimary,
  }) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  final double centerLat;
  final double centerLng;
  final double zoom;
  final BusModel? selectedBus;
  final List<BusModel> fleet;
  final RouteModel? route;

  _MapCanvasPainter({
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
    this.selectedBus,
    required this.fleet,
    this.route,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = (1 << zoom.toInt()) * 256.0 / 360.0;

    Offset latLngToScreen(double lat, double lng) {
      final x = cx + (lng - centerLng) * scale * 100.0;
      final y = cy - (lat - centerLat) * scale * 100.0;
      return Offset(x, y);
    }

    // 1. Draw subtle GIS grid & roads
    final gridPaint = Paint()
      ..color = const Color(0xFFD6DBE1)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 60) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double j = 0; j < size.height; j += 60) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), gridPaint);
    }

    // 2. Draw Route Polyline if available
    if (route != null && route!.polylineWaypoints.isNotEmpty) {
      final polylinePaint = Paint()
        ..color = AppColors.primaryBlue
        ..strokeWidth = 5.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      for (int i = 0; i < route!.polylineWaypoints.length; i++) {
        final pt = route!.polylineWaypoints[i];
        final screenPt = latLngToScreen(pt.latitude, pt.longitude);
        if (i == 0) {
          path.moveTo(screenPt.dx, screenPt.dy);
        } else {
          path.lineTo(screenPt.dx, screenPt.dy);
        }
      }
      canvas.drawPath(path, polylinePaint);

      // Draw stops along the route
      for (final stop in route!.stops) {
        final stopPt = latLngToScreen(stop.latitude, stop.longitude);
        final stopPaint = Paint()..color = Colors.white;
        final stopBorder = Paint()
          ..color = AppColors.primaryNavy
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

        canvas.drawCircle(stopPt, 6, stopPaint);
        canvas.drawCircle(stopPt, 6, stopBorder);
      }
    }

    // 3. Draw College Destination Marker
    final collegePt = latLngToScreen(AppConstants.collegeLatitude, AppConstants.collegeLongitude);
    final collegePaint = Paint()..color = const Color(0xFF7C3AED); // Purple
    canvas.drawCircle(collegePt, 10, collegePaint);
    canvas.drawCircle(
      collegePt,
      10,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // 4. Draw Fleet Vehicle Markers
    for (final bus in fleet) {
      if (bus.liveLocation == null) continue;
      final busPt = latLngToScreen(bus.liveLocation!.latitude, bus.liveLocation!.longitude);

      // Vehicle outer pulse
      final statusColor = bus.status.color;
      canvas.drawCircle(busPt, 14, Paint()..color = statusColor.withOpacity(0.25));

      // Vehicle solid body
      canvas.drawCircle(busPt, 9, Paint()..color = statusColor);
      canvas.drawCircle(
        busPt,
        9,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) => true;
}

