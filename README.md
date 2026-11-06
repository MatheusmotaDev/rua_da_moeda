# Rua da Moeda: Do Marco Zero ao Futuro

**Cada escolha vale.** RPG 2D jogável em Flutter e Flame, com exploração em tempo real, pixel art original, cinco NPCs, quatro missões principais e uma secundária. Ambientado em uma versão estilizada do Recife Antigo, com economia exclusivamente fictícia.

O projeto e o pacote Dart agora se chamam `rua_da_moeda`. A logo fornecida em `visual/logo.png` aparece no menu e nos ícones web. A chave de salvamento e os identificadores nativos existentes foram preservados para manter a compatibilidade com as partidas anteriores.

## Jogar a versão web compilada

Na pasta do projeto, com Node instalado:

```powershell
node tools/serve.cjs
```

Abra **http://127.0.0.1:8080**. Esse comando serve `build/web`, gerado pela compilação. Não abra `index.html` diretamente pelo sistema de arquivos. Se `build/web` não existir, execute a compilação abaixo primeiro. Os recursos de renderização estão incluídos no build; não há API bancária, login ou backend de gameplay.

## Desenvolver e compilar

Ambiente usado: Flutter 3.47.9 stable / Dart 3.13.7. Dependências principais: Flame 1.38.2, shared_preferences 2.5.6 e audioplayers 6.8.1. O `pubspec.lock` registra as versões resolvidas.

```powershell
cd rua_da_moeda
flutter pub get
flutter run -d edge
flutter test
flutter analyze
flutter build web --release
```

O wrapper `flutter.bat` instalado nesta máquina apresentou problemas de acesso ao cache e de localização de Git. O projeto inclui um auxiliar PowerShell que usa o mesmo SDK e o Git incluído nele, sem alterar a instalação:

```powershell
.\tools\flutter.ps1 pub get
.\tools\flutter.ps1 run -d edge
.\tools\flutter.ps1 test
.\tools\flutter.ps1 analyze
.\tools\flutter.ps1 build web --release --no-wasm-dry-run
```

O SDK e o cache de pacotes precisam ter permissão de escrita. Em outro ambiente, prefira os comandos normais do Flutter.

### Android

Com Android SDK/JDK, licenças aceitas e dispositivo ou emulador conectado:

```powershell
flutter devices
flutter run -d <id-do-dispositivo>
flutter build apk --debug
```

Alternativamente, use `.\tools\flutter.ps1` no lugar de `flutter`. O APK de debug, quando a compilação conclui, fica em `build/app/outputs/flutter-apk/app-debug.apk`. O projeto pede orientação horizontal. A distribuição em loja requer ícones próprios, assinatura de release e revisão em dispositivo real.

### iOS

Em um Mac com Xcode e dependências de plataforma configuradas:

```sh
flutter pub get
flutter run -d <id-do-simulador-ou-iphone>
flutter build ios --no-codesign
```

As fontes iOS foram geradas; a compilação e a execução iOS não podem ser verificadas neste Windows.

## Controles e primeiro passeio

- **WASD / setas:** caminhar. O direcional na tela oferece alternativa de toque.
- **E / Enter / espaço:** interagir quando próximo e olhando para o alvo. O botão E mostra o alvo disponível.
- **Esc:** fechar diálogo ou abrir o menu. Mouse/toque navegam nos menus.

Converse com Seu Chico na praça; conheça Bia a leste, perto da ponte; visite a rua comercial ao norte; volte ao mentor para receber R$ 1.200. Em seguida visite Clara no banco, Nando nos eletrônicos e Dona Lúcia no mercado. A atividade de troco fica com Dona Lúcia. Sua casa, a sudoeste, permite descansar e avançar o dia.

Carteira e diário são desbloqueados com a primeira missão. O planejamento não paga despesas. Guardar na reserva exige transferência pela carteira. Parcelar cria obrigações futuras; os pagamentos são explícitos e únicos. Se precisar de recursos, retire da reserva ou faça uma atividade com Bia. O tempo só avança por escolhas.

## Salvamento

Automático nas decisões, nas transições, durante e ao fim do movimento. `Continuar aventura` fica disponível quando há save reconhecido. Uma nova aventura substitui o save local; a criação avisa isso antes do início. Fechar um menu preserva a partida.

O save fica no armazenamento do navegador ou aplicativo, **sem sincronização entre dispositivos**. Apagar os dados do site/aplicativo remove o progresso. Mantenha o mesmo endereço/origem do servidor para continuar a versão web. Não há integração financeira real nem dados bancários.

## Documentação e expansão

- [GAME_DESIGN.md](GAME_DESIGN.md): gameplay, narrativa, economia, progressão e limites.
- [ARCHITECTURE.md](ARCHITECTURE.md): camadas e instruções para adicionar mapas, NPCs, missões e diálogos.
- [ASSETS.md](ASSETS.md): origem da arte, prompt da imagem, recursos e áudio original.
- [TESTING.md](TESTING.md): verificações executadas e limites de validação.

Mapas pequenos são desenhados em tiles no código, sem integração TMX/Flame Tiled nesta versão. ChangeNotifier mantém a sessão; Riverpod não é necessário para o estado local atual. O capítulo 1 está implementado; capítulos 2–6 são expansão futura. As transições são imediatas e as metas financeiras ainda são simplificadas. Os detalhes estão nos documentos acima.

Referências técnicas consultadas: [câmera e mundo no Flame](https://docs.flame-engine.org/latest/flame/camera.html), [entrada de teclado](https://docs.flame-engine.org/latest/flame/inputs/keyboard_input.html), [shared_preferences](https://pub.dev/packages/shared_preferences) e [audioplayers](https://github.com/bluefireteam/audioplayers/blob/main/getting_started.md).
