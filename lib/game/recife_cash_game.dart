import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/session.dart';
import 'maps/map_data.dart';
import 'pixel_art.dart';

class RecifeCashGame extends FlameGame with KeyboardEvents {
  final GameSession session;
  final void Function(WorldTarget) onInteract;
  final VoidCallback onPause;
  final VoidCallback? onStep;
  final void Function(String)? onMapChanged;
  final ValueNotifier<WorldTarget?> nearby = ValueNotifier(null);
  final Set<LogicalKeyboardKey> keys = {};
  Vector2 touchDirection = Vector2.zero();
  late final HeroComponent hero;
  bool blocked = false;
  double phase = 0, saveClock = 0, stepClock = 0;
  int direction = 0;
  bool walking = false;
  RecifeCashGame(
    this.session,
    this.onInteract,
    this.onPause, {
    this.onStep,
    this.onMapChanged,
  }) : super(
         camera: CameraComponent.withFixedResolution(width: 384, height: 216),
       );
  @override
  Color backgroundColor() => const Color(0xff152e43);
  @override
  Future<void> onLoad() async {
    await world.add(Scenery(this));
    hero = HeroComponent(this)..position.setValues(session.x, session.y);
    await world.add(hero);
    for (final id in ['chico', 'bia', 'clara', 'lucia', 'nando']) {
      await world.add(NpcComponent(this, id));
    }
    centerCamera();
  }

  void clearInput() {
    keys.clear();
    touchDirection.setZero();
    walking = false;
  }

  void freeze(bool value) {
    blocked = value;
    clearInput();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    keys
      ..clear()
      ..addAll(keysPressed);
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        clearInput();
        onPause();
      }
      if (!blocked &&
          [
            LogicalKeyboardKey.keyE,
            LogicalKeyboardKey.enter,
            LogicalKeyboardKey.space,
          ].contains(event.logicalKey)) {
        interact();
      }
    }
    return KeyEventResult.handled;
  }

  void interact() {
    if (!blocked && nearby.value != null) {
      clearInput();
      onInteract(nearby.value!);
    }
  }

  bool canStand(double x, double y) {
    final outside = session.map == 'outside';
    if (x < (outside ? 16 : 40) ||
        x > (outside ? 752 : 344) ||
        y < (outside ? 36 : 80) ||
        y > (outside ? 472 : 256)) {
      return false;
    }
    final feet = Rect.fromLTWH(x - 5, y - 5, 10, 7);
    if (solidsFor(session.map).any((r) => r.overlaps(feet))) return false;
    return !targetsFor(session.map)
        .where((t) => t.person)
        .any((t) => (t.position - Offset(x, y)).distance < 11);
  }

  void centerCamera() {
    // Viewfinder.position returns a derived vector; assign through its setter.
    camera.viewfinder.position = Vector2(
      session.map == 'outside'
          ? hero.position.x.clamp(192, 576).toDouble()
          : 192,
      session.map == 'outside'
          ? hero.position.y.clamp(108, 468).toDouble()
          : 164,
    );
  }

  void changeMap(String next) {
    if (next == 'outside') {
      final p = places.firstWhere((p) => p.id == session.map);
      session.x = p.door.dx;
      session.y = p.door.dy + 18;
      direction = 0;
    } else {
      session.x = 192;
      session.y = 220;
      direction = 2;
    }
    session.map = next;
    hero.position.setValues(session.x, session.y);
    nearby.value = null;
    clearInput();
    centerCamera();
    session.changed();
    onMapChanged?.call(next);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded || blocked) return;
    final elapsed = dt.clamp(0.0, .1);
    if (!session.reduceMotion) phase += elapsed;
    var dx = touchDirection.x, dy = touchDirection.y;
    if (keys.contains(LogicalKeyboardKey.keyA) ||
        keys.contains(LogicalKeyboardKey.arrowLeft)) {
      dx--;
    }
    if (keys.contains(LogicalKeyboardKey.keyD) ||
        keys.contains(LogicalKeyboardKey.arrowRight)) {
      dx++;
    }
    if (keys.contains(LogicalKeyboardKey.keyW) ||
        keys.contains(LogicalKeyboardKey.arrowUp)) {
      dy--;
    }
    if (keys.contains(LogicalKeyboardKey.keyS) ||
        keys.contains(LogicalKeyboardKey.arrowDown)) {
      dy++;
    }
    final vector = Vector2(dx, dy);
    final wasWalking = walking;
    walking = vector.length > 0;
    if (wasWalking && !walking) session.save();
    if (walking) {
      stepClock += elapsed;
      if (stepClock > .3) {
        stepClock = 0;
        onStep?.call();
      }
      vector.normalize();
      direction = dx.abs() > dy.abs() ? (dx < 0 ? 1 : 3) : (dy < 0 ? 2 : 0);
      final steps = (elapsed * 82 / 3).ceil().clamp(1, 8);
      for (var i = 0; i < steps; i++) {
        final nx = hero.x + vector.x * elapsed * 82 / steps;
        if (canStand(nx, hero.y)) hero.x = nx;
        final ny = hero.y + vector.y * elapsed * 82 / steps;
        if (canStand(hero.x, ny)) hero.y = ny;
      }
      session.x = hero.x;
      session.y = hero.y;
      hero.priority = hero.y.toInt();
      centerCamera();
      if (session.map == 'outside' &&
          hero.y < 264 &&
          !session.flags.contains('street')) {
        session.flags.add('street');
        session.changed();
      }
    }
    final facing = [
      const Offset(0, 1),
      const Offset(-1, 0),
      const Offset(0, -1),
      const Offset(1, 0),
    ][direction];
    WorldTarget? closest;
    var distance = 30.0;
    for (final target in targetsFor(session.map)) {
      final delta = target.position - Offset(hero.x, hero.y);
      final d = delta.distance;
      if (d < distance &&
          (d < 13 ||
              (delta.dx * facing.dx + delta.dy * facing.dy) / d > -.15)) {
        distance = d;
        closest = target;
      }
    }
    if (nearby.value?.id != closest?.id) nearby.value = closest;
    saveClock += elapsed;
    if (saveClock > 2) {
      saveClock = 0;
      if (walking) session.save();
    }
  }
}

