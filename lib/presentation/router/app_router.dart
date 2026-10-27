// Configuración de enrutamiento de la aplicación PrediGeo
// usando GoRouter con las pantallas principales.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/measure_screen.dart';
import '../screens/history_screen.dart';
import '../screens/evaluation_screen.dart';
import '../screens/gps_debug_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return _buildPage(state, const HomeScreen());
      },
    ),
    GoRoute(
      path: '/measure',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return _buildPage(state, const MeasureScreen());
      },
    ),
    GoRoute(
      path: '/history',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return _buildPage(state, const HistoryScreen());
      },
    ),
    GoRoute(
      path: '/evaluation',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return _buildPage(state, const EvaluationScreen());
      },
    ),
    GoRoute(
      path: '/gps-debug',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return _buildPage(state, const GpsDebugScreen());
      },
    ),
  ],
  redirect: (BuildContext context, GoRouterState state) {
    return null;
  },
);

CustomTransitionPage<void> _buildPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.02, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}
