class LedgerEntry {
  final String id, label, kind;
  final int amount, day;
  const LedgerEntry(this.id, this.label, this.kind, this.amount, this.day);
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'kind': kind,
    'amount': amount,
    'day': day,
  };
  factory LedgerEntry.fromJson(Map<String, dynamic> j) =>
      LedgerEntry(j['id'], j['label'], j['kind'], j['amount'], j['day']);
}

class Bill {
  final String id, label;
  final int amount, due;
  bool paid;
  Bill(this.id, this.label, this.amount, this.due, {this.paid = false});
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'amount': amount,
    'due': due,
    'paid': paid,
  };
  factory Bill.fromJson(Map<String, dynamic> j) =>
      Bill(j['id'], j['label'], j['amount'], j['due'], paid: j['paid']);
}

/// Pure domain service. Every monetary value is an integer number of cents.
class Finance {
  int balance = 0, reserve = 0;
  final List<LedgerEntry> entries = [];
  final List<Bill> bills = [];
  final Map<String, int> budget = {};
  final Set<String> operations = {};
  int get income =>
      entries.where((e) => e.kind == 'income').fold(0, (a, e) => a + e.amount);
  int get expenses =>
      entries.where((e) => e.kind == 'expense').fold(0, (a, e) => a + e.amount);
  int get future => bills.where((b) => !b.paid).fold(0, (a, b) => a + b.amount);
  bool credit(String id, String label, int amount, int day) {
    if (operations.contains(id)) return false;
    if (amount <= 0) throw ArgumentError('Valor deve ser positivo');
    operations.add(id);
    balance += amount;
    entries.add(LedgerEntry(id, label, 'income', amount, day));
    return true;
  }

  bool debit(String id, String label, int amount, int day) {
    if (operations.contains(id)) return false;
    if (amount <= 0) throw ArgumentError('Valor deve ser positivo');
    if (amount > balance) {
      throw StateError(
        'Saldo insuficiente. Reveja a escolha ou retire da reserva.',
      );
    }
    operations.add(id);
    balance -= amount;
    entries.add(LedgerEntry(id, label, 'expense', amount, day));
    return true;
  }

  bool transfer(String id, int amount, int day, {bool withdraw = false}) {
    if (operations.contains(id)) return false;
    if (amount <= 0) throw ArgumentError('Valor deve ser positivo');
    if (amount > (withdraw ? reserve : balance)) {
      throw StateError('Valor indisponível para transferência.');
    }
    operations.add(id);
    balance += withdraw ? amount : -amount;
    reserve += withdraw ? -amount : amount;
    entries.add(
      LedgerEntry(
        id,
        withdraw ? 'Retirada da reserva' : 'Transferência para reserva',
        'transfer',
        amount,
        day,
      ),
    );
    return true;
  }

  bool installments(String id, String label, int count, int amount, int day) {
    if (operations.contains(id)) return false;
    if (count < 1 || amount < 1) throw ArgumentError('Parcelas inválidas');
    operations.add(id);
    for (var i = 1; i <= count; i++) {
      bills.add(Bill('$id-$i', '$label • $i/$count', amount, day + 30 * i));
    }
    return true;
  }

  bool pay(String id, int day) {
    final bill = bills.firstWhere((b) => b.id == id);
    if (bill.paid) return false;
    if (debit('pay-$id', bill.label, bill.amount, day)) {
      bill.paid = true;
      return true;
    }
    return false;
  }

  void plan(int reservePlan, int leisure, int goals) {
    if ([reservePlan, leisure, goals].any((n) => n < 0) ||
        reservePlan + leisure + goals != 30000) {
      throw ArgumentError('Distribua exatamente R\$ 300.');
    }
    budget.clear();
    budget.addAll({
      'Moradia': 50000,
      'Alimentação': 24000,
      'Transporte': 10000,
      'Comunicação': 6000,
      'Reserva': reservePlan,
      'Lazer': leisure,
      'Metas': goals,
    });
  }

  Map<String, dynamic> toJson() => {
    'balance': balance,
    'reserve': reserve,
    'entries': entries.map((e) => e.toJson()).toList(),
    'bills': bills.map((b) => b.toJson()).toList(),
    'budget': budget,
    'operations': operations.toList(),
  };
  factory Finance.fromJson(Map<String, dynamic> j) {
    final f = Finance();
    f.balance = j['balance'];
    f.reserve = j['reserve'];
    if (f.balance < 0 || f.reserve < 0) {
      throw const FormatException('Saldo inválido');
    }
    f.entries.addAll(
      (j['entries'] as List).map(
        (e) => LedgerEntry.fromJson(Map<String, dynamic>.from(e)),
      ),
    );
    f.bills.addAll(
      (j['bills'] as List).map(
        (e) => Bill.fromJson(Map<String, dynamic>.from(e)),
      ),
    );
    f.budget.addAll(Map<String, int>.from(j['budget']));
    f.operations.addAll(List<String>.from(j['operations']));
    return f;
  }
  Finance();
}

String reais(int cents) {
  final digits = (cents.abs() ~/ 100).toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]}.',
  );
  return '${cents < 0 ? '-' : ''}R\$ $digits,${(cents.abs() % 100).toString().padLeft(2, '0')}';
}
