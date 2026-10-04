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
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/measure',
      builder: (BuildContext context, GoRouterState state) {
        return const MeasureScreen();
      },
    ),
    GoRoute(
      path: '/history',
      builder: (BuildContext context, GoRouterState state) {
        return const HistoryScreen();
      },
    ),
    GoRoute(
      path: '/evaluation',
      builder: (BuildContext context, GoRouterState state) {
        return const EvaluationScreen();
      },
    ),
    GoRoute(
      path: '/gps-debug',
      builder: (BuildContext context, GoRouterState state) {
        return const GpsDebugScreen();
      },
    ),
  ],
  redirect: (BuildContext context, GoRouterState state) {
    return null;
  },
);
