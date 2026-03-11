import 'package:flutter/material.dart';

/// Global navigator key to allow navigation from notification callbacks.
final GlobalKey<NavigatorState> pomopetNavKey = GlobalKey<NavigatorState>();

/// Helper to show a sheet/dialog even when triggered from notifications.
BuildContext? get pomopetContext => pomopetNavKey.currentContext;