class HeroComponent extends PositionComponent {
  final RecifeCashGame game;
  HeroComponent(this.game);
  @override
  void render(Canvas canvas) => drawPerson(
    canvas,
    shirt: game.session.shirt,
    skin: game.session.skin,
    hair: game.session.hair,
    accessory: game.session.accessory,
    direction: game.direction,
    phase: game.phase,
    moving: game.walking && !game.session.reduceMotion,
  );
}

class NpcComponent extends PositionComponent {
  final RecifeCashGame game;
  final String id;
  NpcComponent(this.game, this.id);
  WorldTarget? get target {
    for (final t in targetsFor(game.session.map)) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final t = target;
    if (t != null) {
      position.setValues(t.position.dx, t.position.dy);
      priority = position.y.toInt();
    }
  }

  @override
  void render(Canvas canvas) {
    final c = canvas;
    final t = target;
    if (t == null) return;
    final index = ['chico', 'bia', 'clara', 'lucia', 'nando'].indexOf(id);
    final delta = game.hero.position - position;
    final dir = delta.length < 56
        ? (delta.x.abs() > delta.y.abs()
              ? (delta.x < 0 ? 1 : 3)
              : (delta.y < 0 ? 2 : 0))
        : 0;
    c.save();
    c.translate(
      0,
      game.session.reduceMotion ? 0 : math.sin(game.phase * 2 + index) * .5,
    );
    drawPerson(
      c,
      shirt: [0, 2, 1, 3, 1][index],
      skin: [1, 2, 0, 1, 1][index],
      hair: index == 0 ? 2 : index % 3,
      accessory: index == 0 ? 1 : 0,
      direction: dir,
    );
    final quest = ['chico', 'clara', 'nando', 'lucia'].indexOf(id);
    if (quest == game.session.activeQuest) {
      pixel(c, -4, -36, 8, 10, 0xfff5c35f);
      tinyText(c, '!', 0, -36, size: 9, color: const Color(0xff322f4e));
    }
    tinyText(c, t.name, 0, 3, size: 5, color: const Color(0xff20384e));
    c.restore();
  }
}

