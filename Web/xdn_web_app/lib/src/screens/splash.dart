import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xdn_web_app/globals.dart' as globals;
import 'package:xdn_web_app/src/controllers/sign_in_controller.dart';
import 'package:xdn_web_app/src/models/AppUser.dart';
import 'package:xdn_web_app/src/net_interface/interface.dart';
import 'package:xdn_web_app/src/screens/home_screen.dart';
import 'package:xdn_web_app/src/support/app_router.dart';
import 'package:xdn_web_app/src/support/app_sizes.dart';
import 'package:xdn_web_app/src/support/auth_repo.dart';
import 'package:xdn_web_app/src/support/extensions.dart';
import 'package:xdn_web_app/src/support/s_p.dart';
import 'package:xdn_web_app/src/support/secure_storage.dart';
import 'package:xdn_web_app/src/widgets/alert_dialogs.dart';
import 'package:xdn_web_app/src/widgets/background_widget.dart';
import 'package:xdn_web_app/src/widgets/primary_button.dart';
import 'package:xdn_web_app/src/widgets/responsible_center.dart';
import 'package:xdn_web_app/src/widgets/responsive_scrollable_card.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _node = FocusScopeNode();

  String get email => _emailController.text;

  String get password => _passwordController.text;

  var _submitted = false;
  var _qrcancelled = false;

  @override
  void initState() {
    super.initState();
    isLoggedIn();
  }

  isLoggedIn() async {
    var auth = ref.read(authRepositoryProvider);
    auth.checkIfLoggedIn();
  }

  @override
  void dispose() {
    // * TextEditingControllers should be always disposed
    _node.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(EmailPasswordSignInState state) async {
    setState(() => _submitted = true);
    // only submit the form if validation passes
    if (_formKey.currentState!.validate()) {
      final controller = ref.read(emailPasswordSignInControllerProvider(EmailPasswordSignInFormType.signIn).notifier);
      final success = await controller.submit(email, password);
      if (success) {
        if (mounted) context.goNamed(AppRoute.home.name);
        // widget.onSignedIn?.call();
      }
    }
  }

  Future<void> _submitQR(EmailPasswordSignInState state) async {
    setState(() => _submitted = true);
    bool? s;
    _qrcancelled = false;
    final netw = ref.read(networkProvider);
    var res = await netw.get("/login/qr", serverType: ComInterface.serverGoAPI, debug: true);
    _checkLogin(res['token']);
    if (mounted) {
      s = await showQRAlertDialog(context: context, title: "QR code login", content: res["token"]);
    }

    if (s == null || s == false) {
      _qrcancelled = true;
    }
  }

  void _checkLogin(String qr) async {
    final netw = ref.read(networkProvider);
    final rauth = ref.read(authRepositoryProvider);
    String? token;
    await Future.doWhile(() async {
      try {
        if (_qrcancelled) {
          return false;
        }
        await Future.delayed(const Duration(seconds: 1));
        Map<String, dynamic>? res = await netw.post("/login/qr/token", body: {"token": qr}, serverType: ComInterface.serverGoAPI, debug: true);
        if (res != null && res["token"] != null) {
          token = res["token"];
          await SecureStorage.write(key: globals.TOKEN_DAO, value: res["token"]);
          await SecureStorage.write(key: globals.TOKEN_REFRESH, value: res["refresh_token"]);
          await SecureStorage.write(key: globals.ADMINPRIV, value: res["admin"].toString());
          rauth.currentUser = AppUser (uid: "asdf", email: "adf@dsf.com", admin: res["admin"] == 1 ? true : false);
          return false;
        } else {
          return true;
        }
      } catch (e) {
        return true;
      }
    });
    if (_qrcancelled) {
      _qrcancelled = false;
      return;
    }
    if (token != null) {
      if (mounted) context.pop();

      if (mounted) {
        Navigator.of(context).push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) {
        return const HomeScreen();
      }, transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
        return FadeTransition(opacity: animation, child: child);
      }));
      }
    } else {
      if (mounted) showAlertDialog(context: context, title: "QR code login", content: "QR code login failed");
    }
  }

  void _emailEditingComplete(EmailPasswordSignInState state) {
    if (state.canSubmitEmail(email)) {
      _node.nextFocus();
    }
  }

  void _passwordEditingComplete(EmailPasswordSignInState state) {
    if (!state.canSubmitEmail(email)) {
      _node.previousFocus();
      return;
    }
    _submit(state);
  }

  void _updateFormType(EmailPasswordSignInFormType formType) {
    // * Toggle between register and sign in form
    ref.read(emailPasswordSignInControllerProvider(EmailPasswordSignInFormType.signIn).notifier).updateFormType(formType);
    // * Clear the password field when doing so
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue>(
      emailPasswordSignInControllerProvider(EmailPasswordSignInFormType.signIn).select((state) => state.value),
      (_, state) => state.showAlertDialogOnError(context),
    );
    final state = ref.watch(emailPasswordSignInControllerProvider(EmailPasswordSignInFormType.signIn));
    return Stack(
      children: [
        const BackgroundWidget(
          mainMenu: true,
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: ResponsiveCenter(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ResponsiveScrollableCard(
                  child: FocusScope(
                    node: _node,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          gapH8,
                          // Email field
                          TextFormField(
                            // key: EmailPasswordSignInScreen.emailKey,
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Username'.hardcoded,
                              hintText: 'Username from XDN app'.hardcoded,
                              enabled: !state.isLoading,
                            ),
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            validator: (email) => !_submitted ? null : state.emailErrorText(email ?? ''),
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.name,
                            keyboardAppearance: Brightness.light,
                            onEditingComplete: () => _emailEditingComplete(state),
                          ),
                          gapH8,
                          // Password field
                          TextFormField(
                            // key: EmailPasswordSignInScreen.passwordKey,
                            controller: _passwordController,
                            decoration: InputDecoration(
                              hintText: "Password from XDN app".hardcoded,
                              labelText: state.passwordLabelText,
                              enabled: !state.isLoading,
                            ),
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            validator: (password) => !_submitted ? null : state.passwordErrorText(password ?? ''),
                            obscureText: true,
                            autocorrect: false,
                            textInputAction: TextInputAction.done,
                            keyboardAppearance: Brightness.light,
                            onEditingComplete: () => _passwordEditingComplete(state),
                          ),
                          gapH24,
                          PrimaryButton(
                            text: state.primaryButtonText,
                            isLoading: state.isLoading,
                            onPressed: state.isLoading ? null : () => _submit(state),
                          ),
                          gapH8,
                          PrimaryButton(
                            text: "Login via QR code".hardcoded,
                            isLoading: state.isLoading,
                            onPressed: state.isLoading ? null : () => _submitQR(state),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
