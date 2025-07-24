class ProfanityFilterService {
  static final List<String> _profanityList = [
    // Lista básica de palabras prohibidas en español
    'puta', 'puto', 'pendejo', 'pendeja', 'mierda', 'verga',
    'culero', 'culera', 'chingar', 'chingada', 'chingado',
    'mamar', 'mamada', 'joder', 'jodido', 'cabrón', 'cabrona',
    'pinche', 'güey', 'wey', 'estúpido', 'estúpida', 'idiota',
    'imbécil', 'tarado', 'tarada', 'pene', 'vagina', 'culo',
    'tetas', 'coño', 'pija', 'concha', 'pete', 'chupar',
    'coger', 'follar', 'violar', 'violador', 'pedófilo',
    'nazi', 'hitler', 'racista', 'discriminar',
  ];

  static final List<String> _commonSubstitutions = [
    '0' , 'o',
    '1' , 'i',
    '3' , 'e',
    '4' , 'a',
    '5' , 's',
    '@' , 'a',
    '!' , 'i',
    '\$' , 's',
  ];

  static bool containsProfanity(String text) {
    if (text.isEmpty) return false;
    
    String normalizedText = _normalizeText(text);
    
    for (String profanity in _profanityList) {
      String normalizedProfanity = _normalizeText(profanity);
      
      // Verificar coincidencia exacta
      if (normalizedText.contains(normalizedProfanity)) {
        return true;
      }
      
      // Verificar con sustituciones comunes
      String textWithSubstitutions = _applySubstitutions(normalizedText);
      if (textWithSubstitutions.contains(normalizedProfanity)) {
        return true;
      }
    }
    
    return false;
  }

  static String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static String _applySubstitutions(String text) {
    String result = text;
    for (int i = 0; i < _commonSubstitutions.length; i += 2) {
      result = result.replaceAll(_commonSubstitutions[i], _commonSubstitutions[i + 1]);
    }
    return result;
  }

  static String? validateUsername(String username) {
    if (username.isEmpty) {
      return 'El nombre de usuario no puede estar vacío';
    }
    
    if (username.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    
    if (containsProfanity(username)) {
      return 'El nombre contiene palabras no permitidas';
    }
    
    return null;
  }
}