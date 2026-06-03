import 'package:flutter/services.dart' show rootBundle;

class VoiceCommandProcessor {
  // --- CÓDIGO DEL MODELO ANTERIOR (4 OBJETOS) - COMENTADO PARA NO PERDERLO ---
  /*
  static Set<String> supportedObjects = <String>{
    'cama',
    'camas',
    'grada',
    'gradas',
    'mesa',
    'mesas',
    'puerta',
    'puertas',
  };

  static Map<String, String> objectAliases = <String, String>{
    'camas': 'cama',
    'gradas': 'grada',
    'mesas': 'mesa',
    'puertas': 'puerta',
  };
  */

  // --- MODELO COCO (80 OBJETOS) - Se llenan dinámicamente desde assets/labels_coco.txt ---
  static Set<String> supportedObjects = {};
  static Map<String, String> objectAliases = {};

  static Future<void> loadLabels() async {
    try {
      final data = await rootBundle.loadString('assets/labels_coco.txt');
      final lines = data.split('\n');
      final Set<String> loaded = {};
      final Map<String, String> aliases = {};
      for (var line in lines) {
        final label = normalizeText(line.trim());
        if (label.isNotEmpty) {
          loaded.add(label);
          final plural = getPlural(label);
          loaded.add(plural);
          aliases[plural] = label;
        }
      }
      supportedObjects = loaded;
      objectAliases = aliases;
      print('VoiceCommandProcessor: Loaded ${supportedObjects.length} objects (including plurals).');
    } catch (e) {
      print('VoiceCommandProcessor error loading labels: $e');
    }
  }

  static String getPlural(String singular) {
    if (singular.isEmpty) return '';
    final vowels = {'a', 'e', 'i', 'o', 'u'};
    final lastChar = singular[singular.length - 1];
    if (vowels.contains(lastChar)) {
      return '${singular}s';
    }
    final esConsonants = {'d', 'j', 'l', 'n', 'r', 'z'};
    if (esConsonants.contains(lastChar)) {
      if (lastChar == 'z') {
        return '${singular.substring(0, singular.length - 1)}ces';
      }
      return '${singular}es';
    }
    return '${singular}s';
  }

  static String normalizeText(String s) {
    final Map<String, String> map = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'Á': 'a',
      'À': 'a',
      'Ä': 'a',
      'Â': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'É': 'e',
      'È': 'e',
      'Ë': 'e',
      'Ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'Í': 'i',
      'Ì': 'i',
      'Ï': 'i',
      'Î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'Ó': 'o',
      'Ò': 'o',
      'Ö': 'o',
      'Ô': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'Ú': 'u',
      'Ù': 'u',
      'Ü': 'u',
      'Û': 'u',
      'ñ': 'n',
      'Ñ': 'n',
      ',': ' ',
      '.': ' ',
      ';': ' ',
      ':': ' ',
      '!': ' ',
      '?': ' ',
      '"': ' ',
      "'": ' '
    };
    String out = s.toLowerCase();
    map.forEach((k, v) {
      out = out.replaceAll(k, v);
    });
    out = out.replaceAll(RegExp('\\s+'), ' ').trim();
    return out;
  }

  static String canonicalObjectName(String objectName) {
    final normalized = normalizeText(objectName);
    return objectAliases[normalized] ?? normalized;
  }

  static bool isCompleteVoiceCommand(String text) {
    if (text.isEmpty) return false;
    if (text.contains('instrucciones') || text.contains('ayuda')) return true;
    if (text.startsWith('buscar ')) {
      return text.split(' ').length >= 2;
    }
    return false;
  }
}
