import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rua_da_moeda/core/storage/save_repository.dart';
import 'package:rua_da_moeda/features/session.dart';
import 'package:rua_da_moeda/features/dialogues/dialogue_catalog.dart';
import 'package:rua_da_moeda/game/recife_cash_game.dart';
import 'package:rua_da_moeda/game/maps/map_data.dart';
import 'package:rua_da_moeda/ui/recife_app.dart';

Future<GameSession> session() async {
  SharedPreferences.setMockInitialValues({});
  final s = GameSession(await SaveRepository.open());
  s.sound = false;
  return s;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'chapter one UI flow through spatial interaction and persistent choices',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = await session();
      s.newGame(
        playerName: 'Cris',
        playerProfile: 'Primeiro emprego',
        color: 0,
        tone: 1,
        hairstyle: 0,
        adornment: 0,
      );
      s.textSpeed = 'Imediata';
      await s.save();
      await tester.pumpWidget(
        RecifeApp(
          session: s,
          dialogues: await tester.runAsync(DialogueCatalog.load),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar aventura'));
      await tester.pump();
      final g = tester
          .widget<GameWidget<RecifeCashGame>>(
            find.byType(GameWidget<RecifeCashGame>),
          )
          .game!;
      await tester.runAsync(() => g.loaded);
      await tester.pump();
      g.pauseEngine();
      expect(g.camera.viewfinder.position.x, 320);
      expect(g.camera.viewfinder.position.y, 340);
      Future<void> click(String text) async {
        final f = find.text(text);
        await tester.ensureVisible(f);
        await tester.tap(f);
        await tester.pump();
      }

      Future<void> meet(String id) async {
        final t = targetsFor(s.map).firstWhere((t) => t.id == id);
        g.hero.position.setValues(
          t.position.dx,
          t.position.dy + (id == 'exit' ? -20 : 20),
        );
        s.x = g.hero.x;
        s.y = g.hero.y;
        g.direction = id == 'exit' ? 0 : 2;
        g.freeze(false);
        g.update(.016);
        g.interact();
        await tester.pump();
      }

      await meet('chico');
      await click('Vou conhecer o Recife!');
      await meet('bia');
      await click('Prazer em conhecer você!');
      g.hero.position.setValues(320, 250);
      g.keys.add(LogicalKeyboardKey.keyD);
      g.update(.016);
      g.clearInput();
      await meet('chico');
      await click('Receber minha primeira renda • R\$ 1.200');
      await click('Continuar explorando');
      expect(s.finance.balance, 120000);
      await meet('door-bank');
      expect(s.map, 'bank');
      await meet('clara');
      await click('Montar meu orçamento');
      await click('Salvar meu planejamento');
      await click('Continuar explorando');
      expect(s.finance.balance, 120000);
      expect(s.completed.contains(1), true);
      await meet('exit');
      await meet('door-electronics');
      await meet('nando');
      await click('Parcelar • 5 × R\$ 96 = R\$ 480');
      await click('Continuar explorando');
      expect(s.finance.bills.length, 5);
      expect(s.finance.balance, 120000);
      await meet('exit');
      await meet('door-market');
      await meet('lucia');
      await click('Consertar • R\$ 120');
      await click('Continuar explorando');
      expect(s.completed, {0, 1, 2, 3});
      expect(s.finance.balance, 108000);
      expect(s.xp, 600);
      await meet('lucia');
      await click('Praticar o troco certo');
      await click('R\$ 12,50');
      await click('R\$ 18,25');
      await click('R\$ 26,30');
      expect(s.completed.length, 5);
      expect(s.xp, 675);
      expect(s.inventory.contains('Chapéu de frevo'), true);
      expect(tester.takeException(), isNull);
      await s.save();
      final restored = GameSession(s.repository);
      restored.load();
      expect(restored.toJson(), s.toJson());
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('touch landscape viewport keeps HUD and menus usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(740, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = await session();
    s.newGame(
      playerName: 'Sol',
      playerProfile: 'Primeiro emprego',
      color: 1,
      tone: 1,
      hairstyle: 0,
      adornment: 0,
    );
    await s.save();
    await tester.pumpWidget(
      RecifeApp(
        session: s,
        dialogues: await tester.runAsync(DialogueCatalog.load),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continuar aventura'));
    await tester.tap(find.text('Continuar aventura'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Pausar / menu'));
    await tester.pump();
    expect(find.text('Uma pausa na jornada'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  test(
    'collision blocks buildings, water, NPCs and world boundaries',
    () async {
      final s = await session();
      final g = RecifeCashGame(s, (_) {}, () {});
      expect(g.canStand(100, 100), false);
      expect(g.canStand(320, 490), false);
      expect(g.canStand(700, 200), false);
      expect(g.canStand(360, 328), false);
      expect(g.canStand(-1, 320), false);
      expect(g.canStand(700, 376), true);
      expect(g.canStand(320, 340), true);
      s.map = 'bank';
      expect(g.canStand(192, 96), false);
      expect(g.canStand(192, 220), true);
    },
  );
  test('walkable path exists to every required target', () async {
    final s = await session();
    final g = RecifeCashGame(s, (_) {}, () {});
    for (final map in ['outside', 'bank', 'market', 'electronics', 'home']) {
      s.map = map;
      final start = map == 'outside' ? (320, 340) : (192, 220);
      final seen = <(int, int)>{start}, queue = <(int, int)>[start];
      var cursor = 0;
      while (cursor < queue.length) {
        final p = queue[cursor++];
        for (final d in [(4, 0), (-4, 0), (0, 4), (0, -4)]) {
          final n = (p.$1 + d.$1, p.$2 + d.$2);
          if (!seen.contains(n) &&
              g.canStand(n.$1.toDouble(), n.$2.toDouble())) {
            seen.add(n);
            queue.add(n);
          }
        }
      }
      for (final t in targetsFor(map)) {
        expect(
          seen.any(
            (p) =>
                (t.position - Offset(p.$1.toDouble(), p.$2.toDouble()))
                    .distance <
                25,
          ),
          true,
          reason: '$map / ${t.id} inaccessible',
        );
      }
    }
  });
  testWidgets(
    'engine moves in real time, blocks menus, transitions and restores position',
    (tester) async {
      final s = await session();
      final g = RecifeCashGame(s, (_) {}, () {});
      await tester.pumpWidget(GameWidget(game: g));
      await tester.runAsync(() => g.loaded);
      await tester.pump();
      g.pauseEngine();
      final original = g.hero.x;
      g.keys.add(LogicalKeyboardKey.keyD);
      g.update(.05);
      expect(g.hero.x, greaterThan(original));
      expect(g.camera.viewfinder.position.x, g.hero.x);
      final moved = g.hero.x;
      g.freeze(true);
      g.keys.add(LogicalKeyboardKey.keyD);
      g.update(.1);
      expect(g.hero.x, moved);
      g.changeMap('bank');
      expect(s.map, 'bank');
      expect(g.hero.x, 192);
      expect(g.camera.viewfinder.position.x, 192);
      expect(g.camera.viewfinder.position.y, 164);
      g.changeMap('outside');
      expect(s.map, 'outside');
      expect(s.x, 128);
      expect(s.y, 217);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('menu, character creation, settings and continue state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = await session();
    await tester.pumpWidget(
      RecifeApp(
        session: s,
        dialogues: await tester.runAsync(DialogueCatalog.load),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.semanticLabel == 'Rua da Moeda',
      ),
      findsOneWidget,
    );
    expect(s.canContinue, false);
    await tester.tap(find.text('Configurações'));
    await tester.pump();
    expect(find.text('Reduzir animações'), findsOneWidget);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pump();
    await tester.tap(find.text('NOVA AVENTURA  →'));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    for (var attempt = 0; attempt < 20; attempt++) {
      final start = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'COMEÇAR NO MARCO ZERO  →'),
      );
      if (start.onPressed != null) break;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.tap(find.text('COMEÇAR NO MARCO ZERO  →'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(s.started, true);
    expect(find.text('RECIFE ANTIGO'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
