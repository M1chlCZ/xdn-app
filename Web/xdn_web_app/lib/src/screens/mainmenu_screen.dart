import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xdn_web_app/src/support/app_router.dart';
import 'package:xdn_web_app/src/widgets/background_widget.dart';
import 'package:xdn_web_app/src/widgets/flat_custom_btn.dart';
import 'package:xdn_web_app/src/widgets/permission_provider.dart';
import 'package:xdn_web_app/src/widgets/responsible_center.dart';

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perm = ref.watch(permissionProvider);
    return MaterialApp(
      title: 'My App',
      home: Stack(
        children: [
          const BackgroundWidget(
            mainMenu: false,
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: perm.when(
              data: (data) {
                return SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ResponsiveCenter(
                          child: GridView.count(
                            shrinkWrap: true,
                            mainAxisSpacing: 16.0,
                            crossAxisSpacing: 16.0,
                            crossAxisCount: _getCrossAxisCount(context),
                            padding: const EdgeInsets.all(16.0),
                            children: [
                              if (data['admin'] || data['mn'])
                                _buildMenuItem(
                                  context,
                                  title: 'Masternode',
                                  icon: Icons.link,
                                  onTap: () {
                                    context.goNamed(AppRoute.masternode.name);
                                  },
                                ),
                              _buildMenuItem(
                                context,
                                title: 'Wallet',
                                icon: Icons.account_balance_wallet,
                                onTap: () {
                                  context.goNamed(AppRoute.wallet.name);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 1.5,color: Colors.white70,),
              ),
              error: (e, s) => const Center(
                child: Text('Error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.blueAccent,
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: FlatCustomButton(
        radius: 8.0,
        splashColor: Colors.pink,
        onTap: onTap,
        getHover: (isHover) {
          Color c = isHover ? Colors.white70 : Colors.black54;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48.0,
                color: c,
              ),
              const SizedBox(height: 16.0),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: c,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 768) {
      return 2;
    } else if (screenWidth > 480) {
      return 2;
    } else {
      return 1;
    }
  }
}
