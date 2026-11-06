import 'dart:math' as math;

import 'package:flutter/material.dart';

const shirtColors = [
  Color(0xffefaf46),
  Color(0xff4bbed0),
  Color(0xffdd657b),
  Color(0xff957bdd),
];
const skinColors = [Color(0xffffd5ae), Color(0xffcf976a), Color(0xff865740)];
void pixel(Canvas c, double x, double y, double w, double h, int color) =>
    c.drawRect(
      Rect.fromLTWH(x, y, w, h),
      Paint()
        ..color = Color(color)
        ..isAntiAlias = false,
    );
void tinyText(
  Canvas c,
  String text,
  double x,
  double y, {
  double size = 6,
  Color color = const Color(0xfffaf0d1),
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: size,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(c, Offset(x - painter.width / 2, y));
}

/// Original code-native 16x24 sprite, drawn on a fixed pixel grid.
void drawPerson(
  Canvas c, {
  int shirt = 0,
  int skin = 1,
  int hair = 0,
  int accessory = 0,
  int direction = 0,
  double phase = 0,
  bool moving = false,
}) {
  c.save();
  c.drawOval(
    const Rect.fromLTWH(-7, -3, 14, 5),
    Paint()..color = const Color(0x400c2639),
  );
  final step = moving ? math.sin(phase * 12).sign * 1.0 : 0.0;
  pixel(c, -5, -8, 4, 7 + step, 0xff304365);
  pixel(c, 1, -8, 4, 7 - step, 0xff304365);
  pixel(c, -6, -2 + step, 5, 2, 0xff222b42);
  pixel(c, 1, -2 - step, 5, 2, 0xff222b42);
  pixel(c, -6, -15, 12, 9, 0xff26344b);
  pixel(c, -5, -15, 10, 8, shirtColors[shirt % 4].toARGB32());
  pixel(c, -5, -9, 10, 2, 0xffbb793e);
  pixel(c, -8, -14, 3, 7, skinColors[skin % 3].toARGB32());
  pixel(c, 5, -14, 3, 7, skinColors[skin % 3].toARGB32());
  pixel(c, -5, -23, 10, 10, 0xff343343);
  pixel(c, -5, -21, 10, 7, skinColors[skin % 3].toARGB32());
  final hc = hair == 1
      ? 0xffa35834
      : hair == 2
      ? 0xffe0c291
      : 0xff3d3040;
  pixel(c, -5, -24, 10, 4, hc);
  pixel(c, -6, -22, 2, hair == 2 ? 10 : 5, hc);
  if (direction == 2) {
    pixel(c, -5, -22, 10, 8, hc);
  } else if (direction == 1) {
    pixel(c, -4, -19, 2, 2, 0xff202e46);
  } else if (direction == 3) {
    pixel(c, 3, -19, 2, 2, 0xff202e46);
  } else {
    pixel(c, -3, -19, 2, 2, 0xff202e46);
    pixel(c, 2, -19, 2, 2, 0xff202e46);
    pixel(c, -1, -15, 3, 1, 0xff9c5b45);
  }
  if (accessory == 1) {
    pixel(c, -7, -24, 14, 3, 0xfff5d47a);
    pixel(c, -4, -27, 8, 4, 0xffe3b45b);
  }
  c.restore();
}

class PersonPreview extends CustomPainter {
  final int shirt, skin, hair, accessory;
  PersonPreview(this.shirt, this.skin, this.hair, this.accessory);
  @override
  void paint(Canvas c, Size size) {
    c.translate(size.width / 2, size.height * .83);
    c.scale(size.height / 36);
    drawPerson(c, shirt: shirt, skin: skin, hair: hair, accessory: accessory);
  }

  @override
  bool shouldRepaint(covariant PersonPreview old) => true;
}