class Scenery extends PositionComponent {
  final RecifeCashGame game;
  Scenery(this.game) : super(priority: -1000);
  void tree(Canvas c, double x, double y) {
    pixel(c, x - 10, y + 6, 25, 7, 0x302d514c);
    pixel(c, x - 2, y - 15, 5, 24, 0xff895b42);
    pixel(c, x - 15, y - 26, 30, 14, 0xff287064);
    pixel(c, x - 10, y - 34, 23, 25, 0xff388774);
    pixel(c, x - 16, y - 23, 12, 7, 0xff4f9c79);
    pixel(c, x - 9, y - 31, 14, 6, 0xff6eb58a);
    pixel(c, x + 5, y - 20, 12, 7, 0xff246358);
  }

  void palm(Canvas c, double x, double y) {
    pixel(c, x + 3, y - 26, 4, 31, 0xff9c7152);
    pixel(c, x, y - 37, 5, 16, 0xffb18357);
    for (final r in [
      const Rect.fromLTWH(-22, -39, 22, 5),
      const Rect.fromLTWH(-17, -45, 21, 5),
      const Rect.fromLTWH(3, -44, 21, 5),
      const Rect.fromLTWH(6, -35, 23, 5),
      const Rect.fromLTWH(-26, -34, 10, 5),
      const Rect.fromLTWH(19, -39, 10, 5),
    ]) {
      pixel(c, x + r.left, y + r.top, r.width, r.height, 0xff338775);
    }
    pixel(c, x - 3, y - 43, 10, 6, 0xff6aaf78);
  }

