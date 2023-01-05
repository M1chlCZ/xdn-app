import 'package:flutter/material.dart';
import 'package:xdn_web_app/src/support/empty_placeholder.dart';
import 'package:xdn_web_app/src/support/extensions.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: EmptyPlaceholderWidget(
        message: '404 - Page not found!'.hardcoded,
      ),
    );
  }
}