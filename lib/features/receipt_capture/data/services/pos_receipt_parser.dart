import 'package:armi_hub/features/receipt_capture/domain/domain.dart';

class PosReceiptParser implements IReceiptParser {
  static const int _paymentCash = 1;
  static const int _paymentCard = 2;
  static const int _paymentOnline = 3;

  @override
  ReceiptProcessingResult parse(String rawText) {
    final warnings = <String>[];
    final normalized = _normalizeText(rawText);
    final lines = _splitLines(normalized);

    final totalValue = _extractTotalValue(lines);
    final payment = _extractPayment(lines);
    final customerName = _extractCustomerName(lines);
    final customerAddress = _extractAddress(lines);
    final customerPhone = _extractPhone(lines);
    final receiptDateTime = _extractReceiptDateTime(lines);
    final orderCentralId = _extractOrderCentralId(normalized);
    final platformOrderId = _extractPlatformOrderId(normalized);

    if (totalValue == null) {
      warnings.add('No se pudo detectar TOTAL del recibo.');
    }
    if (payment.code == null) {
      warnings.add('No se pudo detectar metodo de pago.');
    }
    if (customerName.raw == null) {
      warnings.add('No se pudo detectar CLIENTE.');
    }
    if (customerAddress == null) {
      warnings.add('No se pudo detectar DIRECCION.');
    }
    if (customerPhone == null) {
      warnings.add('No se pudo detectar CELULAR.');
    }

    final hasMainFields =
        totalValue != null ||
        payment.code != null ||
        customerName.firstName != null ||
        customerAddress != null ||
        customerPhone != null;

    if (!hasMainFields) {
      return ReceiptProcessingResult.error(
        'No se pudo reconocer informacion suficiente del recibo para crear la orden.',
      );
    }

    final optionalExtra = <String, String?>{
      'payment_method_label_raw': payment.labelRaw,
      'order_central_id': orderCentralId,
      'platform_order_id': platformOrderId,
    }..removeWhere((_, value) => value == null || value.trim().isEmpty);

    final extra = optionalExtra.map((key, value) => MapEntry(key, value!));

    return ReceiptProcessingResult.success(
      ReceiptData(
        rawText: rawText,
        totalValue: totalValue,
        paymentMethodCode: payment.code,
        paymentMethodLabelRaw: payment.labelRaw,
        customerNameRaw: customerName.raw,
        customerFirstName: customerName.firstName,
        customerLastName: customerName.lastName,
        customerAddress: customerAddress,
        customerPhone: customerPhone,
        receiptDateTime: receiptDateTime,
        orderCentralId: orderCentralId,
        platformOrderId: platformOrderId,
        extra: extra,
      ),
      warnings: warnings,
    );
  }

  String _normalizeText(String input) {
    var text = input.replaceAll('\r', '\n').replaceAll('\t', ' ').toUpperCase();

    const accented = 'ÁÉÍÓÚÄËÏÖÜÑ';
    const plain = 'AEIOUAEIOUN';
    for (var i = 0; i < accented.length; i++) {
      text = text.replaceAll(accented[i], plain[i]);
    }

    final replacements = <RegExp, String>{
      RegExp(r'\bTOTAI\b'): 'TOTAL',
      RegExp(r'\bCLIENIE\b'): 'CLIENTE',
      RegExp(r'\bCLLENTE\b'): 'CLIENTE',
      RegExp(r'\bCL1ENTE\b'): 'CLIENTE',
      RegExp(r'\bDIRECC1ON\b'): 'DIRECCION',
      RegExp(r'\bDIRECCION\b'): 'DIRECCION',
      RegExp(r'\bCEL\.\b'): 'CEL',
    };

    for (final entry in replacements.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }

    return text;
  }

  List<String> _splitLines(String text) {
    return text
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r' +'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  double? _extractTotalValue(List<String> lines) {
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (!line.contains('TOTAL')) continue;

      final amount = _extractAmountFromLine(line, relaxed: true);
      if (amount != null) return amount;

      // En OCR de tickets el monto puede quedar en la línea siguiente.
      for (var lookAhead = index + 1; lookAhead < lines.length && lookAhead <= index + 3; lookAhead++) {
        final nextLine = lines[lookAhead];
        if (nextLine.contains('CLIENTE') || nextLine.contains('DIRECCI')) {
          break;
        }
        final nearbyAmount = _extractAmountFromLine(nextLine, relaxed: true);
        if (nearbyAmount != null && nearbyAmount > 0) {
          return nearbyAmount;
        }
      }
    }

    for (final line in lines) {
      if (_detectPaymentCode(line) == null) continue;
      final amount = _extractAmountFromLine(line, relaxed: true);
      if (amount != null) return amount;
    }

    return _extractFromFirstDollar(lines);
  }

  _PaymentDetection _extractPayment(List<String> lines) {
    for (final line in lines) {
      final code = _detectPaymentCode(line);
      if (code == null) continue;

      final labelRaw = _detectPaymentLabel(line);
      return _PaymentDetection(code: code, labelRaw: labelRaw);
    }

    return const _PaymentDetection();
  }

