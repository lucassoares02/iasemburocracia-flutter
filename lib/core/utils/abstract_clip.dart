import 'package:flutter/material.dart';

class AbstractClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, 0); // Canto superior esquerdo
    path.lineTo(size.width * 0.8, 0); // Linha reta até a direita
    path.quadraticBezierTo(
      size.width, size.height * 0.4, // Ponto de controle (curva começa)
      size.width * 0.5, size.height, // Ponto final (baixo da direita)
    );
    path.lineTo(0, size.height); // Linha reta de volta para a esquerda
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
