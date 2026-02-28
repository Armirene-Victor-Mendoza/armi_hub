import 'package:armi_hub/features/receipt_capture/domain/domain.dart';
import 'package:intl/intl.dart';

class PosReceiptParser implements IReceiptParser {
  @override
  ReceiptProcessingResult parse(String rawText) {
    final warnings = <String>[];

    final normalized = _normalizeText(rawText);
    final lines = _splitLines(normalized);
    final colonFields = _extractColonFields(lines);

    final Map<String, dynamic> extraFields = {};

    void putExtra(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      if (!extraFields.containsKey(key)) {
        extraFields[key] = value;
      }
    }

    // -------- campos tipados principales --------

    final fechaHora = _parseDateTime(lines);
    if (fechaHora == null) {
      warnings.add('No se pudo detectar la fecha/hora del recibo.');
    }

    final monto = _parseAmount(lines, labels: ['MONTO', 'VALOR']);
    final total = _parseAmount(lines, labels: ['TOTAL']);
    if (monto == null && total == null) {
      warnings.add('No se pudo detectar el monto ni el total del recibo.');
    }

    final card = _parseCard(lines);
    if (card.brand == null) {
      warnings.add('No se pudo detectar la marca/tipo de la tarjeta.');
    }
    if (card.last4 == null) {
      warnings.add('No se pudieron detectar los últimos 4 dígitos de la tarjeta.');
    }

    final cu = _extractFirstMatch(normalized, RegExp(r'\bCU[: ]+([0-9A-Z]+)'));
    if (cu == null) {
      warnings.add('No se pudo detectar el CU.');
    }

    final terminal = _extractFirstMatch(normalized, RegExp(r'\bTER[: ]+([A-Z0-9]+)'));
    if (terminal == null) {
      warnings.add('No se pudo detectar la terminal (TER).');
    }

    final lote = _extractFirstMatch(normalized, RegExp(r'\bLOTE[: ]+([A-Z0-9]+)'));
    // lote puede ser opcional, depende de qué tan exigente quieras ser

    final ver = _extractFirstMatch(normalized, RegExp(r'\bVER[: ]+([A-Z0-9_]+)'));
    if (ver == null) {
      warnings.add('No se pudo detectar el VER.');
    }

    final autorizacion = _parseAutorizacion(normalized, lines);
    if (autorizacion == null) {
      warnings.add('No se pudo detectar el número de autorización.');
    }

    final referencia = _parseReferencia(normalized, lines);
    if (referencia == null) {
      warnings.add('No se pudo detectar la referencia / recibo / RRN.');
    }

    final orderId = _parseOrderId(normalized);
    if (orderId == null) {
      warnings.add('No se pudo detectar el ID de orden.');
    }

    final tienda = _guessTienda(lines);
    if (tienda == null) {
      warnings.add('No se pudo detectar con certeza la tienda/comercio.');
    }

    final afiliado = _guessAfiliado(lines, tienda);
    if (afiliado == null) {
      warnings.add('No se pudo detectar el afiliado.');
    }

    // -------- label:valor → extraFields --------

    for (final f in colonFields) {
      final key = _canonicalKeyForLabel(f.rawLabel);

      if (key == 'monto' || key == 'total' || key == 'compraNeta') {
        final numValue = _tryParseAmount(f.value);
        putExtra(key, numValue ?? f.value);
      } else {
        putExtra(key, f.value);
      }
    }

    // -------- construir ReceiptData --------

    final receiptData = ReceiptData(
      rawText: rawText,
      afiliado: afiliado,
      terminal: terminal,
      lote: lote,
      referencia: referencia,
      tarjeta: card.brand,
      ultimos4: card.last4,
      fechaHora: fechaHora,
      monto: monto,
      total: total ?? monto, // si no hay Total, usamos Monto/Valor
      cu: cu,
      ver: ver,
      tienda: tienda,
      autorizacion: autorizacion,
      orderId: orderId,
      extra: {
        /* Lines 125-126 omitted */
        ...extraFields,
      },
    );

    // -------- decidir success vs error --------

    final coreFieldsDetected = [
      fechaHora,
      monto ?? total,
      referencia,
      autorizacion,
      card.brand,
      card.last4,
      orderId,
    ].where((v) => v != null).length;

    if (coreFieldsDetected == 0) {
      // aquí puedes ajustar el texto de error a algo más de negocio tuyo
      return ReceiptProcessingResult.error('No se pudo reconocer información suficiente para considerar válido el recibo.');
    }

    return ReceiptProcessingResult.success(receiptData, warnings: warnings);
  }
  // --------- Normalización básica ---------

