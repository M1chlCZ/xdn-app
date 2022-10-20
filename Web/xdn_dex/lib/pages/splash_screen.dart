import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xdn_dex/router/route_utils.dart';
import 'package:xdn_dex/services/app_services.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({ Key? key }) : super(key: key);

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  late AppService _appService;

  @override
  void initState() {
    _appService = Provider.of<AppService>(context, listen: false);
    onStartUp();
    super.initState();
  }

  void onStartUp() async {
    await _appService.onAppStart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(APP_PAGE.splash.toTitle),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}