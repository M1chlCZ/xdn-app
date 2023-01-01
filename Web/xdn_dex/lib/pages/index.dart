import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xdn_dex/router/route_utils.dart';
import 'package:xdn_dex/services/app_services.dart';

class IndexPage extends StatelessWidget {
  const IndexPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.red);
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  AppService? _appService;
  @override
  void initState() {
    super.initState();
    _appService = Provider.of<AppService>(context);
  }

  login() {
    _appService!.loginState = true;
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
        body: Container(
            color: Colors.blue,
            child: Center(
              child: TextButton(
                onPressed: () {
                  login();
                },
                child: Container(color: Colors.red,child: const Text("Done")),
              ),
            )));
  }
}

class OnBoardingPage extends StatelessWidget {
  const OnBoardingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appService = Provider.of<AppService>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(APP_PAGE.onBoarding.toTitle),
      ),
      body: Center(
        child: TextButton(
          onPressed: () {
            appService.onboarding = true;
          },
          child: const Text("Done"),
        ),
      ),
    );
  }
}
