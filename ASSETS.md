# Recursos originais

| Recurso | Arquivo / origem | Uso |
|---|---|---|
| Logo Rua da Moeda | `visual/logo.png`, fornecida pelo usuário | Menu e ícone web; cópia idêntica em `web/logo.png` |
| Recife Antigo ao pôr do sol | `assets/images/recife_title.png` | Menu e criação de personagem |
| Personagens, terrenos, fachadas, mobiliário, plantas, barcos e efeitos | `lib/game/pixel_art.dart`, `lib/game/recife_cash_game.dart` | Arte original desenhada em código, sem sprites de terceiros |
| Rosa dos ventos | `web/favicon.svg` | Ícone vetorial original |
| Tema do Marco Zero | `assets/audio/marco_zero.wav` | Loop original de chiptune com ritmo sincopado |
| Tema dos interiores | `assets/audio/interior.wav` | Loop original mais calmo |
| Passo, interação e conquista | `assets/audio/step.wav`, `interact.wav`, `success.wav` | Efeitos sintetizados originais |

A imagem do menu foi produzida com a ferramenta integrada `image_gen`, sem referências a assets de jogos existentes. O arquivo final está dentro do projeto. A imagem é uma ilustração de menu; o mapa jogável é uma camada própria e não uma imagem estática usada para simular exploração.

Prompt usado:

> Use case: stylized-concept. Asset type: original title-screen background for a Brazilian 16-bit top-down RPG, Recife Cash. Wide landscape 1536x1024. Beautiful detailed original pixel art of Recife Antigo and Marco Zero in Pernambuco: colorful colonial waterfront buildings in ochre, terracotta, mint and coral; turquoise river with small boats, palm trees, patterned stone plaza with compass rose, warm golden late afternoon, distant bridge, lush tropical vegetation. View slightly aerial top-down RPG diorama. Crisp square pixels, limited harmonious palette, no blur, artisanal 16-bit aesthetic, welcoming grown-up adventure mood. Composition: architecture and plaza on right and bottom, dark navy river and sky with quiet negative space on left for game title and buttons overlaid by code. No lettering, no logos, no UI, no people copied from existing games, no watermark. This is background illustration only; playable world is rendered separately.

O gerador determinístico `node tools/generate_audio.cjs` reproduz os cinco WAVs. Não usa gravações, samples ou composições externas. A influência regional é conceitual; não pretende representar uma gravação autêntica de frevo ou maracatu. Não existem ainda trilhas exclusivas para cada loja ou missão.

Os recursos criados para este projeto podem ser usados como parte dele. Não se afirma exclusividade autoral sobre conteúdo gerado por IA. Nenhum recurso de Pokémon, Stardew Valley ou de outro jogo foi incorporado. Material Icons e os arquivos de plataforma vêm dos pacotes e templates Flutter e mantêm suas licenças; consulte `flutter pub deps` e a tela de licenças do ecossistema Flutter quando preparar uma distribuição. Os ícones de launcher Android/iOS ainda são os padrões do template e precisam ser substituídos antes da publicação nas lojas.

Organização atual: bitmap do menu em `assets/images`, áudio em `assets/audio`, narrativa em `assets/data`. Personagens, NPCs, construções, terreno, vegetação, objetos, interface e animações do mundo são código nativo editável; não existem referências a spritesheets ausentes.