  int? _detectPaymentCode(String line) {
    final compact = _compact(line);
    if (compact.contains('TRANSACCIONENLINEA') || compact.contains('ONLINE') || compact.contains('PSE')) {
      return _paymentOnline;
    }
    if (compact.contains('EFECTIVO')) {
      return _paymentCash;
    }
    if (compact.contains('TARJETADEBITO') ||
        compact.contains('TARJETACREDITO') ||
        compact.contains('DATAFONO') ||
        compact.contains('TARJETA')) {
      return _paymentCard;
    }
    return null;
  }

  String? _detectPaymentLabel(String line) {
    final compact = _compact(line);
    if (compact.contains('TRANSACCIONENLINEA')) return 'TRANSACCION EN LINEA';
    if (compact.contains('ONLINE')) return 'ONLINE';
    if (compact.contains('PSE')) return 'PSE';
    if (compact.contains('EFECTIVO')) return 'EFECTIVO';
    if (compact.contains('TARJETADEBITO')) return 'TARJETA DEBITO';
    if (compact.contains('TARJETACREDITO')) return 'TARJETA CREDITO';
    if (compact.contains('DATAFONO')) return 'DATAFONO';
    if (compact.contains('TARJETA')) return 'TARJETA';
    return null;
  }

  _CustomerName _extractCustomerName(List<String> lines) {
    final customerIndex = lines.indexWhere((line) => line.contains('CLIENTE'));
    if (customerIndex == -1) return const _CustomerName();

    String rawName = _extractAfterLabel(lines[customerIndex], RegExp(r'CLIENTE'));

    if (rawName.isEmpty &&
        customerIndex + 1 < lines.length &&
        !_isAddressStopLine(lines[customerIndex + 1])) {
      rawName = lines[customerIndex + 1];
    }

    if (rawName.isEmpty) {
      return const _CustomerName();
    }

    final tokens = rawName.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) {
      return const _CustomerName();
    }

    final firstName = tokens.first;
    final lastName = tokens.length > 1 ? tokens.sublist(1).join(' ') : '';

