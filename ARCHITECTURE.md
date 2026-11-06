# Arquitetura

## Camadas

| Caminho | Responsabilidade |
|---|---|
| `lib/main.dart` | Inicialização e abertura do armazenamento |
| `lib/core/storage/save_repository.dart` | Persistência local com SharedPreferences |
| `lib/core/services/sound_service.dart` | Áudio opcional com falhas isoladas do gameplay |
| `lib/features/finance/finance.dart` | Conta, extrato, orçamento, transferências e obrigações |
| `lib/features/session.dart` | Estado serializável, missões, escolhas, progressão e calendário |
| `lib/features/dialogues/dialogue_catalog.dart` | Leitura dos diálogos estruturados |
| `lib/game/recife_cash_game.dart` | Loop Flame, input, câmera, colisões e componentes |
| `lib/game/maps/map_data.dart` | Fachadas, colisões, pontos e IDs estáveis |
| `lib/game/pixel_art.dart` | Desenho dos sprites originais e prévia do avatar |
| `lib/ui/recife_app.dart` | Menu, criação, HUD e overlays Flutter |
| `assets/data/dialogues.json` | Conteúdo narrativo, escolhas, próximos nós e ações |

O serviço Finance não importa Flutter nem Flame. GameSession usa ChangeNotifier para a aplicação observar o estado; não depende de componentes visuais. O mundo referencia a sessão e emite intenções de interação para a interface. `GameWidget` mantém a instância do jogo durante as atualizações de interface.

Para este escopo foi escolhido ChangeNotifier, sem Riverpod: há uma única sessão local e não há fluxo remoto. Os mapas são baseados em tiles e desenhados em código; **Flame Tiled e arquivos TMX ainda não são utilizados**. Essa escolha evita uma cadeia de ferramentas e recursos adicionais para cinco mapas pequenos. Para mapas maiores, o próximo passo é importar TMX e converter as camadas abaixo para os mesmos pontos e colisões.

## Dinheiro e idempotência

Todos os valores financeiros usam `int` em centavos. Identificadores de operação são persistidos em `Finance.operations`. Crédito, débito e transferência repetidos retornam falso sem repetir o efeito. Valores inválidos e saldo insuficiente falham antes da mutação. Parcelamento cria cinco Bills, sem crédito nem débito. Pagamento usa o identificador `pay-<bill-id>`, registra uma despesa e marca a conta paga.

Orçamento é uma distribuição planejada; não altera saldo ou reserva. A reserva é um segundo compartimento da mesma conta fictícia. Transferências aparecem no extrato com tipo próprio, fora dos totais de receita e despesa.

As decisões de campanha são protegidas por dependências e conclusão de missão. XP só é atribuído quando uma missão entra pela primeira vez no conjunto `completed`. O calendário não executa pagamentos automáticos; carregar um save não dispara renda, recompensas ou eventos de dia novamente.

## Salvamento

JSON versionado (`version: 1`), chave `recife_cash.save.v1`, com ID da partida, identidade, cosméticos, mapa, posição, XP, tempo, missões, flags, visitas, conquistas, inventário, escolhas e estado financeiro. As escritas são serializadas para preservar a ordem. Ações relevantes salvam imediatamente; movimento salva a cada dois segundos e ao parar; mudanças de ciclo de vida também solicitam save. Falhas de gravação aparecem no HUD. O save local não é sincronizado entre dispositivos. A versão é validada antes de carregar. Não há migração para versões futuras ainda.

## Mundo

Posição usa ponto nos pés e caixa de colisão 10 × 7. Movimento é normalizado na diagonal e integrado por delta, com subpassos de no máximo aproximadamente três pixels e limite para pausas de frame longas. NPCs sólidos e cenários impedem passagem. Interação exige distância inferior a 30 pixels e direção compatível. Câmera acompanha o jogador com limites; NPCs e jogador usam ordenação pelo eixo Y.

## Como expandir

1. **Mapa:** adicione uma Place com ID estável e seu retângulo em `map_data.dart`; atualize `targetsFor`, `solidsFor` e o desenho em Scenery. Ao adicionar um mapa, atualize a lista de IDs aceitos na restauração. Planeje camadas Ground, DecorationBelow, Buildings, Collision, Interactables, SpawnPoints, NPCPositions e DecorationAbove para futura importação Tiled.
2. **NPC:** adicione um WorldTarget com `person: true`, um NpcComponent no carregamento e sua configuração de aparência. Encaminhe seu ID no método `interact` da UI.
3. **Diálogo:** adicione um nó JSON com `speaker`, `text` e `options`. Cada opção tem `label` e `next` ou `action`. As substituições `{name}` e `{profile}` são resolvidas na exibição. `next` ramifica sem efeito financeiro. Uma nova ação deve chamar um serviço de domínio com ID estável.
4. **Missão:** configure nome, dependências e recompensa na sessão, com marcador no NPC e objetivos visíveis no diário. Para uma campanha maior, extraia as definições de missões e seus objetivos para JSON, mantendo o estado mutável na sessão.
5. **Save:** novos campos opcionais precisam de defaults; mudanças incompatíveis exigem migração de versão, sem descartar silenciosamente o save existente.

As definições de missões e mapas ainda são Dart; apenas os diálogos estão em JSON. Os modelos relacionados são agrupados quando têm ciclo de vida comum, sem criar uma classe vazia para cada termo do briefing.
