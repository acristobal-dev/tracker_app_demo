import 'package:flutter/material.dart';

class CustomAlertDialog {
  static Future<void> showCustomDialog(
    BuildContext context, {
    required String previousUserName,
    required bool isConnected,
    ValueChanged<String>? onConfirm,
  }) async {
    final TextEditingController _textController = TextEditingController(
      text: previousUserName,
    );

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conectate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Ingresa un usuario para conectar'),
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de usuario',
                  hintText: 'Ingresa tu nombre de usuario',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(isConnected ? 'Desconectar' : 'Conectar'),
              onPressed: () {
                Navigator.of(context).pop();
                if (onConfirm != null) {
                  onConfirm(_textController.text);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
