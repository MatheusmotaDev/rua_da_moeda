import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/storage/save_repository.dart';
import 'features/session.dart';
import 'features/dialogues/dialogue_catalog.dart';
import 'ui/recife_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await SaveRepository.open();
  final dialogues = await DialogueCatalog.load();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(RecifeApp(session: GameSession(repository), dialogues: dialogues));
}
