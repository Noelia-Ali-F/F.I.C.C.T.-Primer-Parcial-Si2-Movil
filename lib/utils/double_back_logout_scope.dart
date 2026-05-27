import 'package:flutter/material.dart';

import '../app_routes.dart';

class DoubleBackLogoutScope extends StatefulWidget {
  const DoubleBackLogoutScope({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<DoubleBackLogoutScope> createState() => _DoubleBackLogoutScopeState();
}

class _DoubleBackLogoutScopeState extends State<DoubleBackLogoutScope> {
  DateTime? _lastBackPressAt;

  void _handleBackPress(bool didPop) {
    if (didPop) {
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    final now = DateTime.now();
    final lastBackPressAt = _lastBackPressAt;

    if (lastBackPressAt != null &&
        now.difference(lastBackPressAt) <= const Duration(seconds: 2)) {
      navigator.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
      return;
    }

    _lastBackPressAt = now;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Presiona nuevamente para cerrar sesión.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: _handleBackPress,
      child: widget.child,
    );
  }
}
