import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/app_theme.dart';
import 'add_book_screen.dart';

class IsbnScannerScreen extends StatefulWidget {
  const IsbnScannerScreen({super.key});

  @override
  State<IsbnScannerScreen> createState() => _IsbnScannerScreenState();
}

class _IsbnScannerScreenState extends State<IsbnScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  bool _torchOn = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),)..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null) return;

    final cleaned = rawValue.replaceAll(RegExp(r'[^0-9X]'), '');
    if (cleaned.length != 13 && cleaned.length != 10) return;

    setState(() => _isProcessing = true);
    _scannerController.stop();

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => AddBookScreen(isbn: cleaned),
      ),
    )
        .then((_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _scannerController.start();
      }
    });
  }

  void _toggleTorch() {
    setState(() => _torchOn = !_torchOn);
    _scannerController.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onBarcodeDetected,
          ),

          _ScannerOverlay(pulseAnimation: _pulseAnimation),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  _OverlayIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  // Title
                  Text(
                    'Scan ISBN',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  // Torch button
                  _OverlayIconButton(
                    icon: _torchOn
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded,
                    onTap: _toggleTorch,
                    isActive: _torchOn,
                  ),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isProcessing)
                      const CircularProgressIndicator(
                        color: AppTheme.primary,
                        strokeWidth: 2.5,
                      )
                    else ...[
                      const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white54,
                        size: 22,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Point the camera at the barcode\non the back of the book',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddBookScreen(isbn: null),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined,
                          size: 16, color: AppTheme.primary),
                      label: const Text(
                        'Enter ISBN manually',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  final Animation<double> pulseAnimation;

  const _ScannerOverlay({required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cutoutSize = size.width * 0.72;

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, _) {
        return CustomPaint(
          size: Size(size.width, size.height),
          painter: _OverlayPainter(
            cutoutSize: cutoutSize * pulseAnimation.value,
            cornerRadius: 16,
          ),
        );
      },
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double cutoutSize;
  final double cornerRadius;

  _OverlayPainter({required this.cutoutSize, required this.cornerRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.62);

    final cutoutRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2 - 40),
        width: cutoutSize,
        height: cutoutSize * 0.55,
      ),
      Radius.circular(cornerRadius),
    );

    // Draw overlay excluding the cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(cutoutRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw corner brackets
    final bracketPaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = cutoutRect.outerRect;
    const bracketLen = 22.0;
    final r = cornerRadius;

    // Top-left
    canvas.drawLine(Offset(rect.left + r, rect.top),
        Offset(rect.left + r + bracketLen, rect.top), bracketPaint);
    canvas.drawLine(Offset(rect.left, rect.top + r),
        Offset(rect.left, rect.top + r + bracketLen), bracketPaint);
    // Top-right
    canvas.drawLine(Offset(rect.right - r, rect.top),
        Offset(rect.right - r - bracketLen, rect.top), bracketPaint);
    canvas.drawLine(Offset(rect.right, rect.top + r),
        Offset(rect.right, rect.top + r + bracketLen), bracketPaint);
    // Bottom-left
    canvas.drawLine(Offset(rect.left + r, rect.bottom),
        Offset(rect.left + r + bracketLen, rect.bottom), bracketPaint);
    canvas.drawLine(Offset(rect.left, rect.bottom - r),
        Offset(rect.left, rect.bottom - r - bracketLen), bracketPaint);
    // Bottom-right
    canvas.drawLine(Offset(rect.right - r, rect.bottom),
        Offset(rect.right - r - bracketLen, rect.bottom), bracketPaint);
    canvas.drawLine(Offset(rect.right, rect.bottom - r),
        Offset(rect.right, rect.bottom - r - bracketLen), bracketPaint);
  }

  @override
  bool shouldRepaint(_OverlayPainter oldDelegate) =>
      oldDelegate.cutoutSize != cutoutSize;
}

class _OverlayIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _OverlayIconButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withOpacity(0.2)
              : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppTheme.primary.withOpacity(0.6)
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? AppTheme.primary : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}