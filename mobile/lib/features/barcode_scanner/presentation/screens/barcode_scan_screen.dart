import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_theme.dart';
import 'food_result_screen.dart';

/// Full-screen barcode scanner powered by [MobileScanner].
///
/// On successful detection the barcode value is passed to
/// [FoodResultScreen] for API lookup and display.
class BarcodeScanScreen extends ConsumerStatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  ConsumerState<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends ConsumerState<BarcodeScanScreen> {
  late final MobileScannerController _controller;
  StreamSubscription<BarcodeCapture>? _subscription;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _subscription = _controller.barcodes.listen(_onBarcodeDetected);
    _controller.start();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasNavigated) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _hasNavigated = true);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => FoodResultScreen(barcode: rawValue),
      ),
    );
  }

  void _toggleFlash() {
    _controller.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera viewfinder
          MobileScanner(controller: _controller),

          // Semi-transparent overlay with cutout
          const _ScannerOverlay(),

          // Instruction text
          const Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Text(
              'Point the camera at a barcode',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Top bar with cancel & flash
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ActionButton(
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (_, __) {
                      final bool isOn =
                          _controller.value.torchState == TorchState.on;
                      return _ActionButton(
                        icon: isOn ? Icons.flash_on : Icons.flash_off,
                        onPressed: _toggleFlash,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular icon button used in the scanner overlay.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

/// Paints a semi-transparent overlay with a transparent rectangle in the
/// centre so the user knows where to aim the barcode.
class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _OverlayPainter(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cutoutWidth = size.width * 0.75;
    final double cutoutHeight = cutoutWidth * 0.55;
    final double left = (size.width - cutoutWidth) / 2;
    final double top = (size.height - cutoutHeight) / 2 - 40;

    final cutout = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, cutoutWidth, cutoutHeight),
      const Radius.circular(16),
    );

    // Dark overlay
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(cutout)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlayPaint);

    // Border around the cutout
    final borderPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(cutout, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
