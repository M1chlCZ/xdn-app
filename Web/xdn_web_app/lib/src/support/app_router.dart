import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xdn_web_app/src/screens/admin_panel.dart';
import 'package:xdn_web_app/src/screens/home_screen.dart';
import 'package:xdn_web_app/src/screens/mainmenu_screen.dart';
import 'package:xdn_web_app/src/screens/not_found.dart';
import 'package:xdn_web_app/src/screens/splash.dart';
import 'package:xdn_web_app/src/screens/web_wallet_screen.dart';
import 'package:xdn_web_app/src/support/auth_repo.dart';
import 'package:xdn_web_app/src/support/go_router_refresh_stream.dart';

enum AppRoute {
  home,
  splash,
  masternode,
  wallet,
  admin,
  account,
  signIn,
}

CustomTransitionPage buildPageWithDefaultTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authRepository.currentUser != null;
      final isAdmin = authRepository.currentUser?.admin ?? false;
      if (isLoggedIn) {
        if (state.location == '/') {
          return '/home';
        }
      } else {
        if (state.location == '/home/admin' && !isAdmin) {
          if (isLoggedIn) {
            return '/home';
          } else {
            return '/';
          }
        }
        if (state.location == '/home' || state.location == '/orders') {
          return '/';
        }
      }
      return null;
    },
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges()),
    routes: [
      GoRoute(
        path: '/',
        name: AppRoute.splash.name,
        builder: (context, state) => const SplashScreen(),
        pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
          context: context,
          state: state,
          child: const SplashScreen(),
        ),
        routes: [
          // GoRoute(
          //   path: 'product/:id',
          //   name: AppRoute.product.name,
          //   builder: (context, state) {
          //     final productId = state.params['id']!;
          //     return ProductScreen(productId: productId);
          //   },
          //   routes: [
          //     GoRoute(
          //       path: 'review',
          //       name: AppRoute.leaveReview.name,
          //       pageBuilder: (context, state) {
          //         final productId = state.params['id']!;
          //         return MaterialPage(
          //           key: state.pageKey,
          //           fullscreenDialog: true,
          //           child: LeaveReviewScreen(productId: productId),
          //         );
          //       },
          //     ),
          //   ],
          // ),
          // GoRoute(
          //   path: 'cart',
          //   name: AppRoute.cart.name,
          //   pageBuilder: (context, state) => MaterialPage(
          //     key: state.pageKey,
          //     fullscreenDialog: true,
          //     child: const ShoppingCartScreen(),
          //   ),
          //   routes: [
          //     GoRoute(
          //       path: 'checkout',
          //       name: AppRoute.checkout.name,
          //       pageBuilder: (context, state) => MaterialPage(
          //         key: ValueKey(state.location),
          //         fullscreenDialog: true,
          //         child: const CheckoutScreen(),
          //       ),
          //     ),
          //   ],
          // ),
          // GoRoute(
          //   path: 'orders',
          //   name: AppRoute.orders.name,
          //   pageBuilder: (context, state) => MaterialPage(
          //     key: state.pageKey,
          //     fullscreenDialog: true,
          //     child: const OrdersListScreen(),
          //   ),
          // ),
          GoRoute(
            path: 'home',
            name: AppRoute.home.name,
            builder: (context, state) => const MainMenuScreen(),
            pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
              context: context,
              state: state,
              child: const MainMenuScreen(),
            ),
            routes: [
              GoRoute(
                path: 'masternode',
                name: AppRoute.masternode.name,
                builder: (context, state) => const HomeScreen(),
                pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
                  context: context,
                  state: state,
                  child: const HomeScreen(),
                ),),
              GoRoute(
                path: 'wallet',
                name: AppRoute.wallet.name,
                builder: (context, state) => const WebWalletScreen(),
                pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
                  context: context,
                  state: state,
                  child: const WebWalletScreen(),
                ),),
              GoRoute(
                path: 'admin',
                name: AppRoute.admin.name,
                pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
                  context: context,
                  state: state,
                  child: const AdminScreen(),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'account',
            name: AppRoute.account.name,
            builder: (context, state) => const AdminScreen(),
            pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
              context: context,
              state: state,
              child: const AdminScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});