  void building(Canvas c, Place p) {
    final r = p.bounds;
    pixel(c, r.left + 6, r.top + 9, r.width, r.height + 7, 0x30304954);
    pixel(c, r.left, r.top + 14, r.width, r.height - 14, p.color);
    pixel(c, r.left, r.top + 14, 5, r.height - 14, 0xfff5dcac);
    pixel(c, r.right - 5, r.top + 14, 5, r.height - 14, 0xfff5dcac);
    pixel(c, r.left - 4, r.top, r.width + 8, 19, 0xffa7544e);
    for (double x = r.left - 4; x < r.right + 4; x += 8) {
      pixel(c, x, r.top + 2, 6, 3, 0xffce765c);
      pixel(c, x + 2, r.top + 9, 6, 3, 0xffcd765c);
    }
    pixel(c, r.left - 3, r.top + 18, r.width + 6, 4, 0xfff7dcb1);
    for (double x = r.left + 13; x < r.right - 15; x += 32) {
      pixel(c, x - 2, r.top + 30, 19, 25, 0xfff3dbad);
      pixel(c, x, r.top + 32, 15, 20, 0xff365d72);
      pixel(c, x + 6, r.top + 32, 2, 20, 0xffe2cda2);
      pixel(c, x, r.top + 42, 15, 2, 0xffe2cda2);
      pixel(c, x - 4, r.top + 55, 23, 3, 0xff895846);
    }
    pixel(c, r.left + 8, r.bottom - 41, r.width - 16, 13, 0xff344f60);
    tinyText(c, p.name, r.center.dx, r.bottom - 38, size: 5);
    pixel(c, r.center.dx - 10, r.bottom - 25, 20, 25, 0xfff5ddb1);
    pixel(c, r.center.dx - 7, r.bottom - 23, 14, 23, 0xff3b4b60);
    pixel(c, r.center.dx + 3, r.bottom - 13, 2, 2, 0xffeabd68);
    pixel(c, r.center.dx - 12, r.bottom, 24, 4, 0xffc5b8a0);
    if (p.id == 'market') {
      for (var i = 0; i < 7; i++) {
        pixel(
          c,
          r.left + 8 + i * 16,
          r.bottom - 27,
          16,
          7,
          i.isEven ? 0xfffaf0c7 : 0xffbb5258,
        );
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final c = canvas;
    if (game.session.map != 'outside') {
      interior(c);
      return;
    }
    pixel(c, 0, 0, 768, 576, 0xff23889d);
    for (var row = 0; row < 36; row++) {
      for (var col = 0; col < 48; col++) {
        final x = col * 16.0, y = row * 16.0;
        if (y >= 480 || x >= 688) {
          final shift = (game.phase * 3).floor() % 8;
          if ((col * 7 + row * 3) % 5 == 0) {
            pixel(c, x + shift, y + 7, 8, 1, 0xff48adad);
            pixel(c, x + 3, y + 12, 5, 1, 0xff1e708b);
          }
        } else {
          pixel(
            c,
            x,
            y,
            16,
            16,
            (row + col) % 3 == 0 ? 0xffd7c7a4 : 0xffdfd0ad,
          );
          pixel(c, x, y + 15, 16, 1, 0xffc8b798);
          pixel(c, x + (row.isEven ? 0 : 8), y, 1, 15, 0xffcebf9d);
          if ((row * 13 + col * 7) % 11 == 0) {
            pixel(c, x + 4, y + 5, 2, 1, 0xffbcae90);
          }
        }
      }
    }
    // Commercial street, curb, waterfront promenade and bridge.
    pixel(c, 16, 224, 656, 50, 0xff999e99);
    for (double y = 228; y < 273; y += 8) {
      for (double x = 16; x < 672; x += 16) {
        pixel(c, x + (y % 16), y, 14, 6, 0xffaeb1a5);
      }
    }
    pixel(c, 16, 220, 656, 4, 0xfff0e3bf);
    pixel(c, 16, 274, 656, 4, 0xfff0e3bf);
    pixel(c, 0, 472, 688, 8, 0xffb9ab94);
    pixel(c, 680, 0, 8, 480, 0xffede0b9);
    pixel(c, 680, 352, 88, 48, 0xffb5ad99);
    for (double x = 684; x < 768; x += 8) {
      pixel(c, x, 353, 2, 46, 0xffd2c5a5);
    }
    pixel(c, 682, 350, 86, 4, 0xff706e73);
    pixel(c, 682, 398, 86, 4, 0xff706e73);
    // Marco Zero compass mosaic, radial inlaid stone.
    final center = const Offset(368, 360);
    c.drawCircle(
      center,
      67,
      Paint()
        ..color = const Color(0xffc2aa83)
        ..isAntiAlias = false,
    );
    c.drawCircle(
      center,
      61,
      Paint()
        ..color = const Color(0xfff0dcab)
        ..isAntiAlias = false,
    );
    c.drawCircle(
      center,
      49,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xffb28b68)
        ..isAntiAlias = false,
    );
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final length = i.isEven ? 55.0 : 37.0;
      final path = Path()
        ..moveTo(
          center.dx + math.cos(a) * length,
          center.dy + math.sin(a) * length,
        )
        ..lineTo(
          center.dx + math.cos(a + 1.2) * 12,
          center.dy + math.sin(a + 1.2) * 12,
        )
        ..lineTo(center.dx, center.dy)
        ..close();
      c.drawPath(
        path,
        Paint()
          ..color = Color(i.isEven ? 0xffa06554 : 0xff5b7c7a)
          ..isAntiAlias = false,
      );
    }
    tinyText(
      c,
      'MARCO ZERO',
      368,
      441,
      size: 7,
      color: const Color(0xff665a58),
    );
    for (final p in places) {
      building(c, p);
    }
    for (final p in [
      const Offset(32, 104),
      const Offset(208, 112),
      const Offset(592, 168),
      const Offset(32, 328),
      const Offset(208, 352),
      const Offset(640, 320),
    ]) {
      palm(c, p.dx, p.dy);
    }
    tree(c, 620, 108);
    tree(c, 48, 448);
    tree(c, 648, 452);
    for (final p in [const Offset(208, 392), const Offset(592, 424)]) {
      pixel(c, p.dx, p.dy, 38, 10, 0xff7e6054);
      pixel(c, p.dx, p.dy - 5, 38, 4, 0xffa97e5d);
      pixel(c, p.dx + 3, p.dy + 9, 3, 4, 0xff455264);
      pixel(c, p.dx + 32, p.dy + 9, 3, 4, 0xff455264);
    }
    for (final x in [272.0, 480.0, 640.0]) {
      pixel(c, x, 432, 3, 26, 0xff38485a);
      pixel(c, x - 3, 427, 9, 8, 0xff3e5961);
      pixel(c, x - 1, 429, 5, 4, 0xfff6d88c);
    }
    pixel(c, 428, 409, 3, 18, 0xff825e4f);
    pixel(c, 418, 405, 26, 12, 0xff3b6571);
    tinyText(c, 'RECIFE', 431, 407, size: 4);
    // Boats and flower planters.
    for (final o in [
      const Offset(112, 514),
      const Offset(480, 536),
      const Offset(720, 256),
    ]) {
      pixel(c, o.dx, o.dy, 35, 7, 0xffe8c388);
      pixel(c, o.dx + 4, o.dy + 7, 27, 3, 0xffae5b51);
      pixel(c, o.dx + 8, o.dy - 9, 18, 10, 0xffeff0cf);
      pixel(c, o.dx + 10, o.dy - 7, 14, 5, 0xff39869a);
    }
    for (final x in [240.0, 560.0]) {
      pixel(c, x, 294, 22, 8, 0xffa56d52);
      for (var i = 0; i < 5; i++) {
        pixel(c, x + i * 4, 287, 4, 9, 0xff49946a);
        pixel(c, x + i * 4, 285 + (i % 2) * 3, 3, 3, 0xfff1bb58);
      }
    }
  }

