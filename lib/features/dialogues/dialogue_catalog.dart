import 'dart:convert';

import 'package:flutter/services.dart';

class DialogueOption {
  final String label;
  final String? action, next;
  DialogueOption(Map<String, dynamic> j)
    : label = j['label'],
      action = j['action'],
      next = j['next'];
}

class DialogueNode {
  final String speaker, text;
  final List<DialogueOption> options;
  DialogueNode(Map<String, dynamic> j)
    : speaker = j['speaker'],
      text = j['text'],
      options = (j['options'] as List)
          .map((o) => DialogueOption(Map<String, dynamic>.from(o)))
          .toList();
}

class DialogueCatalog {
  final Map<String, DialogueNode> nodes;
  DialogueCatalog(this.nodes);
  static Future<DialogueCatalog> load() async {
    final j = jsonDecode(
      await rootBundle.loadString('assets/data/dialogues.json'),
    ) as Map<String, dynamic>;
    return DialogueCatalog(
      j.map(
        (key, value) =>
            MapEntry(key, DialogueNode(Map<String, dynamic>.from(value))),
      ),
    );
  }
}
