import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/services/sound_service.dart';
import '../features/dialogues/dialogue_catalog.dart';
import '../features/finance/finance.dart';
import '../features/session.dart';
import '../game/maps/map_data.dart';
import '../game/pixel_art.dart';
import '../game/recife_cash_game.dart';

const ink = Color(0xff142e43),
    panel = Color(0xff203c50),
    cream = Color(0xfff6eacb),
    gold = Color(0xffefbe65),
    mint = Color(0xff83c7af);

class RecifeApp extends StatelessWidget {
  final GameSession session;
  final DialogueCatalog? dialogues;
  const RecifeApp({super.key, required this.session, this.dialogues});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Rua da Moeda • Do Marco Zero ao Futuro',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: ink,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: mint,
        surface: panel,
        onSurface: cream,
      ),
      fontFamily: 'monospace',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(height: 1.6, fontSize: 14),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: cream),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: ink,
          backgroundColor: gold,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cream,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          side: const BorderSide(color: Color(0xff618080)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    ),
    home: Adventure(session: session, dialogues: dialogues),
  );
}

class Adventure extends StatefulWidget {
  final GameSession session;
  final DialogueCatalog? dialogues;
  const Adventure({super.key, required this.session, this.dialogues});
  @override
  State<Adventure> createState() => _AdventureState();
}