  void interior(Canvas c) {
    pixel(c, 0, 0, 384, 288, 0xff263e51);
    pixel(c, 32, 32, 320, 232, 0xffe3c996);
    for (double y = 72; y < 264; y += 16) {
      for (double x = 32; x < 352; x += 32) {
        pixel(
          c,
          x,
          y,
          31,
          15,
          ((x + y).toInt() % 3 == 0) ? 0xffc49f76 : 0xffd4b587,
        );
        pixel(c, x + 3, y + 4, 9, 1, 0xffc49f76);
      }
    }
    pixel(c, 32, 32, 320, 40, 0xff7a9e9a);
    pixel(c, 32, 66, 320, 6, 0xff456b70);
    pixel(c, 32, 32, 5, 232, 0xff385362);
    pixel(c, 347, 32, 5, 232, 0xff385362);
    final label = places.firstWhere((p) => p.id == game.session.map).name;
    tinyText(c, label, 192, 46, size: 9);
    pixel(c, 180, 256, 24, 8, 0xff465367);
    tinyText(c, 'SAÍDA', 192, 266, size: 6);
    if (game.session.map == 'home') {
      pixel(c, 80, 80, 40, 28, 0xff816d59);
      pixel(c, 82, 83, 36, 24, 0xff6c97b5);
      pixel(c, 84, 82, 30, 8, 0xfff3e7be);
      pixel(c, 248, 80, 48, 30, 0xff9f7457);
      pixel(c, 255, 85, 17, 12, 0xfff8e8c4);
      tinyText(c, 'Zzz', 100, 70, size: 7);
      pixel(c, 160, 140, 64, 48, 0xffae706a);
      pixel(c, 164, 144, 56, 40, 0xffc9957c);
    } else {
      pixel(c, 128, 88, 128, 26, 0xff8f6453);
      pixel(c, 126, 86, 132, 6, 0xffe8d0a0);
      for (double x = 64; x < 328; x += 64) {
        pixel(c, x, 80, 24, 38, 0xff4e6b74);
        for (var i = 0; i < 3; i++) {
          pixel(
            c,
            x + 3,
            84 + i * 10,
            18,
            7,
            game.session.map == 'electronics' ? 0xffa5c9c5 : 0xffd6b062,
          );
        }
      }
      tinyText(
        c,
        'Fale com a pessoa à frente do balcão',
        192,
        158,
        size: 5,
        color: const Color(0xff665858),
      );
    }
    for (final x in [48.0, 304.0]) {
      pixel(c, x, 176, 32, 32, 0xff9a795d);
      pixel(c, x + 4, 173, 24, 8, 0xff409078);
      pixel(c, x + 8, 167, 16, 8, 0xff64ae7f);
    }
  }
}
