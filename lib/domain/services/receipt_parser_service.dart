import '../entities/receipts/parsed_receipt.dart';

/// Servicio para parsear texto de facturas usando regex.
/// Intenta extraer monto, comercio y fecha de facturas colombianas comunes.
class ReceiptParserService {
  /// Intenta parsear el texto OCR de una factura.
  /// Retorna ParsedReceipt si tiene éxito, null si necesita IA.
  ParsedReceipt? parse(String ocrText) {
    if (ocrText.trim().isEmpty) return null;

    final amount = _extractAmount(ocrText);
    if (amount == null) return null;

    final merchant = _extractMerchant(ocrText);
    final date = _extractDate(ocrText);
    final category = _suggestCategory(merchant, ocrText);

    return ParsedReceipt(
      amount: amount,
      merchant: merchant,
      date: date,
      suggestedCategory: category,
      rawText: ocrText,
      parseSource: 'regex',
      confidence: _calculateConfidence(amount, merchant, date),
    );
  }

  /// Extrae el monto total de la factura
  double? _extractAmount(String text) {
    // Patrones de monto total en facturas colombianas
    final patterns = [
      // TOTAL: $85,400 o TOTAL $85.400
      RegExp(r'TOTAL[:\s]*\$?\s*([\d.,]+)', caseSensitive: false),
      // Total a pagar: $85,400
      RegExp(r'Total\s+a\s+pagar[:\s]*\$?\s*([\d.,]+)', caseSensitive: false),
      // VALOR TOTAL: 85400
      RegExp(r'VALOR\s+TOTAL[:\s]*\$?\s*([\d.,]+)', caseSensitive: false),
      // Gran Total: $85,400
      RegExp(r'Gran\s+Total[:\s]*\$?\s*([\d.,]+)', caseSensitive: false),
      // NETO A PAGAR: $85,400
      RegExp(r'NETO\s+A\s+PAGAR[:\s]*\$?\s*([\d.,]+)', caseSensitive: false),
      // Saldo a pagar: $85,400
      RegExp(r'Saldo\s+a\s+pagar[:\s]*\$?\s*([\d.,]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amount = _parseAmountString(match.group(1)!);
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }

    // Fallback: buscar el número más grande que parezca un monto
    return _findLargestAmount(text);
  }

  /// Extrae el nombre del comercio
  String? _extractMerchant(String text) {
    final lines = text.split('\n').map((l) => l.trim()).toList();

    // Patrones de comercios conocidos en Colombia
    final knownMerchants = [
      RegExp(r'EXITO|ALMACENES?\s+EXITO', caseSensitive: false),
      RegExp(r'CARULLA', caseSensitive: false),
      RegExp(r'JUMBO', caseSensitive: false),
      RegExp(r'OLIMPICA|SUPERTIENDAS?\s+OLIMPICA', caseSensitive: false),
      RegExp(r'D1\b', caseSensitive: false),
      RegExp(r'ARA\b', caseSensitive: false),
      RegExp(r'JUSTO\s*&\s*BUENO', caseSensitive: false),
      RegExp(r'HOMECENTER|HOME\s+CENTER', caseSensitive: false),
      RegExp(r'FALABELLA', caseSensitive: false),
      RegExp(r'ALKOSTO', caseSensitive: false),
      RegExp(r'MAKRO', caseSensitive: false),
      RegExp(r'PriceSmart', caseSensitive: false),
      RegExp(r'RAPPI', caseSensitive: false),
      RegExp(r'UBER\s*EATS?', caseSensitive: false),
      RegExp(r'DOMINO', caseSensitive: false),
      RegExp(r'MC\s*DONALDS?|MCDONALD', caseSensitive: false),
      RegExp(r'BURGER\s+KING', caseSensitive: false),
      RegExp(r'STARBUCKS', caseSensitive: false),
      RegExp(r'JUAN\s+VALDEZ', caseSensitive: false),
      RegExp(r'CREPES\s*&?\s*WAFFLES', caseSensitive: false),
      RegExp(r'KOKORIKO', caseSensitive: false),
      RegExp(r'FRISBY', caseSensitive: false),
      RegExp(r'EL\s+CORRAL', caseSensitive: false),
      RegExp(r'PRESTO', caseSensitive: false),
      RegExp(r'CINECOLOMBIA|CINE\s+COLOMBIA', caseSensitive: false),
      RegExp(r'CINEMARK', caseSensitive: false),
      RegExp(r'PROCINAL', caseSensitive: false),
      RegExp(r'CLARO\b', caseSensitive: false),
      RegExp(r'MOVISTAR', caseSensitive: false),
      RegExp(r'TIGO\b', caseSensitive: false),
      RegExp(r'ETB\b', caseSensitive: false),
      RegExp(r'EPM\b', caseSensitive: false),
      RegExp(r'CODENSA|ENEL', caseSensitive: false),
      RegExp(r'GAS\s+NATURAL', caseSensitive: false),
      RegExp(r'ACUEDUCTO', caseSensitive: false),
    ];

    // Buscar comercios conocidos
    for (final pattern in knownMerchants) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _cleanMerchantName(match.group(0)!);
      }
    }

