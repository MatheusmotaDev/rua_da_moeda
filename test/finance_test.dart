import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rua_da_moeda/features/finance/finance.dart';

void main() {
  test('credit, debit, balance and unique transaction identifiers', () {
    final f = Finance();
    expect(f.credit('salary', 'Renda', 120000, 1), true);
    expect(f.credit('salary', 'Renda', 120000, 1), false);
    expect(f.debit('food', 'Alimentação', 24000, 1), true);
    expect(f.debit('food', 'Alimentação', 24000, 1), false);
    expect(f.balance, 96000);
    expect(f.income, 120000);
    expect(f.expenses, 24000);
    expect(f.entries.map((e) => e.id).toSet().length, f.entries.length);
  });
  test('insufficient funds do not mutate ledger or consume operation id', () {
    final f = Finance();
    expect(() => f.debit('buy', 'Compra', 1000, 1), throwsStateError);
    expect(f.operations, isEmpty);
    expect(f.entries, isEmpty);
    f.credit('salary', 'Renda', 1000, 1);
    expect(f.debit('buy', 'Compra', 1000, 1), true);
  });
  test('reject nonpositive operations', () {
    final f = Finance();
    expect(() => f.credit('a', 'x', 0, 1), throwsArgumentError);
    expect(() => f.debit('b', 'x', -1, 1), throwsArgumentError);
    expect(() => f.transfer('c', 0, 1), throwsArgumentError);
  });
  test('budget plans never spend money or transfer reserve', () {
    final f = Finance()
      ..credit('salary', 'Renda', 120000, 1)
      ..plan(15000, 10000, 5000);
    expect(f.balance, 120000);
    expect(f.reserve, 0);
    expect(f.expenses, 0);
    expect(f.budget.values.reduce((a, b) => a + b), 120000);
    f.budget['Manutenção'] = 6000;
    f.plan(20000, 5000, 5000);
    expect(f.budget.values.reduce((a, b) => a + b), 120000);
    expect(f.budget.containsKey('Manutenção'), false);
    expect(() => f.plan(30000, 1, 0), throwsArgumentError);
  });
  test('reserve transfers conserve resources and are idempotent', () {
    final f = Finance()..credit('salary', 'Renda', 120000, 1);
    f.transfer('save', 10000, 1);
    f.transfer('save', 10000, 1);
    expect(f.balance, 110000);
    expect(f.reserve, 10000);
    expect(f.expenses, 0);
    f.transfer('withdraw', 5000, 1, withdraw: true);
    expect(f.balance + f.reserve, 120000);
    expect(() => f.transfer('bad', 6000, 1, withdraw: true), throwsStateError);
  });
  test('five installments create five obligations without deducting money', () {
    final f = Finance()..credit('salary', 'Renda', 120000, 1);
    f.installments('phone', 'Celular', 5, 9600, 1);
    f.installments('phone', 'Celular', 5, 9600, 1);
    expect(f.balance, 120000);
    expect(f.future, 48000);
    expect(f.bills.length, 5);
    expect(f.bills.map((b) => b.due), [31, 61, 91, 121, 151]);
    expect(f.pay('phone-1', 31), true);
    expect(f.pay('phone-1', 31), false);
    expect(f.balance, 110400);
    expect(f.future, 38400);
    expect(f.expenses, 9600);
  });
  test('unfunded payment leaves obligation unpaid', () {
    final f = Finance()..installments('phone', 'Celular', 1, 9600, 1);
    expect(() => f.pay('phone-1', 31), throwsStateError);
    expect(f.bills.first.paid, false);
  });
  test('round trip preserves ledger idempotency and bills', () {
    final f = Finance()
      ..credit('salary', 'Renda', 120000, 1)
      ..installments('phone', 'Celular', 5, 9600, 1)
      ..pay('phone-1', 31)
      ..plan(15000, 10000, 5000);
    final r = Finance.fromJson(jsonDecode(jsonEncode(f.toJson())));
    expect(r.toJson(), f.toJson());
    expect(r.pay('phone-1', 31), false);
    expect(r.credit('salary', 'Renda', 120000, 1), false);
  });
  test('Brazilian currency formatting uses exact cents', () {
    expect(reais(120000), 'R\$ 1.200,00');
    expect(reais(1825), 'R\$ 18,25');
    expect(reais(-1), '-R\$ 0,01');
  });
}
