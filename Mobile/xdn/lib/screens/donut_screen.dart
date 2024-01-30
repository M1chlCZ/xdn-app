import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class DonutScreen extends StatelessWidget {
  static const route = "home/donut";
  const DonutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: ModelViewer(
        src: 'assets/Donut.glb',
        alt: "A 3D model of an donut",
        ar: true,
        autoRotate: true,
        cameraControls: true,
      ),
    );
  }
}
