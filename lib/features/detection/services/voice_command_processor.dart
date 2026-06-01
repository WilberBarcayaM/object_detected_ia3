class VoiceCommandProcessor {
  static const Set<String> supportedObjects = <String>{
    'cama',
    'camas',
    'grada',
    'gradas',
    'mesa',
    'mesas',
    'puerta',
    'puertas',
  };

  static const Map<String, String> objectAliases = <String, String>{
    'camas': 'cama',
    'gradas': 'grada',
    'mesas': 'mesa',
    'puertas': 'puerta',
  };

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
