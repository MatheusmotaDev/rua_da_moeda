import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/storage/save_repository.dart';
import 'finance/finance.dart';

const questNames = [
  'Bem-vindo ao Recife',
  'Para onde foi meu dinheiro?',
  'Comprar ou esperar?',
  'Um imprevisto no caminho',
  'O troco certo',
];
const titles = [
  'Aprendiz Financeiro',
  'Organizador',
  'Consumidor Consciente',
  'Planejador',
  'Estrategista',
  'Mestre do Futuro',
];

class GameSession extends ChangeNotifier {
  final SaveRepository repository;
  Finance finance = Finance();
  String name = 'Alex',
      profile = 'Primeiro emprego',
      map = 'outside',
      saveId = '';
  int shirt = 0,
      skin = 1,
      hair = 0,
      accessory = 0,
      xp = 0,
      day = 1,
      period = 0,
      sideRound = 0;
  double x = 320, y = 340;
  bool started = false, reduceMotion = false, sound = true;
  double volume = .35;
  String textSpeed = 'Normal';
  final Set<String> flags = {}, achievements = {}, inventory = {}, visited = {};
  final Set<int> completed = {};
  final Map<String, String> choices = {};
  String? storageWarning;
  Future<void> _pending = Future.value();
  GameSession(this.repository);
  int get level => xp < 200
      ? 0
      : xp < 450
      ? 1
      : xp < 800
      ? 2
      : xp < 1200
      ? 3
      : xp < 1800
      ? 4
      : 5;
  int get activeQuest =>
      [0, 1, 2, 3].firstWhere((q) => !completed.contains(q), orElse: () => 4);
  String get objective => switch (activeQuest) {
    0 =>
      !flags.contains('intro')
          ? 'Converse com Seu Chico na praça.'
          : !visited.contains('bia')
          ? 'Conheça Bia perto da ponte.'
          : !flags.contains('street')
          ? 'Explore a rua comercial ao norte.'
          : 'Volte a Seu Chico para receber sua renda.',
    1 => 'Entre no Banco Aurora e planeje com Clara.',
    2 => 'Visite Nando na loja de eletrônicos.',
    3 => 'Converse com Dona Lúcia no mercado.',
    _ => 'Capítulo concluído! Experimente o troco certo.',
  };
  bool get canContinue {
    try {
      final j = jsonDecode(repository.read() ?? 'null');
      return j is Map && j['version'] == 1;
    } catch (_) {
      return false;
    }
  }

  void newGame({
    required String playerName,
    required String playerProfile,
    required int color,
    required int tone,
    required int hairstyle,
    required int adornment,
  }) {
    finance = Finance();
    name = playerName.trim().isEmpty ? 'Alex' : playerName.trim();
    profile = playerProfile;
    shirt = color;
    skin = tone;
    hair = hairstyle;
    accessory = adornment;
    map = 'outside';
    x = 320;
    y = 340;
    xp = 0;
    day = 1;
    period = 0;
    sideRound = 0;
    flags.clear();
    achievements.clear();
    inventory.clear();
    visited.clear();
    completed.clear();
    choices.clear();
    saveId = DateTime.now().microsecondsSinceEpoch.toString();
    started = true;
    changed();
  }

  void reward(int quest, int points, String achievement) {
    if (!completed.add(quest)) return;
    xp += points;
    achievements.add(achievement);
  }

  void finishWelcome() {
    if (!flags.contains('intro') ||
        !visited.contains('bia') ||
        !flags.contains('street')) {
      throw StateError('Conheça Bia e a rua comercial primeiro.');
    }
    finance.credit(
      'chapter1-first-income',
      'Renda inicial • primeiro passo',
      120000,
      day,
    );
    reward(0, 100, 'Primeiro Salário');
    inventory.add('Caderno de planejamento');
    changed();
  }

