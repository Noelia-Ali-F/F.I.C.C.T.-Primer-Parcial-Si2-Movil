import 'package:flutter/material.dart';

import '../app_routes.dart';

Future<void> showLogoutDialog(BuildContext context) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Cierre de sesión'),
        content: const Text('¿Desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      );
    },
  );

  if (shouldLogout == true && context.mounted) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }
}