  String _normalizeText(String input) {
    var text = input.replaceAll('\r', '\n');
    text = text.replaceAll('\t', ' ');
    text = text.toUpperCase();

    const from = 'ÁÉÍÓÚÄËÏÖÜÑ';
    const to = 'AEIOUAEIOUN';
    for (var i = 0; i < from.length; i++) {
      text = text.replaceAll(from[i], to[i]);
    }

    // colapsar espacios múltiples
    text = text.replaceAll(RegExp(r' +'), ' ');

    return text;
  }

  List<String> _splitLines(String text) {
    return text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  }

  // --------- Fecha / Fecha-hora ---------

  DateTime? _parseDateTime(List<String> lines) {
    final joined = lines.join(' ');

    // formato: 04/12/2024 18:25
    final fullMatch = RegExp(r'(\d{1,2})[\/-](\d{1,2})[\/-](\d{2,4})\s+(\d{1,2}):(\d{2})').firstMatch(joined);

    if (fullMatch != null) {
      final d = int.parse(fullMatch.group(1)!);
      final m = int.parse(fullMatch.group(2)!);
      final yRaw = int.parse(fullMatch.group(3)!);
      final h = int.parse(fullMatch.group(4)!);
      final min = int.parse(fullMatch.group(5)!);

      final y = yRaw < 100 ? 2000 + yRaw : yRaw;
      return DateTime(y, m, d, h, min);
    }

    // fallback: fecha sola o hora sola
    for (final line in lines) {
      // 04/12/2024
      if (RegExp(r'^\d{1,2}[\/-]\d{1,2}[\/-]\d{2,4}$').hasMatch(line)) {
        try {
          final df = DateFormat('dd/MM/yyyy');
          return df.parse(line);
        } catch (_) {}
      }
      // 18:25
      final timeOnly = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(line);
      if (timeOnly != null) {
        final now = DateTime.now();
        final h = int.parse(timeOnly.group(1)!);
        final min = int.parse(timeOnly.group(2)!);
        return DateTime(now.year, now.month, now.day, h, min);
      }
    }

    return null;
  }

  // --------- Montos (Monto / Total) ---------

  double? _parseAmount(List<String> lines, {required List<String> labels}) {
    for (final line in lines) {
      final upper = line.toUpperCase();
      final hasLabel = labels.any((l) => upper.contains(l));
      if (!hasLabel) continue;

      // Ej: "TOTAL: $36.200" o "VALOR:$194.843"
      final match = RegExp(r'([\$\sCOP]*)([\d\.\,]+)').firstMatch(line);
      if (match != null) {
        final numberPart = match.group(2)!;
        final normalized = numberPart.replaceAll('.', '').replaceAll(',', '.').trim();
        try {
          return double.parse(normalized);
        } catch (_) {}
      }
    }
    return null;
  }

  // --------- Tarjeta / últimos 4 dígitos ---------

  _Card _parseCard(List<String> lines) {
    // Ej: "DB-MASTERCARD ***3633" o "DB-MASTERCARD 3533"
    final regex = RegExp(r'\b(DB|CR)[-\s]*([A-Z]+)\s+\*{0,3}\s?(\d{3,4})');

    for (final line in lines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final tipo = match.group(1)!; // DB, CR
        final marca = match.group(2)!; // MASTERCARD, VISA
        final last4 = match.group(3)!;
        return _Card(brand: '$tipo-$marca', last4: last4);
      }
    }

    // Fallback: sólo "MASTERCARD 3633"
    final simple = RegExp(r'(MASTERCARD|VISA|AMEX)\s+(\d{4})');
    for (final line in lines) {
      final match = simple.firstMatch(line);
      if (match != null) {
        return _Card(brand: match.group(1), last4: match.group(2));
      }
    }

