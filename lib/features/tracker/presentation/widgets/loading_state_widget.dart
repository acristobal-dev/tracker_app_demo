import 'package:flutter/material.dart';

class LoadingStateWidget extends StatelessWidget {
  const LoadingStateWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(
            color: Color(0xFF00D46A),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando ubicaciones...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
