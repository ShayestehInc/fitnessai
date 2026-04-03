import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

enum BodyMapView { front, back }

/// Maps muscle slugs to which body view they primarily appear in.
class MuscleViewMapping {
  static const frontMuscles = {
    'quads',
    'hip_flexors',
    'hip_adductors',
    'abs_rectus',
    'obliques',
    'chest',
    'front_delts',
    'side_delts',
    'biceps',
    'forearms_and_grip',
  };
  static const backMuscles = {
    'hamstrings',
    'glutes',
    'calves',
    'hip_abductors',
    'spinal_erectors',
    'lats',
    'mid_back',
    'upper_traps',
    'rear_delts',
    'triceps',
    'deep_core',
  };
}

/// Controller to call JS API methods on the 3D body map.
class BodyMapController {
  InAppWebViewController? _webController;
  bool _isReady = false;

  bool get isReady => _isReady;

  void _attach(InAppWebViewController controller) {
    _webController = controller;
  }

  void _markReady() => _isReady = true;

  void setLayer(String layer) {
    _webController?.evaluateJavascript(source: "setLayer('$layer')");
  }

  void zoomIn() {
    _webController?.evaluateJavascript(source: 'zoomIn()');
  }

  void zoomOut() {
    _webController?.evaluateJavascript(source: 'zoomOut()');
  }

  void resetCamera() {
    _webController?.evaluateJavascript(source: 'resetCamera()');
  }

  void focusOnMuscle(String slug) {
    _webController?.evaluateJavascript(source: "focusOnMuscle('$slug')");
  }

  void setAutoRotate(bool enabled) {
    _webController?.evaluateJavascript(
      source: 'setAutoRotate(${enabled ? "true" : "false"})',
    );
  }
}

class BodyMapWidget extends StatefulWidget {
  final BodyMapView view;
  final Map<String, double> muscleIntensities;
  final Map<String, Color>? highlightedMuscles;
  final ValueChanged<String>? onMuscleTapped;
  final bool interactive;
  final BodyMapController? controller;

  const BodyMapWidget({
    super.key,
    required this.view,
    this.muscleIntensities = const {},
    this.highlightedMuscles,
    this.onMuscleTapped,
    this.interactive = true,
    this.controller,
  });

  @override
  State<BodyMapWidget> createState() => _BodyMapWidgetState();
}

class _BodyMapWidgetState extends State<BodyMapWidget> {
  InAppWebViewController? _webController;
  bool _isReady = false;

  @override
  void didUpdateWidget(BodyMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isReady) return;
    if (oldWidget.muscleIntensities != widget.muscleIntensities) {
      _applyIntensities();
    }
    if (oldWidget.highlightedMuscles != widget.highlightedMuscles) {
      _applyHighlights();
    }
  }

  void _applyIntensities() {
    if (_webController == null || widget.muscleIntensities.isEmpty) return;
    final encoded = jsonEncode(widget.muscleIntensities);
    final escaped = encoded.replaceAll("'", "\\'");
    _webController!.evaluateJavascript(
      source: "setMuscleIntensities('$escaped')",
    );
  }

  void _applyHighlights() {
    if (_webController == null) return;
    _webController!.evaluateJavascript(source: 'clearHighlights()');
    final highlights = widget.highlightedMuscles;
    if (highlights == null) return;
    for (final entry in highlights.entries) {
      final hex =
          '#${entry.value.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
      _webController!.evaluateJavascript(
        source: "highlightMuscle('${entry.key}', '$hex')",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialFile: 'assets/anatomy/anatomy_viewer.html',
      initialSettings: InAppWebViewSettings(
        transparentBackground: true,
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        allowFileAccessFromFileURLs: true,
        allowUniversalAccessFromFileURLs: true,
        disableHorizontalScroll: true,
        disableVerticalScroll: true,
        supportZoom: false,
      ),
      onWebViewCreated: (InAppWebViewController controller) {
        _webController = controller;
        widget.controller?._attach(controller);
        controller.addJavaScriptHandler(
          handlerName: 'onMuscleTapped',
          callback: (List<dynamic> args) {
            if (args.isNotEmpty && widget.onMuscleTapped != null) {
              HapticFeedback.lightImpact();
              widget.onMuscleTapped!(args[0] as String);
            }
            return null;
          },
        );
      },
      onLoadStop: (InAppWebViewController controller, WebUri? url) async {
        setState(() => _isReady = true);
        widget.controller?._markReady();
        _applyIntensities();
        _applyHighlights();
        if (!widget.interactive) {
          _webController?.evaluateJavascript(source: 'setAutoRotate(true)');
        }
      },
    );
  }
}
