# Verificação do MVP

Ambiente: Windows, Flutter 3.47.9 stable, Dart 3.13.7 e Edge 122.0.2365.106. As verificações abaixo foram executadas durante o desenvolvimento em 6 de novembro de 2026.

## Comandos

```powershell
flutter test
flutter analyze
flutter build web --release --no-wasm-dry-run
```

Nesta instalação, foi usado o Dart do SDK para executar `C:\flutter\bin\cache\flutter_tools.snapshot`, com `C:\flutter\bin\mingit\cmd` adicionado ao PATH, por problemas no wrapper `flutter.bat`. O equivalente para repetir é `tools/flutter.ps1`.

## Cobertura

Resultado final: **27 testes passaram**, `flutter analyze` concluiu com **No issues found**, e `flutter build web --release --no-wasm-dry-run` gerou `build/web`. O smoke test da versão final no Edge registrou **zero exceções JavaScript**; as capturas finais mostram o personagem, a praça corretamente enquadrada e o diálogo com Seu Chico.

A suíte de 27 testes e a análise estática também passaram após renomear a pasta e o pacote para `rua_da_moeda` e integrar a logo fornecida em `visual/logo.png`. A chave de armazenamento original foi mantida para preservar os saves existentes.

27 testes automatizados:

- 9 testes financeiros: saldo, crédito/débito, centavos, valores inválidos, operações repetidas, reserva, planejamento sem pagamento, criação de parcelas, pagamentos e serialização.
- 12 testes de sessão: dependências e recompensas de missões, quatro escolhas de celular, alternativas de imprevisto, recuperação de reserva, calendário, trabalho diário, dificuldade e recompensa do troco, persistência e save inválido.
- 6 testes de mundo/interface: colisões, busca de caminhos até todos os pontos obrigatórios, movimentação, posição real da câmera, bloqueio por modal, transições, menu, criação e viewport horizontal 740 × 360.

O teste completo de interface percorre as quatro missões, escolhe o celular parcelado, paga o conserto e conclui as três situações de troco. Confere saldo de R$ 1.080, cinco parcelas futuras, 675 XP, item cosmético e restauração do save. Para manter o teste rápido, o personagem é posicionado próximo dos alvos; as interações usam o detector espacial e os botões reais. O deslocamento contínuo e a acessibilidade dos caminhos têm testes separados.

## Navegador

A versão de produção foi servida por `node tools/serve.cjs` e aberta no Edge em modo headless, com perfil separado em `tools/browser-profile`. Capturas ficam em `output/browser-menu.png`, `browser-creation.png`, `browser-world.png` e `browser-dialogue.png`. O script opcional `tools/browser_check.cjs` usa CDP na porta 9222 e Node com WebSocket integrado; testa criação, entrada no mundo e conversa via teclas. Ele limpa somente o armazenamento do perfil isolado usado no teste. Não aponte esse script para seu perfil pessoal.

A inspeção visual detectou e levou à correção do enquadramento da câmera: `Viewfinder.position` precisa receber um novo vetor pelo setter. O teste de engine verifica agora as coordenadas da câmera ao iniciar, andar e entrar em um interior. Também foi ajustada a largura do menu e corrigido o Material dos controles de configuração.

## Plataformas e limites

- **Web:** compilação de produção, testes Flutter e smoke test no Edge. O jogo não foi publicado em serviço externo.
- **Android:** o SDK está instalado. A tentativa de gerar APK foi interrompida a pedido do usuário; nenhum APK é entregue ou declarado validado. O layout de toque foi verificado por teste Flutter, sem dispositivo Android em execução.
- **iOS:** fontes de plataforma geradas; compilação, assinatura e execução pendentes de um Mac/Xcode.
- **Áudio:** WAVs originais presentes e integração com controle de volume. A avaliação auditiva em dispositivos reais permanece pendente. Falhas de áudio não bloqueiam o jogo.
- Os testes não equivalem a QA completo de acessibilidade, desempenho, navegadores e dispositivos físicos. Não há garantia de salvar o último frame em caso de encerramento abrupto do processo ou indisponibilidade do armazenamento.

Antes de uma distribuição pública, revisar ícones de launcher, licenças distribuídas, contraste em telas pequenas, leitura assistiva, áudio, assinatura e testes em aparelhos reais. Capítulos 2–6, importação TMX e metas múltiplas não fazem parte desta entrega.