    // Intentar extraer de NIT o razón social
    final nitPattern = RegExp(
      r'(?:NIT|Nit)[:\s]*([\d.-]+)\s*\n?\s*([A-Z][A-Z\s]+)',
      caseSensitive: false,
    );
    final nitMatch = nitPattern.firstMatch(text);
    if (nitMatch != null && nitMatch.group(2) != null) {
      final name = nitMatch.group(2)!.trim();
      if (name.length > 3 && name.length < 50) {
        return _cleanMerchantName(name);
      }
    }

    // Usar primera línea no vacía que parezca un nombre
    for (final line in lines.take(5)) {
      if (line.length > 3 &&
          line.length < 40 &&
          !RegExp(r'^\d').hasMatch(line) &&
          !RegExp(r'fecha|hora|nit|dir|tel', caseSensitive: false)
              .hasMatch(line)) {
        return _cleanMerchantName(line);
      }
    }

    return null;
  }

  /// Extrae la fecha de la factura
  DateTime? _extractDate(String text) {
    // Patrones de fecha comunes en Colombia
    final patterns = [
      // 15/01/2026 o 15-01-2026
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})'),
      // 2026/01/15 o 2026-01-15
      RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})'),
      // 15 ENE 2026 o 15 ENERO 2026
      RegExp(
        r'(\d{1,2})\s+(ENE|FEB|MAR|ABR|MAY|JUN|JUL|AGO|SEP|OCT|NOV|DIC)[A-Z]*\s+(\d{2,4})',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          return _parseDate(match);
        } catch (_) {
          continue;
        }
      }
    }

    return null;
  }

  /// Sugiere una categoría basada en el comercio
  String? _suggestCategory(String? merchant, String text) {
    final searchText = '${merchant ?? ''} $text'.toLowerCase();

    // Mapeo de palabras clave a categorías
    final categoryKeywords = {
      'Alimentación': [
        'exito',
        'carulla',
        'jumbo',
        'olimpica',
        'd1',
        'ara',
        'justo',
        'supermercado',
        'mercado',
        'fruver',
        'carniceria',
        'panaderia',
      ],
      'Restaurantes': [
        'rappi',
        'uber eats',
        'domino',
        'mcdonald',
        'burger',
        'starbucks',
        'juan valdez',
        'crepes',
        'kokoriko',
        'frisby',
        'corral',
        'presto',
        'restaurante',
        'comida',
      ],
      'Entretenimiento': [
        'cine',
        'cinecolombia',
        'cinemark',
        'procinal',
        'teatro',
        'concierto',
      ],
      'Hogar': [
        'homecenter',
        'home center',
        'falabella',
        'alkosto',
        'makro',
        'ferreteria',
      ],
      'Servicios': [
        'claro',
        'movistar',
        'tigo',
        'etb',
        'epm',
        'codensa',
        'enel',
        'gas natural',
        'acueducto',
        'internet',
        'celular',
        'energia',
        'agua',
      ],
      'Transporte': [
        'uber',
        'didi',
        'cabify',
        'indriver',
        'gasolina',
        'tanqueo',
        'peaje',
        'parqueadero',
      ],
      'Salud': [
        'farmacia',
        'drogueria',
        'eps',
        'medicina',
        'consultorio',
        'laboratorio',
      ],
    };

    for (final entry in categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (searchText.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return null;
  }

  /// Parsea un string de monto a double
  double? _parseAmountString(String text) {
    // Limpiar: $45.000 -> 45000, $45,000.00 -> 45000.00
    var cleaned = text.replaceAll(RegExp(r'[^\d.,]'), '');

    // Detectar formato basado en patrones
    final dotCount = '.'.allMatches(cleaned).length;
    final commaCount = ','.allMatches(cleaned).length;

    if (commaCount == 1 && dotCount == 0) {
      // Formato: 125,000 (miles con coma) o 125,50 (decimales con coma)
      final parts = cleaned.split(',');
      if (parts[1].length == 3) {
        // 125,000 -> es separador de miles
        cleaned = cleaned.replaceAll(',', '');
      } else {
        // 125,50 -> es decimal europeo/colombiano
        cleaned = cleaned.replaceAll(',', '.');
      }
    } else if (dotCount == 1 && commaCount == 0) {
      // Puede ser 45.000 (colombiano) o 45.00 (internacional)
      final parts = cleaned.split('.');
      if (parts[1].length == 3) {
        // 45.000 -> colombiano, es separador de miles
        cleaned = cleaned.replaceAll('.', '');
      }
      // Si tiene 2 decimales, es internacional y está bien
    } else if (dotCount > 1 || commaCount > 1) {
      // Múltiples separadores: 1.250.000 o 1,250,000
      // Quitar todos los separadores de miles
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '');
    } else if (dotCount == 1 && commaCount == 1) {
      // Formato mixto: 1.250,00 o 1,250.00
      // Asumir que el último separador es decimal
      if (cleaned.lastIndexOf(',') > cleaned.lastIndexOf('.')) {
        // 1.250,00 - punto es miles, coma es decimal
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // 1,250.00 - coma es miles, punto es decimal
        cleaned = cleaned.replaceAll(',', '');
      }
    }

    return double.tryParse(cleaned);
  }

  /// Busca el monto más grande en el texto (fallback)
  double? _findLargestAmount(String text) {
    final amountPattern = RegExp(r'\$?\s*([\d]{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)');
    final matches = amountPattern.allMatches(text);

    double? largest;
    for (final match in matches) {
      final amount = _parseAmountString(match.group(1)!);
      if (amount != null && amount > 100 && (largest == null || amount > largest)) {
        // Ignorar montos menores a 100 (probablemente no son totales)
        // y mayores a 100M (probablemente errores de OCR)
        if (amount < 100000000) {
          largest = amount;
        }
      }
    }

    return largest;
  }

  /// Parsea una fecha de un match de regex
  DateTime _parseDate(RegExpMatch match) {
    final groups = match.groups([1, 2, 3]);

    // Detectar formato basado en el patrón
    final first = groups[0]!;
    final second = groups[1]!;
    final third = groups[2]!;

    int year, month, day;

    if (first.length == 4) {
      // YYYY-MM-DD
      year = int.parse(first);
      month = int.parse(second);
      day = int.parse(third);
    } else if (RegExp(r'[A-Z]', caseSensitive: false).hasMatch(second)) {
      // DD MON YYYY
      day = int.parse(first);
      month = _monthNameToNumber(second);
      year = int.parse(third);
    } else {
      // DD/MM/YYYY (formato colombiano)
      day = int.parse(first);
      month = int.parse(second);
      year = int.parse(third);
    }

    // Ajustar año de 2 dígitos
    if (year < 100) {
      year += 2000;
    }

    return DateTime(year, month, day);
  }

  /// Convierte nombre de mes a número
  int _monthNameToNumber(String name) {
    const months = {
      'ENE': 1, 'FEB': 2, 'MAR': 3, 'ABR': 4,
      'MAY': 5, 'JUN': 6, 'JUL': 7, 'AGO': 8,
      'SEP': 9, 'OCT': 10, 'NOV': 11, 'DIC': 12,
    };
    return months[name.toUpperCase().substring(0, 3)] ?? 1;
  }

  /// Limpia el nombre del comercio
  String _cleanMerchantName(String name) {
    return name
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  /// Calcula confianza del parsing
  double _calculateConfidence(double? amount, String? merchant, DateTime? date) {
    var confidence = 0.0;

    if (amount != null && amount > 0) confidence += 0.5;
    if (merchant != null && merchant.isNotEmpty) confidence += 0.3;
    if (date != null) confidence += 0.2;

    return confidence;
  }
}
