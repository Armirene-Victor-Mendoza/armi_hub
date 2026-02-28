import 'package:armi_hub/features/receipt_capture/domain/domain.dart';
import 'package:armi_hub/features/receipt_capture/presentation/widgets/photo_evidence_widget.dart';
import 'package:flutter/material.dart';

class ReceiptCaptureScreen extends StatelessWidget {
  const ReceiptCaptureScreen({
    super.key,
    required this.onEvidenceReady,
  });

  final ValueChanged<ReceiptCaptureResult> onEvidenceReady;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PhotoEvidenceWidget(
        orderId: 0,
        isArmiBusiness: true,
        toReturn: false,
        evidenceType: EvidenceCaptureType.invoice,
        enableOCR: true,
        allowSaveLocally: true,
        onCameraClose: () => Navigator.of(context).maybePop(),
        onNext: () {},
        onEvidenceReady: onEvidenceReady,
      ),
    );
  }
}