    return const _Card();
  }

  // --------- Referencia ---------
  // (usa primero RECIBO:/REFERENCIA:, si no, RRN)

  String? _parseReferencia(String normalized, List<String> lines) {
    // RECIBO: 000561
    final recMatch = RegExp(r'\bRECIBO[: ]+([0-9A-Z]+)').firstMatch(normalized);
    if (recMatch != null) {
      return recMatch.group(1);
    }

    // REFERENCIA: XXXXX
    final refMatch = RegExp(r'\bREFERENCIA[: ]+([0-9A-Z]+)').firstMatch(normalized);
    if (refMatch != null) {
      return refMatch.group(1);
    }

    // RRN: 084200297452
    final rrnMatch = RegExp(r'\bRRN[: ]*([0-9]{6,})').firstMatch(normalized);
    if (rrnMatch != null) {
      return rrnMatch.group(1);
    }

    return null;
  }

  // --------- ID de orden ---------
  String? _parseOrderId(String normalized) {
    // Patrón: "ID de orden: 103669750" (basado en las imágenes de ejemplo)
    final orderIdRegex = RegExp(r'\bID\s+DE\s+ORDEN[:\s]+([0-9]+)');
    final match = orderIdRegex.firstMatch(normalized);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }

  // --------- # de autorización ---------
  // Soporta:
  // - "CU: ... TER: ... AUT182524"
  // - "NUMERO DE APROBACION:\n233316"

  String? _parseAutorizacion(String normalized, List<String> lines) {
    // 1. Caso clásico "AUT182524" o "AUT: 182524"
    final autRegex = RegExp(r'\bAUT[: ]*([0-9A-Z]{4,})');
    final autMatch = autRegex.firstMatch(normalized);
    if (autMatch != null) {
      return autMatch.group(1);
    }

    // 2. Caso "NUMERO DE APROBACION:" en una línea y el número en la siguiente
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('NUMERO DE APROBACION')) {
        // buscamos en las siguientes líneas el primer número "grande"
        for (int j = i + 1; j < lines.length; j++) {
          final nextLine = lines[j];
          // si ya llegamos a VALOR / TOTAL, dejamos de buscar
          if (nextLine.contains('VALOR') || nextLine.contains('TOTAL')) {
            break;
          }
          final digitsMatch = RegExp(r'\b(\d{4,})\b').firstMatch(nextLine);
          if (digitsMatch != null) {
            return digitsMatch.group(1);
          }
        }
      }
    }

    return null;
  }

  // --------- Tienda / Afiliado ---------

  String? _guessTienda(List<String> lines) {
    // 1) Comercios conocidos por nombre (puedes ir ampliando la lista)
    final knownMerchant = lines.firstWhere(
      (l) => l.contains('FARMATODO') || l.contains('EXITO') || l.contains('OLIMPICA') || l.contains('ARA'),
      orElse: () => '',
    );
    if (knownMerchant.isNotEmpty) return knownMerchant;

    // 2) Heurística: línea siguiente a CREDIBANCO/REDEBAN, pero
    // solo si no parece etiqueta genérica.
    final procIndex = lines.indexWhere((l) => l.contains('CREDIBANCO') || l.contains('EDIBANCO') || l.contains('REDEBAN'));
    if (procIndex != -1 && procIndex + 1 < lines.length) {
      final candidate = lines[procIndex + 1];

      final looksLikeLabel =
          candidate.contains('VENTA') ||
          candidate.contains('NUMERO DE APROBACION') ||
          candidate.contains('VALOR') ||
          candidate.contains('RECIBO');

      if (!_looksLikeMonto(candidate) && !_looksLikeFecha(candidate) && !looksLikeLabel) {
        return candidate;
      }
    }

    // 3) Si no estamos razonablemente seguros, mejor NO inventar tienda.
    return null;
  }

  String? _guessAfiliado(List<String> lines, String? tienda) {
    // Si el slip trae AFILIADO: xxx, úsalo
    final match = RegExp(r'\bAFILIADO[: ]+(.+)');
    for (final line in lines) {
      final m = match.firstMatch(line);
      if (m != null) {
        return m.group(1)!.trim();
      }
    }

    // Si no hay AFILIADO explícito, no asumimos nada.
    return null;
  }

  bool _looksLikeMonto(String line) {
    return line.contains('\$') || RegExp(r'\b\d{1,3}(\.\d{3})+\b').hasMatch(line);
  }

  bool _looksLikeFecha(String line) {
    return RegExp(r'\d{1,2}[\/-]\d{1,2}[\/-]\d{2,4}').hasMatch(line);
  }

  // --------- Helper genérico regex ---------

  String? _extractFirstMatch(String text, RegExp regex) {
    final match = regex.firstMatch(text);
    return match?.group(1);
  }

  // --------- Extracción genérica de "label: valor" ---------

  List<RawField> _extractColonFields(List<String> lines) {
    final fields = <RawField>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final tokens = line.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

      for (int ti = 0; ti < tokens.length; ti++) {
        final token = tokens[ti];
        final colonIdx = token.indexOf(':');
        if (colonIdx == -1) continue;

        // ⛔ si es hora (18:25), lo ignoramos como campo
        if (_isTimeToken(token)) continue;

        // 1) Etiqueta (puede ser multi-palabra)
        int startLabelIdx = ti;
        while (startLabelIdx > 0) {
          final prev = tokens[startLabelIdx - 1];
          if (prev.contains(':')) break;
          if (_isLikelyValueToken(prev)) break;
          startLabelIdx--;
        }

        final labelTokens = tokens.sublist(startLabelIdx, ti + 1);
        final last = labelTokens.last;
        final cleanLast = last.substring(0, colonIdx);
        labelTokens[labelTokens.length - 1] = cleanLast;

        final rawLabel = labelTokens.join(' ').trim();

        // 2) Valor
        String firstValuePart = '';
        if (colonIdx + 1 < token.length) {
          firstValuePart = token.substring(colonIdx + 1);
        }

        final valueTokens = <String>[];
        if (firstValuePart.isNotEmpty) {
          valueTokens.add(firstValuePart);
        }

        int j = ti + 1;
        while (j < tokens.length && !tokens[j].contains(':')) {
          valueTokens.add(tokens[j]);
          j++;
        }

        var value = valueTokens.join(' ').trim();

        // Caso "NUMERO DE APROBACION:\n233316"
        if (value.isEmpty && i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          if (nextLine.isNotEmpty && !nextLine.contains(':')) {
            value = nextLine;
          }
        }

        if (rawLabel.isNotEmpty && value.isNotEmpty) {
          fields.add(RawField(rawLabel: rawLabel, value: value));
        }
      }
    }

    return fields;
  }

  bool _isTimeToken(String token) {
    return RegExp(r'^\d{1,2}:\d{2}$').hasMatch(token);
  }

  bool _isLikelyValueToken(String token) {
    // Números puros o con decimal
    if (RegExp(r'^\d+([.,]\d+)?$').hasMatch(token)) return true;
    // Algo que empieza en dígito o en "$"
    if (RegExp(r'^\$?\d').hasMatch(token)) return true;
    return false;
  }

  // --------- Normalización de etiquetas a claves JSON ---------

  String _canonicalKeyForLabel(String rawLabel) {
    var s = rawLabel.toUpperCase();
    s = s.replaceAll(RegExp(r'[^A-Z0-9 ]'), '').trim();

    switch (s) {
      case 'NUMERO DE APROBACION':
      case 'NUMERO APROBACION':
        return 'autorizacion';
      case 'VALOR':
        return 'monto';
      case 'TOTAL':
        return 'total';
      case 'RECIBO':
        return 'referencia';
      case 'COMPRA NETA':
        return 'compraNeta';
      case 'CU':
        return 'cu';
      case 'TER':
        return 'terminal';
      case 'LOTE':
        return 'lote';
      case 'AID':
        return 'aid';
      case 'VER':
        return 'ver';
      case 'TVR':
        return 'tvr';
      case 'RRN':
        return 'rrn';
      case 'TSI':
        return 'tsi';
      case 'CR':
        return 'cr';
      default:
        final parts = s.split(RegExp(r'\s+'));
        if (parts.isEmpty) return s.toLowerCase();
        final first = parts.first.toLowerCase();
        final rest = parts.skip(1).map((p) => p[0] + p.substring(1).toLowerCase()).join();
        return '$first$rest';
    }
  }

  // --------- Parseo suave de montos ---------

  double? _tryParseAmount(String value) {
    final match = RegExp(r'([\$\sCOP]*)([\d\.\,]+)').firstMatch(value);
    if (match == null) return null;
    final numberPart = match.group(2)!;
    final normalized = numberPart.replaceAll('.', '').replaceAll(',', '.').trim();
    try {
      return double.parse(normalized);
    } catch (_) {
      return null;
    }
  }
}

class _Card {
  final String? brand;
  final String? last4;

  const _Card({this.brand, this.last4});
}

/// Campo crudo extraído como "etiqueta: valor"
class RawField {
  final String rawLabel; // ej: "NUMERO DE APROBACION", "CU", "COMPRA NETA"
  final String value; // ej: "233316", "818443488", "$36.200"

  RawField({required this.rawLabel, required this.value});
}
