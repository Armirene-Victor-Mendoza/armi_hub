import 'package:armi_hub/features/receipt_capture/domain/entities/evidence_capture_type.dart';

/// Configuración para la captura de recibos
class ReceiptCaptureConfig {
  final EvidenceCaptureType evidenceType;
  final bool enableOCR;
  final int maxPhotos;

  const ReceiptCaptureConfig({
    this.evidenceType = EvidenceCaptureType.paymentVoucher,
    this.enableOCR = false,
    this.maxPhotos = 1,
  });
}
