import 'package:flutter/material.dart';

class DisplayErrorMessage extends StatelessWidget {
  const DisplayErrorMessage({Key? key, this.error}) : super(key: key);

  final Object? error;

  @override
  Widget build(BuildContext context) {
    // 'Veuillez vérifier votre connexion : $error'
    return Center(
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20),
        child: const Text(
          'Veuillez vérifier votre connexion, Assurez-vous d\'être connecté(e) à INTERNET !!!',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold
          ),
        ),
      )
    );
  }
}
