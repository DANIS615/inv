import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    formats: [
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.itf,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.pdf417,
    ],
    autoStart: true,
    torchEnabled: false,
    useNewCameraSelector: true,
  );
  bool _hasScanned = false;
  bool _isFlashOn = false;
  CameraFacing _cameraFacing = CameraFacing.back;
  bool _controllerReady = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    
    // Intentar inicializar explícitamente para evitar controllerUninitialized
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await controller.start();
        if (mounted) {
          setState(() => _controllerReady = true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _initError = e.toString());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error inicializando cámara: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard),
            onPressed: _showManualInput,
            tooltip: 'Ingresar Manualmente',
          ),
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: _isFlashOn ? Colors.yellow : Colors.grey,
            ),
            iconSize: 32.0,
            onPressed: !_controllerReady
                ? null
                : () async {
                    try {
                      await controller.toggleTorch();
                      setState(() {
                        _isFlashOn = !_isFlashOn;
                      });
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No se pudo cambiar linterna: $e')),
                      );
                    }
                  },
          ),
          IconButton(
            icon: Icon(
              _cameraFacing == CameraFacing.front 
                ? Icons.camera_front 
                : Icons.camera_rear,
            ),
            iconSize: 32.0,
            onPressed: !_controllerReady
                ? null
                : () async {
                    try {
                      await controller.switchCamera();
                      setState(() {
                        _cameraFacing = _cameraFacing == CameraFacing.front 
                          ? CameraFacing.back 
                          : CameraFacing.front;
                      });
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No se pudo cambiar cámara: $e')),
                      );
                    }
                  },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_initError == null)
            MobileScanner(
              controller: controller,
              onDetect: _onBarcodeDetected,
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Escáner no disponible. Reinicia la app o reinstala en el dispositivo.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          // Overlay con marco de escaneo rectangular
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Theme.of(context).primaryColor,
                borderRadius: 15,
                borderLength: 40,
                borderWidth: 8,
                cutOutWidth: MediaQuery.of(context).size.width * 0.8,
                cutOutHeight: MediaQuery.of(context).size.height * 0.4,
                useRectangle: true,
              ),
            ),
          ),
          // Estado de la cámara
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _controllerReady ? Colors.green.withOpacity(0.9) : Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _controllerReady ? Icons.camera_alt : Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _controllerReady ? 'Cámara Activa - Buscando códigos...' : 'Inicializando cámara...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Instrucciones y botón de prueba
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Coloca el código dentro del marco rectangular',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'También puedes usar el botón ⌨️ para ingresar manualmente',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture barcodeCapture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      final String? code = barcode.rawValue;

      if (code != null && code.isNotEmpty) {
        final cleanCode = code.trim();
        
        // Buscar códigos de 6 dígitos para clientes
        final sixDigitsMatch = RegExp(r'(\d{6})').firstMatch(cleanCode);
        if (sixDigitsMatch != null) {
          final clientCode = sixDigitsMatch.group(1)!;
          _hasScanned = true;
          controller.stop();
          Navigator.of(context).pop(clientCode);
          return;
        }
        
        // Si no es de 6 dígitos, usar el código completo
        _hasScanned = true;
        controller.stop();
        Navigator.of(context).pop(cleanCode);
      }
    }
  }

  void _showManualInput() {
    final TextEditingController codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.keyboard, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(child: Text('Ingresar Código Manualmente')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Si el escáner no funciona, puedes ingresar el código del cliente manualmente:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Código de Cliente (6 dígitos)',
                hintText: '123456',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code_2),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.length == 6 && RegExp(r'^\d{6}$').hasMatch(code)) {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pop(code); // Regresar con código
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor ingresa un código de 6 dígitos'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Usar Código'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// Widget personalizado para el overlay del escáner
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;
  final double cutOutWidth;
  final double cutOutHeight;
  final bool useRectangle;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
    this.cutOutWidth = 300,
    this.cutOutHeight = 200,
    this.useRectangle = false,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final actualCutOutWidth = useRectangle ? cutOutWidth : cutOutSize;
    final actualCutOutHeight = useRectangle ? cutOutHeight : cutOutSize;

    final backgroundPath = Path()
      ..addRect(rect);
    
    if (useRectangle) {
      // Usar rectángulo redondeado para mejor escaneo
      backgroundPath.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: rect.center,
          width: actualCutOutWidth,
          height: actualCutOutHeight,
        ),
        Radius.circular(borderRadius),
      ));
    } else {
      // Mantener óvalo para compatibilidad
      backgroundPath.addOval(Rect.fromCenter(
        center: rect.center,
        width: actualCutOutWidth,
        height: actualCutOutHeight,
      ));
    }
    
    backgroundPath.fillType = PathFillType.evenOdd;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Dibujar las esquinas del marco
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final borderRect = Rect.fromCenter(
      center: rect.center,
      width: actualCutOutWidth,
      height: actualCutOutHeight,
    );

    // Esquina superior izquierda
    canvas.drawPath(
      Path()
        ..moveTo(borderRect.left, borderRect.top + borderLength)
        ..lineTo(borderRect.left, borderRect.top + borderRadius)
        ..quadraticBezierTo(borderRect.left, borderRect.top,
            borderRect.left + borderRadius, borderRect.top)
        ..lineTo(borderRect.left + borderLength, borderRect.top),
      borderPaint,
    );

    // Esquina superior derecha
    canvas.drawPath(
      Path()
        ..moveTo(borderRect.right - borderLength, borderRect.top)
        ..lineTo(borderRect.right - borderRadius, borderRect.top)
        ..quadraticBezierTo(borderRect.right, borderRect.top,
            borderRect.right, borderRect.top + borderRadius)
        ..lineTo(borderRect.right, borderRect.top + borderLength),
      borderPaint,
    );

    // Esquina inferior derecha
    canvas.drawPath(
      Path()
        ..moveTo(borderRect.right, borderRect.bottom - borderLength)
        ..lineTo(borderRect.right, borderRect.bottom - borderRadius)
        ..quadraticBezierTo(borderRect.right, borderRect.bottom,
            borderRect.right - borderRadius, borderRect.bottom)
        ..lineTo(borderRect.right - borderLength, borderRect.bottom),
      borderPaint,
    );

    // Esquina inferior izquierda
    canvas.drawPath(
      Path()
        ..moveTo(borderRect.left + borderLength, borderRect.bottom)
        ..lineTo(borderRect.left + borderRadius, borderRect.bottom)
        ..quadraticBezierTo(borderRect.left, borderRect.bottom,
            borderRect.left, borderRect.bottom - borderRadius)
        ..lineTo(borderRect.left, borderRect.bottom - borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
      borderRadius: borderRadius,
      borderLength: borderLength,
      cutOutSize: cutOutSize,
      cutOutWidth: cutOutWidth,
      cutOutHeight: cutOutHeight,
      useRectangle: useRectangle,
    );
  }
}