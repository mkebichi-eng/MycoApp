import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_constants.dart';
import '../providers/app_providers.dart';
import 'bag_detail_dialog.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _manualInputController = TextEditingController();
  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeDetected(String code) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final bag = await ref.read(productionRepositoryProvider).findBagByQrCode(code);

    if (mounted) {
      if (bag != null) {
        await showDialog(
          context: context,
          builder: (ctx) => BagDetailDialog(bag: bag),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sac introuvable pour le code : $code'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner Sac de Culture'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            tooltip: 'Allumer la torche (salle sombre)',
            onPressed: () {
              _scannerController.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Caméra mobile scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final rawValue = barcode.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  _handleBarcodeDetected(rawValue);
                  break;
                }
              }
            },
          ),

          // Viseur graphique central
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // En-tête informatif
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Pointez la caméra vers l\'étiquette QR code du sac',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),

          // Champ de saisie manuelle de secours en bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Code abîmé ou illisible ? Saisie manuelle :',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualInputController,
                          decoration: const InputDecoration(
                            hintText: 'ex: MYCO-BAG-0004',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onPressed: () {
                          if (_manualInputController.text.isNotEmpty) {
                            _handleBarcodeDetected(_manualInputController.text.trim());
                          }
                        },
                        child: const Text('Valider'),
                      ),
                    ],
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