  void plan(int reserve, int leisure, int goal) {
    if (!completed.contains(0)) {
      throw StateError('Conclua a recepção com Seu Chico.');
    }
    finance.plan(reserve, leisure, goal);
    reward(1, 150, 'Meu Primeiro Orçamento');
    changed();
  }

  String phone(String option) {
    if (!completed.contains(1) || completed.contains(2)) {
      return 'Sua decisão já está registrada ou falta planejar com Clara.';
    }
    switch (option) {
      case 'cash':
        finance.debit('phone-cash', 'Celular à vista', 40000, day);
        inventory.add('Celular novo');
      case 'installments':
        finance.installments('phone-credit', 'Celular parcelado', 5, 9600, day);
        inventory.add('Celular novo');
      case 'research':
        finance.debit(
          'phone-reconditioned',
          'Celular recondicionado pesquisado',
          28000,
          day,
        );
        inventory.add('Celular recondicionado');
      case 'wait':
        inventory.add('Celular atual conservado');
      default:
        throw ArgumentError('Escolha desconhecida');
    }
    choices['phone'] = option;
    reward(2, 150, 'Consumidor Consciente');
    inventory.add('Comparador de preços');
    changed();
    return switch (option) {
      'cash' => 'Você pagou R\$ 400 sem criar parcelas. As despesas de R\$ 900 ainda são um plano: confira se caberão no mês.',
      'installments' =>
        'Cinco contas de R\$ 96, com vencimentos nos dias ${day + 30}, ${day + 60}, ${day + 90}, ${day + 120} e ${day + 150}. Total: R\$ 480, R\$ 80 acima do preço à vista. Nenhuma parcela foi paga agora.',
      'research' => 'A pesquisa revelou um recondicionado fictício com garantia por R\$ 280. Economia de R\$ 120 comparado ao novo. Avaliar condições e durabilidade também importa.',
      _ => 'Você manteve o celular atual e não gastou. Adiar preserva recursos, desde que o aparelho ainda atenda às suas necessidades.',
    };
  }

  String emergency(String option) {
    if (!completed.contains(2) || completed.contains(3)) {
      return 'Conclua a decisão do celular antes. Seu progresso permanece salvo.';
    }
    if (!['repair', 'replace', 'replan'].contains(option)) {
      throw ArgumentError('Escolha inválida');
    }
    final cost = option == 'repair'
        ? 12000
        : option == 'replace'
        ? 22000
        : 6000;
    finance.debit(
      'emergency',
      option == 'repair'
          ? 'Conserto do equipamento'
          : option == 'replace'
          ? 'Equipamento substituto'
          : 'Reparo básico e reorganização',
      cost,
      day,
    );
    if (option == 'replan' && finance.budget.isNotEmpty) {
      final leisure = finance.budget['Lazer'] ?? 0;
      final shifted = leisure < 6000 ? leisure : 6000;
      finance.budget['Lazer'] = leisure - shifted;
      finance.budget['Manutenção'] =
          (finance.budget['Manutenção'] ?? 0) + shifted;
    }
    choices['emergency'] = option;
    reward(3, 200, 'Planejador do Futuro');
    inventory.add('Lembrança do Marco Zero');
    changed();
    return 'Você pagou ${reais(cost)} e manteve o equipamento necessário à rotina. ${option == 'replan' ? 'O reparo básico exige cuidado até a revisão completa; o planejamento do lazer foi revisto.' : 'Seu saldo e extrato refletem a despesa.'} Reserva e planejamento ajudam; imprevistos também podem exigir apoio. Capítulo 1 concluído!';
  }

  void reserveMoney(int amount, {bool withdraw = false}) {
    finance.transfer(
      'reserve-${finance.entries.length}',
      amount,
      day,
      withdraw: withdraw,
    );
    if (!withdraw) achievements.add('Primeira Reserva');
    changed();
  }

  void payBill(String id) {
    finance.pay(id, day);
    changed();
  }

  void rest() {
    day++;
    period = 0;
    flags.add('day-$day');
    changed();
  }

