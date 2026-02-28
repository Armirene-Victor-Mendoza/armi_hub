class ReceiptData {
  final String rawText;

  final String? afiliado; // Afiliado
  final String? terminal; // TER / Terminal
  final String? lote; // Lote
  final String? referencia; // Referencia / Recibo / RRN

  final String? tarjeta; // "DB-MASTERCARD", "CR-VISA", etc.
  final String? ultimos4; // últimos 4 dígitos

  final DateTime? fechaHora; // Fecha o Fecha/hora

  final double? monto; // Monto / Valor
  final double? total; // Total

  final String? cu; // CU
  final String? ver; // VER
  final String? tienda; // Tienda / comercio
  final String? autorizacion; // # de autorización (AUT / Núm. de aprobación)
  final String? orderId;

  final Map<String, String> extra; // p.ej. AID, TVR, texto normalizado, etc.

  const ReceiptData({
    required this.rawText,
    this.afiliado,
    this.terminal,
    this.lote,
    this.referencia,
    this.tarjeta,
    this.ultimos4,
    this.fechaHora,
    this.monto,
    this.total,
    this.cu,
    this.ver,
    this.tienda,
    this.autorizacion,
    this.orderId,
    this.extra = const {},
  });

  bool get hasMinimumFields {
    return fechaHora != null && monto != null;
  }

  Map<String, dynamic> toJson() {
    return {
      'rawText': rawText,
      'afiliado': afiliado,
      'terminal': terminal,
      'lote': lote,
      'referencia': referencia,
      'tarjeta': tarjeta,
      'ultimos4': ultimos4,
      'fechaHora': fechaHora?.toIso8601String(),
      'monto': monto,
      'total': total,
      'cu': cu,
      'ver': ver,
      'tienda': tienda,
      'autorizacion': autorizacion,
      'extra': extra,
    };
  }

  @override
  String toString() {
    return 'ReceiptData('
        'afiliado: $afiliado, terminal: $terminal, lote: $lote, '
        'referencia: $referencia, tarjeta: $tarjeta, ultimos4: $ultimos4, '
        'fechaHora: $fechaHora, monto: $monto, total: $total, cu: $cu, '
        'ver: $ver, tienda: $tienda, autorizacion: $autorizacion'
        ')';
  }
}
