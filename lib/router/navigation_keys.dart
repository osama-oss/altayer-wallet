import 'package:flutter/widgets.dart';

/// Root navigator of the app (attached to GoRouter). Lets non-widget layers
/// (e.g. the session re-auth flow triggered from a Dio interceptor) present
/// UI on top of whatever screen is currently visible.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
