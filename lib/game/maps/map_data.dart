import 'dart:ui';

class Place {
  final String id, name;
  final Rect bounds;
  final int color;
  const Place(this.id, this.name, this.bounds, this.color);
  Offset get door => Offset(bounds.center.dx, bounds.bottom + 7);
}

const places = [
  Place('bank', 'BANCO AURORA', Rect.fromLTWH(64, 80, 128, 112), 0xffe5b955),
  Place(
    'market',
    'MERCADO DE LÚCIA',
    Rect.fromLTWH(240, 96, 128, 96),
    0xffdd8070,
  ),
  Place(
    'electronics',
    'NANDO • ELETRÔNICOS',
    Rect.fromLTWH(416, 80, 144, 112),
    0xff6ab7ae,
  ),
  Place('home', 'SUA CASA', Rect.fromLTWH(64, 352, 112, 96), 0xff8a9dc0),
];

class WorldTarget {
  final String id, name;
  final Offset position;
  final bool person;
  const WorldTarget(this.id, this.name, this.position, {this.person = false});
}

List<WorldTarget> targetsFor(String map) => map == 'outside'
    ? [
        const WorldTarget('chico', 'Seu Chico', Offset(360, 328), person: true),
        const WorldTarget('bia', 'Bia', Offset(544, 376), person: true),
        const WorldTarget('sign', 'Placa do Marco Zero', Offset(432, 422)),
        ...places.map(
          (p) => WorldTarget('door-${p.id}', 'Entrar • ${p.name}', p.door),
        ),
      ]
    : [
        const WorldTarget('exit', 'Sair', Offset(192, 252)),
        if (map == 'bank')
          const WorldTarget('clara', 'Clara', Offset(192, 132), person: true),
        if (map == 'market')
          const WorldTarget(
            'lucia',
            'Dona Lúcia',
            Offset(192, 132),
            person: true,
          ),
        if (map == 'electronics')
          const WorldTarget('nando', 'Nando', Offset(192, 132), person: true),
        if (map == 'home') ...[
          const WorldTarget('bed', 'Descansar e salvar', Offset(104, 118)),
          const WorldTarget('desk', 'Seu planejamento', Offset(264, 116)),
        ],
      ];
List<Rect> solidsFor(String map) => map == 'outside'
    ? [
        ...places.map((p) => p.bounds),
        const Rect.fromLTWH(0, 480, 768, 96),
        const Rect.fromLTWH(688, 0, 80, 352),
        const Rect.fromLTWH(688, 400, 80, 80),
        const Rect.fromLTWH(600, 76, 40, 36),
        const Rect.fromLTWH(208, 392, 38, 10),
        const Rect.fromLTWH(592, 424, 38, 10),
        const Rect.fromLTWH(688, 350, 80, 4),
        const Rect.fromLTWH(688, 398, 80, 4),
        const Rect.fromLTWH(428, 418, 6, 9),
        const Rect.fromLTWH(240, 294, 22, 8),
        const Rect.fromLTWH(560, 294, 22, 8),
        for (final p in [
          const Offset(32, 104),
          const Offset(208, 112),
          const Offset(592, 168),
          const Offset(32, 328),
          const Offset(208, 352),
          const Offset(640, 320),
        ])
          Rect.fromLTWH(p.dx + 1, p.dy - 10, 7, 15),
        const Rect.fromLTWH(46, 438, 7, 15),
        const Rect.fromLTWH(646, 442, 7, 15),
      ]
    : [
        const Rect.fromLTWH(32, 32, 320, 40),
        if (map == 'home') ...[
          const Rect.fromLTWH(80, 80, 40, 28),
          const Rect.fromLTWH(248, 80, 48, 30),
        ] else
          const Rect.fromLTWH(128, 88, 128, 26),
        const Rect.fromLTWH(48, 176, 32, 32),
        const Rect.fromLTWH(304, 176, 32, 32),
      ];
