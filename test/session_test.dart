import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rua_da_moeda/core/storage/save_repository.dart';
import 'package:rua_da_moeda/features/session.dart';

Future<GameSession> fresh() async {
  SharedPreferences.setMockInitialValues({});
  final s = GameSession(await SaveRepository.open());
  s.newGame(
    playerName: 'Cris',
    playerProfile: 'Recomeço financeiro',
    color: 2,
    tone: 2,
    hairstyle: 1,
    adornment: 0,
  );
  return s;
}

void welcome(GameSession s) {
  s.flags.add('intro');
  s.flags.add('street');
  s.visited.add('bia');
  s.finishWelcome();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'welcome requires exploration and grants only one income and reward',
    () async {
      final s = await fresh();
      expect(() => s.finishWelcome(), throwsStateError);
      welcome(s);
      s.finishWelcome();
      expect(s.finance.balance, 120000);
      expect(s.xp, 100);
      expect(s.finance.entries.length, 1);
    },
  );
  test('quest dependencies prevent spending out of order', () async {
    final s = await fresh();
    expect(() => s.plan(15000, 10000, 5000), throwsStateError);
    s.phone('cash');
    s.emergency('repair');
    expect(s.finance.balance, 0);
    expect(s.completed, isEmpty);
  });
  for (final option in ['cash', 'installments', 'wait', 'research']) {
    test(
      'complete chapter with $option; reward and effects cannot repeat',
      () async {
        final s = await fresh();
        welcome(s);
        s.plan(15000, 10000, 5000);
        s.phone(option);
        s.emergency('repair');
        final before = jsonEncode(s.finance.toJson());
        s.phone(option);
        s.emergency('repair');
        expect(jsonEncode(s.finance.toJson()), before);
        expect(s.completed, {0, 1, 2, 3});
        expect(s.xp, 600);
        expect(
          s.finance.balance,
          120000 - 12000 - ({'cash': 40000, 'research': 28000}[option] ?? 0),
        );
        expect(s.finance.bills.length, option == 'installments' ? 5 : 0);
      },
    );
  }
  test(
    'emergency reallocation preserves total budget and persists effect',
    () async {
      final s = await fresh();
      welcome(s);
      s.plan(15000, 10000, 5000);
      s.phone('wait');
      s.emergency('replan');
      expect(s.finance.budget['Lazer'], 4000);
      expect(s.finance.budget['Manutenção'], 6000);
      expect(s.finance.balance, 114000);
    },
  );
  test('reserve can be recovered before resolving an emergency', () async {
    final s = await fresh();
    welcome(s);
    s.plan(30000, 0, 0);
    s.phone('wait');
    s.reserveMoney(120000);
    expect(() => s.emergency('repair'), throwsStateError);
    expect(s.completed.contains(3), false);
    s.reserveMoney(12000, withdraw: true);
    s.emergency('repair');
    expect(s.finance.balance, 0);
    expect(s.completed.contains(3), true);
  });
  test(
    'calendar never duplicates payments and work is once per fictional day',
    () async {
      final s = await fresh();
      welcome(s);
      s.plan(15000, 10000, 5000);
      s.phone('installments');
      s.work();
      expect(() => s.work(), throwsStateError);
      for (var i = 0; i < 30; i++) {
        s.rest();
      }
      expect(s.day, 31);
      expect(s.finance.expenses, 0);
      s.payBill('phone-credit-1');
      s.payBill('phone-credit-1');
      expect(s.finance.expenses, 9600);
      s.work();
      expect(s.finance.income, 136000);
    },
  );
  test('side quest increases difficulty, no financial punishment and unique reward', () async {
    final s = await fresh();
    expect(s.answerChange(0), false);
    expect(s.finance.balance, 0);
    expect(s.answerChange(1250), true);
    expect(s.answerChange(1825), true);
    expect(s.answerChange(2630), true);
    s.answerChange(2630);
    expect(s.xp, 75);
    expect(s.inventory.contains('Chapéu de frevo'), true);
  });
  test(
    'persistent save restores position, identity, decisions, time and economy',
    () async {
      final s = await fresh();
      welcome(s);
      s.plan(15000, 10000, 5000);
      s.phone('installments');
      s.reserveMoney(5000);
      s.rest();
      s.x = 124.5;
      s.y = 210;
      s.map = 'bank';
      await s.save();
      final restored = GameSession(s.repository);
      restored.load();
      expect(restored.toJson(), s.toJson());
      restored.finishWelcome();
      expect(restored.finance.income, 120000);
      expect(restored.finance.bills.where((b) => b.paid), isEmpty);
    },
  );
  test('invalid save format is rejected', () async {
    final s = await fresh();
    expect(() => s.restore('{"version":2}'), throwsFormatException);
  });
}