class _AdventureState extends State<Adventure> with WidgetsBindingObserver {
  GameSession get s => widget.session;
  String screen = 'menu';
  String? overlay, dialogue;
  DialogueCatalog? catalog;
  RecifeCashGame? game;
  final FocusNode gameFocus = FocusNode();
  final SoundService audio = SoundService();
  final TextEditingController name = TextEditingController(text: 'Alex');
  int shirt = 0, skin = 1, hair = 0, accessory = 0;
  String profile = 'Primeiro emprego',
      feedback = '',
      feedbackTitle = '',
      changeHint = '';
  int reservePlan = 150, leisurePlan = 100;
  int revealed = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    catalog = widget.dialogues;
    if (catalog == null) {
      DialogueCatalog.load().then((value) {
        if (mounted) setState(() => catalog = value);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    name.dispose();
    gameFocus.dispose();
    game?.nearby.dispose();
    audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      game?.clearInput();
      s.save();
      audio.pause();
    } else if (screen == 'play') {
      syncAudio();
    }
  }

  void syncAudio() {
    audio.configure(
      s.sound,
      s.volume,
      track: s.map == 'outside' ? 'marco_zero' : 'interior',
    );
  }

  void launch() {
    game?.nearby.dispose();
    game = RecifeCashGame(
      s,
      interact,
      () {
        if (overlay != null) {
          close();
        } else {
          show('pause');
        }
      },
      onStep: () => audio.effect('step'),
      onMapChanged: (_) => syncAudio(),
    );
    syncAudio();
    setState(() {
      screen = 'play';
      overlay = null;
      dialogue = null;
    });
    focus();
  }

  void focus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && screen == 'play' && overlay == null) {
        gameFocus.requestFocus();
      }
    });
  }

  void show(String id) {
    game?.freeze(true);
    setState(() {
      overlay = id;
    });
    s.save();
    if (screen == 'play') audio.effect('interact');
  }

  void close() {
    game?.freeze(false);
    setState(() {
      overlay = null;
      dialogue = null;
      changeHint = '';
    });
    focus();
  }

  void tell(String title, String text) {
    feedbackTitle = title;
    feedback = text;
    show('feedback');
    if (title.contains('XP') || title.contains('concluído')) {
      audio.effect('success');
    }
  }

  void guard(VoidCallback callback) {
    try {
      callback();
    } catch (e) {
      tell(
        'Vamos rever a escolha',
        e is StateError ? e.message.toString() : e.toString(),
      );
    }
  }

  void talk(String id) {
    dialogue = id;
    revealed = 0;
    show('dialogue');
  }

  void interact(WorldTarget target) {
    final id = target.id;
    if (id.startsWith('door-')) {
      game!.changeMap(id.substring(5));
      return;
    }
    if (id == 'exit') {
      game!.changeMap('outside');
      return;
    }
    if (id == 'bed') {
      show('rest');
      return;
    }
    if (id == 'desk') {
      show('planning');
      return;
    }
    if (id == 'sign') {
      tell(
        'Você está no Marco Zero',
        'Norte: rua comercial, Banco Aurora, mercado e eletrônicos. Leste: Bia e ponte. Sudoeste: sua casa. A cidade é uma representação estilizada do Recife. Use o mapa para se orientar.',
      );
      return;
    }
    s.visited.add(id);
    s.changed();
    switch (id) {
      case 'chico':
        talk(
          s.completed.contains(0)
              ? 'chico_done'
              : !s.flags.contains('intro')
              ? 'chico_intro'
              : s.visited.contains('bia') && s.flags.contains('street')
              ? 'chico_reward'
              : 'chico_wait',
        );
      case 'bia':
        talk('bia');
      case 'clara':
        talk(s.completed.contains(0) ? 'clara' : 'clara_locked');
      case 'nando':
        talk(
          s.completed.contains(2)
              ? 'nando_done'
              : s.completed.contains(1)
              ? 'nando'
              : 'nando_locked',
        );
      case 'lucia':
        talk(
          s.completed.contains(3)
              ? 'lucia_done'
              : s.completed.contains(2)
              ? 'lucia'
              : 'lucia_locked',
        );
    }
  }

  void choose(DialogueOption option) {
    if (option.next != null) {
      talk(option.next!);
      return;
    }
    final action = option.action ?? 'close';
    guard(() {
      switch (action) {
        case 'intro':
          s.flags.add('intro');
          s.changed();
          close();
        case 'welcome':
          s.finishWelcome();
          tell(
            'Primeiro passo concluído! +100 XP',
            'R\$ 1.200 foram registrados como receita uma única vez. Sua carteira e seu diário estão disponíveis. Agora entre no Banco Aurora e converse com Clara.',
          );
        case 'wallet':
          show('wallet');
        case 'budget':
          show('budget');
        case 'work':
          s.work();
          tell(
            'Feira organizada!',
            'Você recebeu R\$ 80 por ajudar Bia. O período avançou. Outra atividade estará disponível depois de descansar em casa.',
          );
        case 'change':
          show('change');
        default:
          if (action.startsWith('phone-')) {
            tell('Escolha registrada • +150 XP', s.phone(action.substring(6)));
          } else if (action.startsWith('emergency-')) {
            tell(
              'Do Marco Zero ao Futuro • +200 XP',
              s.emergency(action.substring(10)),
            );
          } else {
            close();
          }
      }
    });
  }

  Widget button(
    String text,
    VoidCallback? callback, {
    bool primary = false,
    IconData? icon,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SizedBox(
      width: double.infinity,
      child: primary
          ? FilledButton(onPressed: callback, child: Text(text))
          : OutlinedButton(
              onPressed: callback,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 10),
                  ],
                  Flexible(child: Text(text, textAlign: TextAlign.center)),
                ],
              ),
            ),
    ),
  );
  Widget eyebrow(String text) => Text(
    text,
    style: const TextStyle(
      color: mint,
      fontSize: 10,
      letterSpacing: 2,
      fontWeight: FontWeight.bold,
    ),
  );
  Widget body(String text, {Color? color}) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(text, style: TextStyle(color: color ?? cream, height: 1.65)),
  );
  Widget rule() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Divider(color: Color(0xff496471)),
  );
  Widget stat(String label, String value, {Color color = gold}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: s,
    builder: (context, _) => Scaffold(
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (overlay != null) {
              close();
            } else if (screen == 'create') {
              setState(() => screen = 'menu');
            } else if (screen == 'play') {
              show('pause');
            }
          },
        },
        child: Stack(
          children: [
            if (screen == 'play') play() else titleScreen(),
            if (overlay != null)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0xbb081b2d),
                  child: Center(child: modal()),
                ),
              ),
          ],
        ),
      ),
    ),
  );
  Widget titleScreen() => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/images/recife_title.png',
        fit: BoxFit.cover,
        alignment: Alignment.centerRight,
        filterQuality: FilterQuality.none,
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xf5122b40), Color(0xc6122b40), Color(0x00122b40)],
            stops: [0, .38, 1],
          ),
        ),
      ),
      SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                constraints.maxWidth > 700 ? 72 : 24,
                32,
                24,
                32,
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: math.min(410, constraints.maxWidth - 48),
                  child: screen == 'create'
                      ? creation()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            eyebrow('UMA AVENTURA PELO SEU AMANHÃ'),
                            const SizedBox(height: 28),
                            Center(
                              child: ClipOval(
                                child: Image.asset(
                                  'visual/logo.png',
                                  width: 240,
                                  height: 240,
                                  fit: BoxFit.contain,
                                  semanticLabel: 'Rua da Moeda',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'DO MARCO ZERO AO FUTURO',
                              style: TextStyle(
                                fontSize: 12,
                                color: cream,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 28),
                            body(
                              'Uma cidade para descobrir.\nUm futuro para construir.\nCada escolha vale.',
                              color: const Color(0xffbfcecb),
                            ),
                            const SizedBox(height: 12),
                            button(
                              'NOVA AVENTURA  →',
                              () => setState(() => screen = 'create'),
                              primary: true,
                            ),
                            button(
                              'Continuar aventura',
                              s.canContinue
                                  ? () => guard(() {
                                      s.load();
                                      launch();
                                    })
                                  : null,
                              icon: Icons.play_arrow_rounded,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => show('settings'),
                                    child: const Text('Configurações'),
                                  ),
                                ),
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => show('credits'),
                                    child: const Text('Créditos'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            eyebrow('CAPÍTULO 01  /  O PRIMEIRO PASSO'),
                            const SizedBox(height: 12),
                            const Text(
                              'Economia fictícia · Sem anúncios · Sem cadastro',
                              style: TextStyle(
                                color: Color(0xffa7bcb9),
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
  Widget creation() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      eyebrow('NOVA AVENTURA'),
      const SizedBox(height: 12),
      const Text(
        'Quem vai escrever\nessa história?',
        style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      Center(
        child: SizedBox(
          height: 100,
          width: 100,
          child: CustomPaint(
            painter: PersonPreview(shirt, skin, hair, accessory),
          ),
        ),
      ),
      TextField(
        controller: name,
        maxLength: 20,
        decoration: const InputDecoration(
          labelText: 'Seu nome',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: List.generate(
          4,
          (i) => ChoiceChip(
            label: Text(['Sol', 'Mar', 'Coral', 'Frevo'][i]),
            selected: shirt == i,
            onSelected: (_) => setState(() => shirt = i),
          ),
        ),
      ),
      Wrap(
        spacing: 8,
        children: List.generate(
          3,
          (i) => ChoiceChip(
            label: Text('Tom ${i + 1}'),
            selected: skin == i,
            onSelected: (_) => setState(() => skin = i),
          ),
        ),
      ),
      Wrap(
        spacing: 8,
        children: List.generate(
          3,
          (i) => ChoiceChip(
            label: Text(['Escuro', 'Cobre', 'Claro'][i]),
            selected: hair == i,
            onSelected: (_) => setState(() => hair = i),
          ),
        ),
      ),
      FilterChip(
        label: const Text('Chapéu de palha'),
        selected: accessory == 1,
        onSelected: (v) => setState(() => accessory = v ? 1 : 0),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: profile,
        decoration: const InputDecoration(labelText: 'Seu ponto de partida'),
        items: [
          'Primeiro emprego',
          'Trabalhador autônomo',
          'Recomeço financeiro',
        ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
        onChanged: (v) => profile = v!,
      ),
      const SizedBox(height: 20),
      if (s.canContinue)
        body(
          'Uma nova aventura substituirá o progresso salvo neste dispositivo.',
          color: gold,
        ),
      button(
        'COMEÇAR NO MARCO ZERO  →',
        catalog == null
            ? null
            : () {
                s.newGame(
                  playerName: name.text,
                  playerProfile: profile,
                  color: shirt,
                  tone: skin,
                  hairstyle: hair,
                  adornment: accessory,
                );
                launch();
              },
        primary: true,
      ),
      button('Voltar', () => setState(() => screen = 'menu')),
    ],
  );
  Widget badge(Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xee18374a),
      border: Border.all(color: const Color(0xff6a8a8b)),
      borderRadius: BorderRadius.circular(4),
      boxShadow: const [
        BoxShadow(color: Color(0x40000000), offset: Offset(0, 3)),
      ],
    ),
    child: child,
  );
  Widget play() => Stack(
    children: [
      Positioned.fill(
        child: Listener(
          onPointerDown: (_) {
            if (overlay == null) gameFocus.requestFocus();
          },
          child: GameWidget(game: game!, focusNode: gameFocus, autofocus: true),
        ),
      ),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 650;
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      badge(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.map == 'outside'
                                  ? 'RECIFE ANTIGO'
                                  : places
                                        .firstWhere((p) => p.id == s.map)
                                        .name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: gold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dia ${s.day} · ${['Manhã', 'Tarde', 'Noite'][s.period]}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (s.completed.contains(0))
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => show('wallet'),
                            child: badge(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'CARTEIRA',
                                    style: TextStyle(fontSize: 8, color: mint),
                                  ),
                                  Text(
                                    reais(s.finance.balance),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: gold,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      IconButton.filledTonal(
                        tooltip: 'Pausar / menu',
                        onPressed: () => show('pause'),
                        icon: const Icon(Icons.menu),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: narrow ? 220 : 320),
                      child: InkWell(
                        onTap: () =>
                            show(s.completed.contains(0) ? 'quests' : 'help'),
                        child: badge(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.completed.contains(3)
                                    ? '✦ CAPÍTULO CONCLUÍDO'
                                    : '◆ ${questNames[s.activeQuest].toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.objective,
                                style: const TextStyle(
                                  fontSize: 10,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (s.storageWarning != null)
                    badge(
                      Text(
                        s.storageWarning!,
                        style: const TextStyle(color: gold, fontSize: 10),
                      ),
                    ),
                  const Spacer(),
                  if (overlay == null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        dpad(),
                        const Spacer(),
                        if (!narrow)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: badge(
                              const Text(
                                'WASD / setas  ·  E conversar  ·  Esc menu',
                                style: TextStyle(fontSize: 9),
                              ),
                            ),
                          ),
                        const Spacer(),
                        ValueListenableBuilder<WorldTarget?>(
                          valueListenable: game!.nearby,
                          builder: (context, target, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (target != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: badge(
                                    Text(
                                      target.name,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: gold,
                                      ),
                                    ),
                                  ),
                                ),
                              SizedBox(
                                width: 74,
                                height: 64,
                                child: FilledButton(
                                  onPressed: target == null
                                      ? null
                                      : () => game!.interact(),
                                  child: const Text(
                                    'E',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ],
  );
  Widget dpad() {
    Widget arrow(IconData icon, double x, double y) => Listener(
      onPointerDown: (_) {
        game!.touchDirection.setValues(x, y);
      },
      onPointerUp: (_) => game!.touchDirection.setZero(),
      onPointerCancel: (_) => game!.touchDirection.setZero(),
      child: Semantics(
        label:
            'Mover ${y < 0
                ? 'para cima'
                : y > 0
                ? 'para baixo'
                : x < 0
                ? 'para esquerda'
                : 'para direita'}',
        button: true,
        child: Container(
          width: 42,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xcc203c50),
            border: Border.all(color: const Color(0xff6a8a8b)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: cream, size: 26),
        ),
      ),
    );
    return SizedBox(
      width: 126,
      height: 114,
      child: Column(
        children: [
          arrow(Icons.keyboard_arrow_up, 0, -1),
          Row(
            children: [
              arrow(Icons.keyboard_arrow_left, -1, 0),
              const SizedBox(width: 42, height: 38),
              arrow(Icons.keyboard_arrow_right, 1, 0),
            ],
          ),
          arrow(Icons.keyboard_arrow_down, 0, 1),
        ],
      ),
    );
  }

  String get modalTitle => switch (overlay) {
    'pause' => 'Uma pausa na jornada',
    'wallet' => 'Sua carteira',
    'planning' => 'Planejar o amanhã',
    'budget' => 'Cada real com um propósito',
    'quests' => 'Diário de missões',
    'inventory' => 'Sua mochila',
    'map' => 'Pelos caminhos do Recife',
    'profile' => 'Sua jornada',
    'settings' => 'Do seu jeito',
    'credits' => 'Feito para descobrir',
    'rest' => 'Um novo dia',
    'help' => 'Seu primeiro passeio',
    'change' => 'O troco certo',
    'feedback' => feedbackTitle,
    'dialogue' => catalog?.nodes[dialogue]?.speaker ?? 'Conversa',
    _ => 'Rua da Moeda',
  };
  Widget modal() => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          decoration: BoxDecoration(
            color: ink,
            border: Border.all(color: gold, width: 2),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(color: Color(0x55000000), offset: Offset(6, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        modalTitle,
                        style: const TextStyle(
                          fontSize: 19,
                          color: gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: close,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xff496471)),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Material(color: ink, child: modalContent()),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget modalContent() => switch (overlay) {
    'dialogue' => dialogueContent(),
    'pause' => pauseContent(),
    'wallet' => wallet(),
    'budget' => budget(),
    'planning' => planning(),
    'quests' => quests(),
    'inventory' => inventory(),
    'map' => mapContent(),
    'profile' => profileContent(),
    'settings' => settings(),
    'rest' => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        body(
          'Descansar avança um dia e salva sua aventura. O tempo só avança quando você escolhe. Contas vencidas são sinalizadas na carteira; nenhum pagamento é automático.',
        ),
        button('Descansar até amanhã', () {
          s.rest();
          tell(
            'Bom dia, ${s.name}!',
            'Dia ${s.day}. ${s.finance.bills.where((b) => !b.paid && b.due <= s.day).length} conta(s) vencida(s) ou vencendo hoje. Consulte a carteira.',
          );
        }, primary: true),
      ],
    ),
    'feedback' => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        body(feedback),
        button('Continuar explorando', close, primary: true),
      ],
    ),
    'help' => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        body(
          'Caminhe com WASD, setas ou o direcional. Aproxime-se e olhe para a pessoa ou porta. Use E, Enter ou o botão de interação.\n\nComece com Seu Chico, à direita de onde você chegou. Bia fica perto da ponte, a leste. A rua comercial fica ao norte. Sua casa fica a sudoeste.\n\nEsc abre o menu. Conversas e menus pausam o movimento. O salvamento é automático neste dispositivo.',
        ),
        button('Vamos explorar', close, primary: true),
      ],
    ),
    'credits' => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        eyebrow('RUA DA MOEDA · CADA ESCOLHA VALE.'),
        const SizedBox(height: 16),
        body(
          'Conceito e direção: briefing do projeto Rua da Moeda.\nImplementação: Flutter + Flame.\nArte do menu: imagem original gerada com IA.\nCenários e personagens: pixel art original desenhada em código.\n\nUma homenagem ao Recife e às histórias de quem constrói o próprio caminho. Todos os estabelecimentos, produtos e valores são fictícios. O dinheiro do jogo não tem valor real.\n\nCapítulo 1 disponível. Os próximos capítulos ainda não fazem parte desta versão.',
        ),
        button('Voltar', close),
      ],
    ),
    'change' => changeGame(),
    _ => const SizedBox.shrink(),
  };
  Widget dialogueContent() {
    final node = catalog?.nodes[dialogue];
    if (node == null) return body('A conversa está sendo carregada.');
    final text = node.text
        .replaceAll('{name}', s.name)
        .replaceAll('{profile}', s.profile.toLowerCase());
    final chunks = text.split(RegExp(r'(?<=[.!?])\s+'));
    final step = s.textSpeed == 'Imediata'
        ? chunks.length
        : s.textSpeed == 'Rápida'
        ? 2
        : 1;
    final visible = (revealed + step).clamp(1, chunks.length);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 48,
              height: 64,
              child: CustomPaint(
                painter: PersonPreview(
                  [
                    'Seu Chico',
                    'Bia',
                    'Clara',
                    'Dona Lúcia',
                    'Nando',
                  ].indexOf(node.speaker).clamp(0, 3),
                  1,
                  node.speaker == 'Seu Chico' ? 2 : 0,
                  node.speaker == 'Seu Chico' ? 1 : 0,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: eyebrow('RECIFE ANTIGO  /  CONVERSA')),
          ],
        ),
        const SizedBox(height: 16),
        body(chunks.take(visible).join(' ')),
        if (visible < chunks.length)
          button(
            'Continuar  ▾',
            () => setState(() => revealed = visible),
            primary: true,
          )
        else
          ...node.options.map((o) => button(o.label, () => choose(o))),
      ],
    );
  }

  Widget pauseContent() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      eyebrow('${s.name.toUpperCase()} · ${titles[s.level]}'),
      const SizedBox(height: 18),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          menuTile(
            'Carteira',
            Icons.account_balance_wallet,
            'wallet',
            unlocked: s.completed.contains(0),
          ),
          menuTile(
            'Missões',
            Icons.auto_stories,
            'quests',
            unlocked: s.completed.contains(0),
          ),
          menuTile(
            'Planejamento',
            Icons.event_note,
            'planning',
            unlocked: s.completed.contains(0),
          ),
          menuTile('Mochila', Icons.backpack, 'inventory'),
          menuTile('Mapa', Icons.map, 'map'),
          menuTile('Perfil', Icons.person, 'profile'),
        ],
      ),
      rule(),
      button('Continuar explorando', close, primary: true),
      button('Configurações', () => show('settings')),
      button('Como jogar', () => show('help')),
      button('Salvar e voltar ao início', () async {
        await s.save();
        game!.freeze(true);
        audio.pause();
        setState(() {
          screen = 'menu';
          overlay = null;
        });
      }),
    ],
  );
  Widget menuTile(
    String label,
    IconData icon,
    String id, {
    bool unlocked = true,
  }) => SizedBox(
    width: 150,
    child: OutlinedButton(
      onPressed: unlocked ? () => show(id) : null,
      child: Column(
        children: [
          Icon(unlocked ? icon : Icons.lock_outline),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    ),
  );
  Widget wallet() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      eyebrow('DINHEIRO FICTÍCIO · DIA ${s.day}'),
      const SizedBox(height: 8),
      Text(
        reais(s.finance.balance),
        style: const TextStyle(
          fontSize: 34,
          color: gold,
          fontWeight: FontWeight.bold,
        ),
      ),
      stat('Receitas', reais(s.finance.income), color: mint),
      stat('Despesas pagas', reais(s.finance.expenses)),
      stat('Reserva separada', reais(s.finance.reserve)),
      stat('Obrigações não pagas', reais(s.finance.future)),
      body(
        'Reserva é uma transferência entre seus recursos, não uma despesa. O orçamento planejado não é descontado do saldo.',
        color: mint,
      ),
      Wrap(
        spacing: 8,
        children: [
          OutlinedButton(
            onPressed: () => guard(() => s.reserveMoney(5000)),
            child: const Text('Guardar R\$ 50'),
          ),
          OutlinedButton(
            onPressed: () => guard(() => s.reserveMoney(5000, withdraw: true)),
            child: const Text('Retirar R\$ 50'),
          ),
        ],
      ),
      rule(),
      const Text('CONTAS A PAGAR', style: TextStyle(color: gold)),
      if (s.finance.bills.isEmpty) body('Nenhuma conta parcelada registrada.'),
      ...s.finance.bills.map(
        (b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${b.label}\nDia ${b.due} · ${b.paid
                      ? 'Paga'
                      : b.due < s.day
                      ? 'Vencida'
                      : b.due == s.day
                      ? 'Vence hoje'
                      : 'Futura'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: !b.paid && b.due <= s.day ? gold : cream,
                  ),
                ),
              ),
              Text(reais(b.amount)),
              const SizedBox(width: 8),
              if (!b.paid)
                TextButton(
                  onPressed: () => guard(() => s.payBill(b.id)),
                  child: const Text('Pagar'),
                ),
            ],
          ),
        ),
      ),
      rule(),
      const Text('EXTRATO', style: TextStyle(color: gold)),
      if (s.finance.entries.isEmpty)
        body('O extrato começa com a sua primeira renda.'),
      ...s.finance.entries.reversed.map(
        (e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Dia ${e.day} · ${e.label}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              Text(
                '${e.kind == 'income'
                    ? '+'
                    : e.kind == 'expense'
                    ? '-'
                    : '↔'} ${reais(e.amount)}',
                style: TextStyle(
                  fontSize: 11,
                  color: e.kind == 'income' ? mint : gold,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
  Widget budget() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      body(
        'Renda de referência: R\$ 1.200. Despesas essenciais planejadas: R\$ 900. Distribua os R\$ 300 restantes. Nenhuma conta será paga por esta tela.',
      ),
      stat('Moradia', 'R\$ 500,00'),
      stat('Alimentação', 'R\$ 240,00'),
      stat('Transporte', 'R\$ 100,00'),
      stat('Comunicação', 'R\$ 60,00'),
      rule(),
      stat('Reserva planejada', reais(reservePlan * 100)),
      Slider(
        value: reservePlan.toDouble(),
        min: 0,
        max: 300,
        divisions: 30,
        onChanged: (v) => setState(() {
          reservePlan = v.round();
          leisurePlan = math.min(leisurePlan, 300 - reservePlan);
        }),
      ),
      stat('Lazer e qualidade de vida', reais(leisurePlan * 100)),
      Slider(
        value: leisurePlan.toDouble(),
        min: 0,
        max: (300 - reservePlan).toDouble(),
        divisions: math.max(1, (300 - reservePlan) ~/ 10),
        onChanged: (v) => setState(() => leisurePlan = v.round()),
      ),
      stat('Metas pessoais', reais((300 - reservePlan - leisurePlan) * 100)),
      button(
        'Salvar meu planejamento',
        () => guard(() {
          s.plan(
            reservePlan * 100,
            leisurePlan * 100,
            (300 - reservePlan - leisurePlan) * 100,
          );
          tell(
            'Meu primeiro orçamento',
            'Planejamento salvo! Os R\$ 900 essenciais e os R\$ 300 distribuídos são intenções. Seu saldo continua ${reais(s.finance.balance)}. Para separar uma reserva de verdade dentro do jogo, faça uma transferência na carteira. +150 XP na primeira conclusão.',
          );
        }),
        primary: true,
      ),
    ],
  );
  Widget planning() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (s.finance.budget.isEmpty)
        body(
          'Procure Clara no Banco Aurora para montar seu primeiro orçamento.',
        )
      else ...[
        eyebrow('ORÇAMENTO PLANEJADO · REFERÊNCIA MENSAL'),
        const SizedBox(height: 12),
        ...s.finance.budget.entries.map(
          (e) => Column(
            children: [
              stat(e.key, reais(e.value)),
              LinearProgressIndicator(
                value: e.value / 120000,
                color: e.key == 'Reserva' ? mint : gold,
                backgroundColor: panel,
                minHeight: 5,
              ),
            ],
          ),
        ),
        rule(),
        body(
          'A meta pessoal é uma intenção de uso do restante do orçamento. O valor alocado não sai da carteira. Reveja o plano quando renda ou necessidades mudarem.',
        ),
      ],
      stat('Reserva atual', reais(s.finance.reserve)),
      stat('Meta inicial de reserva', 'R\$ 300,00'),
      LinearProgressIndicator(
        value: (s.finance.reserve / 30000).clamp(0, 1),
        color: mint,
      ),
      const SizedBox(height: 18),
      button('Ver contas e transferir reserva', () => show('wallet')),
      if (s.completed.contains(1))
        button('Revisar distribuição do orçamento', () => show('budget')),
    ],
  );
  Widget quests() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      eyebrow('CAPÍTULO 01 · O PRIMEIRO PASSO'),
      const SizedBox(height: 16),
      ...List.generate(
        5,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${s.completed.contains(i)
                    ? '✓'
                    : s.activeQuest == i
                    ? '◆'
                    : '○'} ${questNames[i]}',
                style: TextStyle(
                  color: s.completed.contains(i) ? mint : gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.completed.contains(i)
                    ? 'Concluída · recompensa registrada'
                    : i == s.activeQuest
                    ? s.objective
                    : i == 4
                    ? 'Dona Lúcia · três situações de troco'
                    : 'Continue a história para desbloquear.',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '${[100, 150, 150, 200, 75][i]} XP${i == 0
                    ? ' · R\$ 1.200'
                    : i == 4
                    ? ' · Chapéu de frevo'
                    : ''}',
                style: const TextStyle(fontSize: 10, color: mint),
              ),
              if (i == 0 && !s.completed.contains(0))
                Text(
                  'Seu Chico ${s.flags.contains('intro') ? '✓' : '○'} · Bia ${s.visited.contains('bia') ? '✓' : '○'} · Rua comercial ${s.flags.contains('street') ? '✓' : '○'}',
                  style: const TextStyle(fontSize: 10),
                ),
            ],
          ),
        ),
      ),
    ],
  );
  Widget inventory() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (s.inventory.isEmpty)
        body(
          'Sua mochila ainda está leve. Converse, explore e complete atividades.',
        ),
      ...s.inventory.map(
        (item) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            item == 'Chapéu de frevo'
                ? Icons.celebration
                : Icons.inventory_2_outlined,
            color: gold,
          ),
          title: Text(item),
          subtitle: Text(
            item == 'Comparador de preços'
                ? 'Novo: R\$ 400 · parcelado: R\$ 480 · recondicionado: R\$ 280'
                : 'Uma lembrança da sua aventura.',
            style: const TextStyle(fontSize: 11),
          ),
          trailing: item == 'Chapéu de frevo'
              ? TextButton(
                  onPressed: () {
                    s.accessory = s.accessory == 1 ? 0 : 1;
                    s.changed();
                  },
                  child: Text(s.accessory == 1 ? 'Retirar' : 'Usar'),
                )
              : null,
        ),
      ),
    ],
  );
  Widget mapContent() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      eyebrow('RECIFE ANTIGO · REPRESENTAÇÃO ESTILIZADA'),
      const SizedBox(height: 16),
      AspectRatio(
        aspectRatio: 768 / 576,
        child: CustomPaint(painter: MiniMapPainter(s)),
      ),
      const SizedBox(height: 16),
      body(
        'Norte: Banco Aurora, mercado e Nando.\nCentro: Marco Zero e Seu Chico.\nLeste: Bia, trabalhos e ponte.\nSudoeste: sua casa, descanso e planejamento.',
      ),
      Text(
        'Locais visitados: ${s.visited.map((v) => {'chico': 'Seu Chico', 'bia': 'Bia', 'clara': 'Clara', 'nando': 'Nando', 'lucia': 'Dona Lúcia'}[v] ?? v).join(', ')}',
        style: const TextStyle(fontSize: 11, color: mint),
      ),
    ],
  );
  Widget profileContent() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Center(
        child: SizedBox(
          width: 100,
          height: 110,
          child: CustomPaint(
            painter: PersonPreview(s.shirt, s.skin, s.hair, s.accessory),
          ),
        ),
      ),
      stat(s.name, titles[s.level]),
      stat('Experiência', '${s.xp} XP'),
      stat('Missões concluídas', '${s.completed.length}/5'),
      stat('Dias de aventura', '${s.day}'),
      rule(),
      body(
        'Seu ponto de partida: ${s.profile}. O progresso reconhece aprendizado, exploração e decisões — dinheiro acumulado é só uma parte da história.',
      ),
      const Text('CONQUISTAS', style: TextStyle(color: gold)),
      const SizedBox(height: 12),
      ...[
        'Primeiro Salário',
        'Meu Primeiro Orçamento',
        'Consumidor Consciente',
        'Primeira Reserva',
        'Planejador do Futuro',
        'O Troco Certo',
      ].map(
        (a) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            '${s.achievements.contains(a) ? '✦' : '◇'} $a',
            style: TextStyle(
              color: s.achievements.contains(a)
                  ? mint
                  : const Color(0xff829397),
            ),
          ),
        ),
      ),
    ],
  );
  Widget settings() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Música e efeitos'),
        value: s.sound,
        onChanged: (v) {
          s.sound = v;
          s.changed();
          syncAudio();
        },
      ),
      stat('Volume', '${(s.volume * 100).round()}%'),
      Slider(
        value: s.volume,
        onChanged: (v) {
          s.volume = v;
          s.changed();
          syncAudio();
        },
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Reduzir animações'),
        subtitle: const Text(
          'Desativa balanço, caminhada e ondas.',
          style: TextStyle(fontSize: 11),
        ),
        value: s.reduceMotion,
        onChanged: (v) {
          s.reduceMotion = v;
          s.changed();
        },
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: s.textSpeed,
        decoration: const InputDecoration(labelText: 'Avanço de texto'),
        items: [
          'Normal',
          'Rápida',
          'Imediata',
        ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) {
          s.textSpeed = v!;
          s.changed();
        },
      ),
      const SizedBox(height: 20),
      body(
        'O texto sempre avança por sua ação. Você pode ler no seu ritmo. A trilha e os efeitos são originais. O jogo também funciona sem áudio.',
        color: mint,
      ),
      button('Voltar ao jogo', close, primary: true),
    ],
  );
  Widget changeGame() {
    if (s.completed.contains(4)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          body(
            'Três situações concluídas! Você ganhou 75 XP e um chapéu de frevo. A recompensa já está na mochila.',
          ),
          button('Ver meu chapéu', () => show('inventory'), primary: true),
        ],
      );
    }
    final round = s.sideRound.clamp(0, 2);
    final questions = [
      'Uma compra custa R\$ 7,50. O pagamento foi de R\$ 20. Quanto devolver?',
      'A compra custa R\$ 31,75. O pagamento foi de R\$ 50. Qual é o troco?',
      'Os itens somam R\$ 73,70. O pagamento foi de R\$ 100. Qual é o troco?',
    ];
    final answers = [
      [1150, 1250, 1350],
      [1725, 1925, 1825],
      [2630, 2730, 3630],
    ][round];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        eyebrow('SITUAÇÃO ${round + 1} DE 3 · SEM PERDA DE DINHEIRO'),
        const SizedBox(height: 16),
        body(questions[round]),
        ...answers.map(
          (a) => button(reais(a), () {
            final correct = s.answerChange(a);
            setState(
              () => changeHint = correct
                  ? 'Muito bem! Próxima situação.'
                  : 'Tente novamente: troco = pagamento − valor da compra.',
            );
          }),
        ),
        if (changeHint.isNotEmpty) body(changeHint, color: mint),
      ],
    );
  }
}