    return _CustomerName(raw: rawName, firstName: firstName, lastName: lastName);
  }

  String? _extractAddress(List<String> lines) {
    final startIndex = lines.indexWhere((line) => _looksLikeAddressStart(line));
    if (startIndex == -1) return null;

    final chunks = <String>[];
    final firstChunk = _extractAfterLabel(lines[startIndex], RegExp(r'DIREC+I*ON?|DIRECCI'));
    if (firstChunk.isNotEmpty) {
      chunks.add(firstChunk);
    }

    for (var i = startIndex + 1; i < lines.length; i++) {
      final line = lines[i];
      if (_isAddressStopLine(line)) break;
      chunks.add(line);
    }

    if (chunks.isEmpty) return null;

    final merged = chunks.join(' ').replaceAll(RegExp(r' +'), ' ').trim();
    return merged.isEmpty ? null : merged;
  }

  bool _looksLikeAddressStart(String line) {
    return line.contains('DIRECCION') || line.contains('DIRECCI');
  }

  bool _isAddressStopLine(String line) {
    return line.startsWith('TEL') ||
        line.startsWith('TEL-EXT') ||
        line.startsWith('CEL') ||
        line.startsWith('HORA ENTREGA') ||
        line.startsWith('HORA DE ENTREGA') ||
        line.startsWith('PEDIDO CENTRAL') ||
        line.startsWith('DOMICILIO NO') ||
        line.startsWith('PEDIDO PLATAFORMA') ||
        line.startsWith('NIT');
  }

  String? _extractPhone(List<String> lines) {
    final regex = RegExp(r'\bCEL(?:ULAR)?\b\s*[:\-]?\s*([+0-9][0-9\s\-]{6,})');

    for (final line in lines) {
      final match = regex.firstMatch(line);
      if (match == null) continue;
      final normalized = _normalizePhone(match.group(1)!);
      if (normalized != null) return normalized;
    }

    return null;
  }

  String? _normalizePhone(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('+')) {
      final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length < 7) return null;
      return '+$digits';
    }

    final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 7) return null;
    return digitsOnly;
  }

  DateTime? _extractReceiptDateTime(List<String> lines) {
    DateTime? date;

    for (final line in lines) {
      if (!line.contains('FECHA')) continue;

      final dateMatch = RegExp(r'(\d{1,2})[\/-](\d{1,2})[\/-](\d{2,4})').firstMatch(line);
      if (dateMatch == null) continue;

      final day = int.parse(dateMatch.group(1)!);
      final month = int.parse(dateMatch.group(2)!);
      final yearRaw = int.parse(dateMatch.group(3)!);
      final year = yearRaw < 100 ? 2000 + yearRaw : yearRaw;

      date = DateTime(year, month, day);
      break;
    }

    if (date == null) return null;

    DateTime? withTime;
    for (final line in lines) {
      if (!line.contains('HORA DE LLEGADA')) continue;
      withTime = _combineDateAndTime(date, line);
      if (withTime != null) return withTime;
    }

    for (final line in lines) {
      final candidate = _combineDateAndTime(date, line);
      if (candidate != null) return candidate;
    }

    return date;
  }

  DateTime? _combineDateAndTime(DateTime date, String source) {
    final timeMatch = RegExp(r'(\d{1,2}):(\d{2})(?::(\d{2}))?').firstMatch(source);
    if (timeMatch == null) return null;

    final hour = int.parse(timeMatch.group(1)!);
    final minute = int.parse(timeMatch.group(2)!);
    final second = int.tryParse(timeMatch.group(3) ?? '0') ?? 0;

    return DateTime(date.year, date.month, date.day, hour, minute, second);
  }

  String? _extractOrderCentralId(String text) {
    return _firstGroup(
      text,
      RegExp(r'PEDIDO\s+CENTRAL\s*[:#]?\s*([0-9]{4,})'),
    );
  }

  String? _extractPlatformOrderId(String text) {
    return _firstGroup(
      text,
      RegExp(r'PEDIDO\s+PLATAFORMA\s*#?\s*[: ]\s*([0-9]{4,})'),
    );
  }

  String _extractAfterLabel(String line, RegExp labelPattern) {
    final colonIndex = line.indexOf(':');
    if (colonIndex >= 0 && colonIndex + 1 < line.length) {
      return line.substring(colonIndex + 1).trim();
    }

    final withoutLabel = line.replaceFirst(labelPattern, '').trim();
    return withoutLabel.replaceFirst(RegExp(r'^[-#\s]+'), '').trim();
  }

  double? _extractAmountFromLine(String line, {bool relaxed = false}) {
    final hasCurrencyHint = RegExp(r'[$S]\s*\d').hasMatch(line);
    if (!relaxed && !hasCurrencyHint) {
      return null;
    }

    final matches = RegExp(r'[$S]?\s*\d[\d\.,]*').allMatches(line).toList();
    if (matches.isEmpty) return null;

    final last = matches.last.group(0);
    if (last == null) return null;

    final parsed = _toDouble(last);
    if (parsed == null) return null;

    // Evita tomar IDs/lotes muy grandes como monto.
    if (parsed > 50000000) return null;
    return parsed;
  }

  double? _extractFromFirstDollar(List<String> lines) {
    for (final line in lines) {
      final markerIndex = _firstCurrencyMarkerIndex(line);
      if (markerIndex == -1) continue;

      final right = line.substring(markerIndex + 1);
      final match = RegExp(r'(\d[\d\.,]*)').firstMatch(right);
      if (match == null) continue;

      final parsed = _toDouble(match.group(1)!);
      if (parsed == null) continue;
      if (parsed <= 0) continue;
      if (parsed > 50000000) continue;

      return parsed;
    }

    return null;
  }

  int _firstCurrencyMarkerIndex(String line) {
    final match = RegExp(r'[$S](?=\s*\d)').firstMatch(line);
    if (match == null) return -1;
    return match.start;
  }

  double? _toDouble(String value) {
    var cleaned = value.replaceAll(RegExp(r'[^0-9,\.]'), '');
    if (cleaned.isEmpty) return null;

    final hasDot = cleaned.contains('.');
    final hasComma = cleaned.contains(',');

    if (hasDot && hasComma) {
      final dot = cleaned.lastIndexOf('.');
      final comma = cleaned.lastIndexOf(',');
      final decimalIndex = dot > comma ? dot : comma;
      final decimals = cleaned.length - decimalIndex - 1;

      if (decimals >= 1 && decimals <= 2) {
        final separator = cleaned[decimalIndex];
        cleaned = cleaned.replaceAll(separator == '.' ? ',' : '.', '');
        cleaned = cleaned.replaceFirst(separator, '.');
      } else {
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '');
      }
    } else if (hasComma) {
      final decimals = cleaned.length - cleaned.lastIndexOf(',') - 1;
      cleaned = decimals >= 1 && decimals <= 2 ? cleaned.replaceAll(',', '.') : cleaned.replaceAll(',', '');
    } else if (hasDot) {
      final decimals = cleaned.length - cleaned.lastIndexOf('.') - 1;
      cleaned = decimals >= 1 && decimals <= 2 ? cleaned : cleaned.replaceAll('.', '');
    }

    return double.tryParse(cleaned);
  }

  String _compact(String line) {
    return line.replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  String? _firstGroup(String source, RegExp regex) {
    final match = regex.firstMatch(source);
    return match?.group(1);
  }
}

class _PaymentDetection {
  const _PaymentDetection({this.code, this.labelRaw});

  final int? code;
  final String? labelRaw;
}

class _CustomerName {
  const _CustomerName({this.raw, this.firstName, this.lastName});

  final String? raw;
  final String? firstName;
  final String? lastName;
}
