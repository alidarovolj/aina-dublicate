import 'package:flutter/material.dart';

// Global navigator key for accessing navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global route observer for navigation events
final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();