  void work() {
    if (!completed.contains(0)) {
      throw StateError('Converse com Seu Chico antes de começar o trabalho.');
    }
    if (flags.contains('work-$day')) {
      throw StateError(
        'Atividade de hoje concluída. Descanse em casa para outro dia.',
      );
    }
    flags.add('work-$day');
    finance.credit('work-$day', 'Ajuda na feira • Bia', 8000, day);
    period = (period + 1).clamp(0, 2);
    changed();
  }

  bool answerChange(int answer) {
    if (completed.contains(4)) return true;
    final correct = [1250, 1825, 2630][sideRound.clamp(0, 2)];
    if (answer != correct) return false;
    sideRound++;
    if (sideRound >= 3) {
      reward(4, 75, 'O Troco Certo');
      inventory.add('Chapéu de frevo');
    }
    changed();
    return true;
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': saveId,
    'name': name,
    'profile': profile,
    'shirt': shirt,
    'skin': skin,
    'hair': hair,
    'accessory': accessory,
    'map': map,
    'x': x,
    'y': y,
    'xp': xp,
    'day': day,
    'period': period,
    'sideRound': sideRound,
    'flags': flags.toList(),
    'achievements': achievements.toList(),
    'inventory': inventory.toList(),
    'visited': visited.toList(),
    'completed': completed.toList(),
    'choices': choices,
    'finance': finance.toJson(),
    'reduceMotion': reduceMotion,
    'sound': sound,
    'volume': volume,
    'textSpeed': textSpeed,
  };
  void restore(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    if (j['version'] != 1) throw const FormatException('Versão incompatível');
    final restoredFinance = Finance.fromJson(
      Map<String, dynamic>.from(j['finance']),
    );
    final restoredMap = j['map'] as String;
    if (![
      'outside',
      'bank',
      'market',
      'electronics',
      'home',
    ].contains(restoredMap)) {
      throw const FormatException('Mapa inválido');
    }
    finance = restoredFinance;
    saveId = j['id'];
    name = j['name'];
    profile = j['profile'];
    shirt = j['shirt'];
    skin = j['skin'];
    hair = j['hair'];
    accessory = j['accessory'] ?? 0;
    map = restoredMap;
    x = (j['x'] as num).toDouble();
    y = (j['y'] as num).toDouble();
    xp = j['xp'];
    day = j['day'];
    period = j['period'];
    sideRound = j['sideRound'];
    flags
      ..clear()
      ..addAll(List<String>.from(j['flags']));
    achievements
      ..clear()
      ..addAll(List<String>.from(j['achievements']));
    inventory
      ..clear()
      ..addAll(List<String>.from(j['inventory']));
    visited
      ..clear()
      ..addAll(List<String>.from(j['visited']));
    completed
      ..clear()
      ..addAll(List<int>.from(j['completed']));
    choices
      ..clear()
      ..addAll(Map<String, String>.from(j['choices']));
    reduceMotion = j['reduceMotion'] ?? false;
    sound = j['sound'] ?? true;
    volume = (j['volume'] as num?)?.toDouble() ?? .35;
    textSpeed = j['textSpeed'] ?? 'Normal';
    started = true;
    notifyListeners();
  }

  void load() => restore(
    repository.read() ?? (throw StateError('Nenhuma aventura salva.')),
  );
  Future<void> save() {
    if (!started) return Future.value();
    final snapshot = jsonEncode(toJson());
    _pending = _pending.then((_) async {
      try {
        if (!await repository.write(snapshot)) {
          throw StateError('Falha ao salvar');
        }
        if (storageWarning != null) {
          storageWarning = null;
          notifyListeners();
        }
      } catch (_) {
        storageWarning = 'Não foi possível salvar neste dispositivo. Verifique o armazenamento.';
        notifyListeners();
      }
    });
    return _pending;
  }

  void changed() {
    notifyListeners();
    save();
  }
}