class MiniMapPainter extends CustomPainter {
  final GameSession session;
  MiniMapPainter(this.session);
  @override
  void paint(Canvas c, Size size) {
    c.scale(size.width / 768, size.height / 576);
    pixel(c, 0, 0, 768, 576, 0xff3e8e9d);
    pixel(c, 16, 16, 672, 456, 0xffd4c49d);
    pixel(c, 16, 224, 656, 50, 0xff8a9c98);
    for (final p in places) {
      pixel(
        c,
        p.bounds.left,
        p.bounds.top,
        p.bounds.width,
        p.bounds.height,
        p.color,
      );
      tinyText(
        c,
        p.name,
        p.bounds.center.dx,
        p.bounds.center.dy,
        size: 10,
        color: ink,
      );
    }
    c.drawCircle(const Offset(368, 360), 60, Paint()..color = gold);
    tinyText(c, 'MARCO ZERO', 368, 352, size: 11, color: ink);
    tinyText(c, 'BIA', 544, 382, size: 12, color: ink);
    tinyText(c, 'N ↑', 638, 40, size: 15, color: ink);
    final position = session.map == 'outside'
        ? Offset(session.x, session.y)
        : places.firstWhere((p) => p.id == session.map).bounds.center;
    c.drawCircle(position, 9, Paint()..color = const Color(0xffd65067));
    c.drawCircle(position, 4, Paint()..color = cream);
  }

  @override
  bool shouldRepaint(covariant MiniMapPainter old) => true;
}
