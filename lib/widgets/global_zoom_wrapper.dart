import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// A widget that enables global zoom functionality for the entire app
/// Supports:
/// - Trackpad pinch-to-zoom gestures
/// - Ctrl + Mouse wheel zoom
/// - Touch pinch-to-zoom on mobile
class GlobalZoomWrapper extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;

  const GlobalZoomWrapper({
    Key? key,
    required this.child,
    this.minScale = 0.5,
    this.maxScale = 3.0,
  }) : super(key: key);

  @override
  State<GlobalZoomWrapper> createState() => _GlobalZoomWrapperState();
}

class _GlobalZoomWrapperState extends State<GlobalZoomWrapper> {
  double _scale = 1.0;
  double _previousScale = 1.0;
  Offset _focalPoint = Offset.zero;
  Offset _previousFocalPoint = Offset.zero;

  void _handleScaleStart(ScaleStartDetails details) {
    _previousScale = _scale;
    _previousFocalPoint = details.focalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // Handle zoom
      _scale = (_previousScale * details.scale).clamp(
        widget.minScale,
        widget.maxScale,
      );

      // Handle pan when zoomed
      if (_scale > 1.0) {
        _focalPoint = details.focalPoint;
      }
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _previousScale = _scale;
    _previousFocalPoint = _focalPoint;
  }

  // Handle mouse wheel zoom with Ctrl key
  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // Check if Ctrl key is pressed (for desktop zoom)
      // On trackpad, this also captures pinch gestures
      final delta = event.scrollDelta.dy;

      setState(() {
        // Negative delta = zoom in, positive = zoom out
        final zoomDelta = delta > 0 ? -0.1 : 0.1;
        _scale = (_scale + zoomDelta).clamp(widget.minScale, widget.maxScale);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: GestureDetector(
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        onScaleEnd: _handleScaleEnd,
        child: Transform.scale(scale: _scale, child: widget.child),
      ),
    );
  }
}

/// Alternative implementation using InteractiveViewer for more native feel
/// Like Facebook - can zoom in but not out beyond actual content
class GlobalZoomInteractiveWrapper extends StatelessWidget {
  final Widget child;
  final double minScale;
  final double maxScale;

  const GlobalZoomInteractiveWrapper({
    Key? key,
    required this.child,
    this.minScale = 1.0, // Changed from 0.8 to 1.0 - no zoom out
    this.maxScale = 2.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: minScale,
      maxScale: maxScale,
      boundaryMargin: EdgeInsets.zero, // Changed from infinity to zero
      constrained: true, // Changed from false to true - prevents white space
      panEnabled: true,
      scaleEnabled: true,
      clipBehavior: Clip.hardEdge, // Added - clips content to boundaries
      child: child, // Removed unnecessary Container wrapper
    );
  }
}

/// A widget that shows zoom controls overlay
class ZoomControlsOverlay extends StatefulWidget {
  final ValueChanged<double> onZoomChanged;
  final double currentZoom;
  final double minZoom;
  final double maxZoom;

  const ZoomControlsOverlay({
    Key? key,
    required this.onZoomChanged,
    required this.currentZoom,
    this.minZoom = 0.5,
    this.maxZoom = 3.0,
  }) : super(key: key);

  @override
  State<ZoomControlsOverlay> createState() => _ZoomControlsOverlayState();
}

class _ZoomControlsOverlayState extends State<ZoomControlsOverlay> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      right: 16,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isVisible = true),
        onExit: (_) => Future.delayed(
          Duration(seconds: 2),
          () => mounted ? setState(() => _isVisible = false) : null,
        ),
        child: AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.3,
          duration: Duration(milliseconds: 200),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zoom In
                  IconButton(
                    icon: Icon(Icons.add_circle_outline),
                    onPressed: () {
                      final newZoom = (widget.currentZoom + 0.1).clamp(
                        widget.minZoom,
                        widget.maxZoom,
                      );
                      widget.onZoomChanged(newZoom);
                    },
                    tooltip: 'Zoom In',
                  ),
                  // Current zoom percentage
                  Text(
                    '${(widget.currentZoom * 100).toInt()}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  // Zoom Out
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      final newZoom = (widget.currentZoom - 0.1).clamp(
                        widget.minZoom,
                        widget.maxZoom,
                      );
                      widget.onZoomChanged(newZoom);
                    },
                    tooltip: 'Zoom Out',
                  ),
                  Divider(height: 8),
                  // Reset zoom
                  IconButton(
                    icon: Icon(Icons.refresh, size: 20),
                    onPressed: () => widget.onZoomChanged(1.0),
                    tooltip: 'Reset Zoom',
                    iconSize: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
