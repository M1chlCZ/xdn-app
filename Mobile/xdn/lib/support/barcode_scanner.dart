
import 'package:digitalnote/support/barcode_overlay.dart';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScanner extends StatefulWidget {
  final Function(String) scanResult;
  const BarcodeScanner({Key? key, required this.scanResult}) : super(key: key);

  @override
  BarcodeScannerState createState() => BarcodeScannerState();
}

class BarcodeScannerState extends State<BarcodeScanner> {
  Barcode? result;
  // QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  MobileScannerController? cameraController;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController();
    cameraController!.start();
  } // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.


  @override
  void reassemble() {
    super.reassemble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF2D344E),
            title: Text('Scan QR code', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white70),),
            actions: [
              IconButton(
                color: Colors.white,
                icon: ValueListenableBuilder(
                  valueListenable: cameraController!.torchState,
                  builder: (context, state, child) {
                    switch (state as TorchState) {
                      case TorchState.off:
                        return const Icon(Icons.flash_off, color: Colors.white54);
                      case TorchState.on:
                        return const Icon(Icons.flash_on, color: Colors.white);
                    }
                  },
                ),
                iconSize: 32.0,
                onPressed: () => cameraController!.toggleTorch(),
              ),
              IconButton(
                color: Colors.white,
                icon: ValueListenableBuilder(
                  valueListenable: cameraController!.cameraFacingState,
                  builder: (context, state, child) {
                    switch (state as CameraFacing) {
                      case CameraFacing.front:
                        return Icon(FontAwesomeIcons.cameraRotate, color: Colors.white.withOpacity(0.9),);
                      case CameraFacing.back:
                        return Icon(FontAwesomeIcons.cameraRotate, color: Colors.white.withOpacity(0.9));
                    }
                  },
                ),
                iconSize: 32.0,
                onPressed: () => cameraController!.switchCamera(),
              ),
            ],
          ),
      body: Container(
        color: const Color(0xFF2f2b5e),
        child: Stack(
          children: [
            MobileScanner(
                allowDuplicates: false,
                controller: cameraController,
                onDetect: (barcode, args) {
                  if (barcode.rawValue == null) {
                    debugPrint('Failed to scan Barcode');
                  } else {
                    final String code = barcode.rawValue!;
                    widget.scanResult(code);
                    cameraController!.stop();
                    Navigator.maybePop(context);
                    debugPrint('Barcode found! $code');
                  }
                }),
            Container(
            decoration: ShapeDecoration(
            shape: BarcodeOverlay(
              borderColor: Colors.deepPurple,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 5,
            )),
            ),
            // Column(
            //   children: <Widget>[
            //     Expanded(flex: 7, child: _buildQrView(context)),
            //     Expanded(
            //       flex: 1,
            //       child: FittedBox(
            //         fit: BoxFit.contain,
            //         child: Column(
            //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //           children: <Widget>[
            //             Row(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               crossAxisAlignment: CrossAxisAlignment.center,
            //               children: <Widget>[
            //                 Container(
            //                   margin: const EdgeInsets.all(8),
            //                   child: ElevatedButton(
            //                       onPressed: () async {
            //                         await controller?.toggleFlash();
            //                         setState(() {});
            //                       },
            //                       child: FutureBuilder(
            //                         future: controller?.getFlashStatus(),
            //                         builder: (context, snapshot) {
            //                           return Text('Flash: ${snapshot.data == true ? 'ON' : 'OFF'}');
            //                         },
            //                       )),
            //                 ),
            //                 Container(
            //                   margin: const EdgeInsets.all(8),
            //                   child: ElevatedButton(
            //                       onPressed: () async {
            //                         await controller?.flipCamera();
            //                         setState(() {});
            //                       },
            //                       child: FutureBuilder(
            //                         future: controller?.getCameraInfo(),
            //                         builder: (context, snapshot) {
            //                           if (snapshot.data != null) {
            //                             return Text(
            //                               describeEnum(snapshot.data!) == 'front' ? 'Back Camera' : 'Front Camera'
            //                             );
            //                           } else {
            //                             return const Text('loading');
            //                           }
            //                         },
            //                       )),
            //                 )
            //               ],
            //             ),
            //           ],
            //         ),
            //       ),
            //     )
            //   ],
            // ),
            // const CardHeader(title: '', backArrow: true,),
          ],
        ),
      ),
    );
  }

  // Container(
  // decoration: ShapeDecoration(
  // shape: widget.overlay!,
  // ),

  // Widget _buildQrView(BuildContext context) {
  //   // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
  //   var scanArea = (MediaQuery.of(context).size.width < 400 ||
  //       MediaQuery.of(context).size.height < 400)
  //       ? 250.0
  //       : 400.0;
  //   // To ensure the Scanner view is properly sizes after rotation
  //   // we need to listen for Flutter SizeChanged notification and update controller
  //   return QRView(
  //     key: qrKey,
  //     onQRViewCreated: _onQRViewCreated,
  //     overlay: QrScannerOverlayShape(
  //         borderColor: Colors.deepPurple,
  //         borderRadius: 10,
  //         borderLength: 30,
  //         borderWidth: 5,
  //         cutOutSize: scanArea),
  //     onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
  //   );
  // }
  //
  // void _onQRViewCreated(QRViewController controller) {
  //   setState(() {
  //     this.controller = controller;
  //   });
  //   controller.scannedDataStream.listen((scanData) {
  //     widget.scanResult(scanData.code!);
  //     controller.pauseCamera();
  //     Navigator.of(context).pop();
  //     // setState(() {
  //     //   result = scanData;
  //     // });
  //   });
  // }
  //
  // void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
  //   if (!p) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('no Permission')),
  //     );
  //   }
  // }
  //
  @override
  void dispose() {
    cameraController?.stop();
    cameraController?.dispose();
    super.dispose();
  }
}

