import 'dart:io';
import 'package:armi_hub/features/receipt_capture/data/repositories/image_optimizer_repository_impl.dart';
import 'package:armi_hub/features/receipt_capture/domain/domain.dart';
import 'package:armi_hub/features/receipt_capture/presentation/cubit/photo_evidence_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:armi_hub/core/media_picker/media_picker.dart';

/// Widget moderno de captura de evidencias fotográficas con BLoC
class PhotoEvidenceWidget extends StatelessWidget {
  final int orderId;
  final bool isArmiBusiness;
  final bool toReturn;
  final Function() onCameraClose;
  final Function() onNext;
  // Governs visual skin and upload/validation flow.
  final EvidenceCaptureType evidenceType;
  final bool enableOCR;
  final bool allowSaveLocally;
  final bool isDev;

  const PhotoEvidenceWidget({
    super.key,
    required this.orderId,
    required this.isArmiBusiness,
    required this.toReturn,
    required this.onCameraClose,
    required this.onNext,
    this.evidenceType = EvidenceCaptureType.paymentVoucher,
    this.enableOCR = false,
    this.allowSaveLocally = true,
    this.isDev = false,
  }) : assert(
         evidenceType == EvidenceCaptureType.paymentVoucher || !enableOCR,
         'enableOCR solo aplica para evidenceType paymentVoucher',
       );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PhotoEvidenceCubit(
        config: ReceiptCaptureConfig(evidenceType: evidenceType, enableOCR: enableOCR, maxPhotos: 1),
        mediaRepository: MediaPickerRepositoryImpl(),
        captureUseCase: TakePhotoEvidence(enableOCR: true, imageOptimizer: ImageOptimizerRepositoryImpl()),
      ),
      child: _EnhancedPhotoEvidenceView(
        orderId: orderId,
        isArmiBusiness: isArmiBusiness,
        toReturn: toReturn,
        onCameraClose: onCameraClose,
        onNext: onNext,
        evidenceType: evidenceType,
        enableOCR: enableOCR,
        allowSaveLocally: allowSaveLocally,
        isDev: isDev,
      ),
    );
  }
}

/// Vista interna que maneja la UI con BLoC
class _EnhancedPhotoEvidenceView extends StatefulWidget {
  final int orderId;
  final bool isArmiBusiness;
  final bool toReturn;
  final Function() onCameraClose;
  final Function() onNext;
  final EvidenceCaptureType evidenceType;
  final bool enableOCR;
  final bool allowSaveLocally;
  final bool isDev;

  const _EnhancedPhotoEvidenceView({
    required this.orderId,
    required this.isArmiBusiness,
    required this.toReturn,
    required this.onCameraClose,
    required this.onNext,
    required this.evidenceType,
    required this.enableOCR,
    required this.allowSaveLocally,
    this.isDev = false,
  });

  @override
  State<_EnhancedPhotoEvidenceView> createState() => _EnhancedPhotoEvidenceViewState();
}

class _EnhancedPhotoEvidenceViewState extends State<_EnhancedPhotoEvidenceView> with TickerProviderStateMixin {
  // Animaciones
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  // PageController para mantener la posición entre múltiples fotos
  PageController? _pageController;

  String get _headerTitle {
    switch (widget.evidenceType) {
      case EvidenceCaptureType.invoice:
        return 'Evidencia de factura';
      case EvidenceCaptureType.paymentVoucher:
        return 'Evidencia de pago';
      case EvidenceCaptureType.deliveryProof:
        return 'Evidencia de entrega';
    }
  }

  String get _captureTitle {
    switch (widget.evidenceType) {
      case EvidenceCaptureType.invoice:
        return 'Captura tu factura';
      case EvidenceCaptureType.paymentVoucher:
        return 'Captura tu recibo';
      case EvidenceCaptureType.deliveryProof:
        return 'Captura evidencia de entrega';
    }
  }

  String get _captureDescription {
    switch (widget.evidenceType) {
      case EvidenceCaptureType.invoice:
        return 'Posiciona la factura completa en el encuadre para una captura clara';
      case EvidenceCaptureType.paymentVoucher:
        return 'Posiciona el recibo completo en el encuadre para una captura clara';
      case EvidenceCaptureType.deliveryProof:
        return 'Asegura que se vea claramente la entrega antes de capturar la evidencia';
    }
  }

  String get _primaryCaptureButtonText {
    switch (widget.evidenceType) {
      case EvidenceCaptureType.invoice:
        return 'Capturar Factura';
      case EvidenceCaptureType.paymentVoucher:
        return 'Capturar Recibo';
      case EvidenceCaptureType.deliveryProof:
        return 'Capturar Evidencia';
    }
  }

  String get _statusCapturingText {
    switch (widget.evidenceType) {
      case EvidenceCaptureType.invoice:
        return 'Capturando factura...';
      case EvidenceCaptureType.paymentVoucher:
        return 'Capturando recibo...';
      case EvidenceCaptureType.deliveryProof:
        return 'Capturando evidencia de entrega...';
    }
  }

  String get _statusProcessingText {
    switch (widget.evidenceType) {
      case EvidenceCaptureType.invoice:
        return 'Procesando factura...';
      case EvidenceCaptureType.paymentVoucher:
        return 'Procesando recibo...';
      case EvidenceCaptureType.deliveryProof:
        return 'Procesando evidencia de entrega...';
    }
  }

  IconData get _capturePromptIcon {
    switch (widget.evidenceType) {
      case EvidenceCaptureType.invoice:
      case EvidenceCaptureType.paymentVoucher:
        return Icons.receipt_long_rounded;
      case EvidenceCaptureType.deliveryProof:
        return Icons.local_shipping_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _pulseController.repeat(reverse: true);
  }

  void _updatePageController(PhotoEvidenceSuccess state) {
    // Si no existe el controller, crearlo
    if (_pageController == null) {
      _pageController = PageController(initialPage: state.currentPhotoIndex);
      return;
    }

    // Si el controller no está conectado, recrearlo
    if (!_pageController!.hasClients) {
      _pageController?.dispose();
      _pageController = PageController(initialPage: state.currentPhotoIndex);
      return;
    }

    // Si ya está conectado, navegar a la página correcta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController != null && _pageController!.hasClients && _pageController!.page?.round() != state.currentPhotoIndex) {
        _pageController!.animateToPage(
          state.currentPhotoIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Dismiss cualquier loading activo al cambiar de estado
        } else {
          widget.onCameraClose();
        }
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<PhotoEvidenceCubit, PhotoEvidenceState>(
            listener: (context, state) {
              if (state is PhotoEvidenceLoading) {
                // Mostrar un loading genérico para estados de carga
              } else {
                // Dismiss cualquier loading activo al cambiar de estado
              }

              if (state is PhotoEvidenceError) {
                _showSnackbar(state.message, isError: true);
              }

              if (state is PhotoEvidenceSuccess) {
                _slideController.forward();
              }

              // Resetear PageController si volvemos al estado inicial
              if (state is PhotoEvidenceInitial) {
                _pageController?.dispose();
                _pageController = null;
              }
            },
          ),
        ],
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.grey.shade50, Colors.white],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Contenido principal
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),

                            // Contenido basado en estado
                            BlocBuilder<PhotoEvidenceCubit, PhotoEvidenceState>(
                              builder: (context, state) {
                                return _buildStateContent(context, state);
                              },
                            ),

                            const SizedBox(height: 30),

                            // Botones de acción
                            BlocBuilder<PhotoEvidenceCubit, PhotoEvidenceState>(
                              builder: (context, state) {
                                return _buildActionButtons(context, state);
                              },
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onCameraClose,
            icon: const Icon(Icons.close, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(36, 36),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _headerTitle,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateContent(BuildContext context, PhotoEvidenceState state) {
    if (state is PhotoEvidenceInitial) {
      return _buildInitialContent(context);
    } else if (state is PhotoEvidenceCapturing) {
      return _buildCapturingContent();
    } else if (state is PhotoEvidenceProcessing) {
      return _buildProcessingContent();
    } else if (state is PhotoEvidenceSuccess) {
      return _buildImagePreview(state);
    } else if (state is PhotoEvidenceError) {
      return _buildErrorContent(context, state);
    } else if (state is PhotoEvidenceLoading) {
      return _buildLoadingContent(state);
    }

    return const SizedBox.shrink();
  }

  Widget _buildInitialContent(BuildContext context) {
    return Column(
      children: [
        _buildCapturePrompt(),
        const SizedBox(height: 40),
        _buildPrimaryButton(
          icon: Icons.camera_alt_rounded,
          text: _primaryCaptureButtonText,
          onPressed: () => context.read<PhotoEvidenceCubit>().capturePhoto(),
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildCapturingContent() {
    return Column(
      children: [
        _buildStatusIcon(icon: Icons.camera_alt_rounded, color: Colors.greenAccent, isAnimated: true),
        const SizedBox(height: 24),
        Text(
          _statusCapturingText,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
        Text('Mantén el dispositivo estable', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildProcessingContent() {
    return Column(
      children: [
        _buildStatusIcon(icon: Icons.auto_awesome, color: Colors.orange, isAnimated: true),
        const SizedBox(height: 24),
        Text(
          _statusProcessingText,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
        Text('Optimizando calidad de imagen', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
        ),
      ],
    );
  }

  Widget _buildErrorContent(BuildContext context, PhotoEvidenceError state) {
    return Column(
      children: [
        _buildStatusIcon(icon: Icons.error_outline_rounded, color: Colors.red, isAnimated: false),
        const SizedBox(height: 24),
        Text(
          'Error al capturar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
        Text(
          state.message,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        _buildPrimaryButton(
          icon: Icons.refresh_rounded,
          text: 'Intentar de nuevo',
          onPressed: () {
            if (state.hasExistingPhotos) {
              context.read<PhotoEvidenceCubit>().retryFromError();
            } else {
              context.read<PhotoEvidenceCubit>().capturePhoto();
            }
          },
          isPrimary: false,
        ),
      ],
    );
  }

  Widget _buildLoadingContent(PhotoEvidenceLoading state) {
    return Column(
      children: [
        _buildStatusIcon(icon: Icons.cloud_upload_rounded, color: Colors.greenAccent, isAnimated: true),
        const SizedBox(height: 24),
        Text(
          state.message,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, PhotoEvidenceState state) {
    if (state is! PhotoEvidenceSuccess) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Botón principal - Enviar
        _buildPrimaryButton(
          icon: Icons.cloud_upload_rounded,
          text: 'Enviar Evidencia',
          onPressed: () => _sendEvidence(context),
          isPrimary: true,
        ),

        const SizedBox(height: 16),

        // Botones secundarios
        Row(
          children: [
            // Guardar localmente
            if (widget.allowSaveLocally && widget.evidenceType != EvidenceCaptureType.invoice)
              Expanded(
                child: _buildSecondaryButton(
                  icon: Icons.save_alt_rounded,
                  text: 'Guardar',
                  onPressed: () => _saveLocally(context),
                ),
              ),

            if (context.read<PhotoEvidenceCubit>().canCaptureMorePhotos()) const SizedBox(width: 12),

            // Tomar otra foto
            if (context.read<PhotoEvidenceCubit>().canCaptureMorePhotos())
              Expanded(
                child: _buildSecondaryButton(
                  icon: Icons.add_a_photo_rounded,
                  text: 'Otra foto',
                  onPressed: () => context.read<PhotoEvidenceCubit>().capturePhoto(),
                ),
              ),
          ],
        ),

        // Botón para rehacer todas las fotos si hay múltiples
        if (state.hasMultiplePhotos) ...[
          const SizedBox(height: 12),
          _buildSecondaryButton(
            icon: Icons.refresh_rounded,
            text: 'Rehacer todas las fotos',
            onPressed: () => context.read<PhotoEvidenceCubit>().retakeAllPhotos(),
          ),
        ],
      ],
    );
  }

  // Resto de widgets helper (mantienen la misma implementación)
  Widget _buildCapturePrompt() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3), width: 2),
          ),
          child: Icon(_capturePromptIcon, size: 60, color: Colors.greenAccent),
        ),
        const SizedBox(height: 24),
        Text(
          _captureTitle,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            _captureDescription,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon({required IconData icon, required Color color, required bool isAnimated}) {
    Widget iconWidget = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Icon(icon, size: 40, color: color),
    );

    return isAnimated
        ? AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(scale: _pulseAnimation.value, child: iconWidget);
            },
          )
        : iconWidget;
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String text,
    required VoidCallback? onPressed,
    required bool isPrimary,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.greenAccent : Colors.grey.shade100,
          foregroundColor: isPrimary ? Colors.white : Colors.black87,
          elevation: isPrimary ? 4 : 0,
          shadowColor: isPrimary ? Colors.greenAccent.withValues(alpha: 0.3) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({required IconData icon, required String text, required VoidCallback onPressed}) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade100,
          foregroundColor: Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(PhotoEvidenceSuccess state) {
    if (!state.hasPhotos) return const SizedBox.shrink();

    // Actualizar el PageController con el estado actual
    _updatePageController(state);

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: state.captureResults.length,
            onPageChanged: (index) {
              context.read<PhotoEvidenceCubit>().changeCurrentPhoto(index);
            },
            controller: _pageController,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Image.file(
                        File(state.captureResults[index].imagePath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      // Overlay con acciones
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => context.read<PhotoEvidenceCubit>().removePhoto(index),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.8), shape: BoxShape.circle),
                            child: const Icon(Icons.delete_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),

                      // Contador de fotos si hay múltiples
                      if (state.hasMultiplePhotos)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${index + 1}/${state.captureResults.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      if (state.captureResults[index].receiptData != null && widget.isDev)
                        Container(
                          height: 96,
                          width: double.infinity,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: SelectableText(
                              state.captureResults[index].receiptData?.rawText ?? 'No hay información OCR disponible.',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Indicadores de página si hay múltiples fotos
        if (state.hasMultiplePhotos) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              state.captureResults.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == state.currentPhotoIndex ? Colors.greenAccent : Colors.grey.shade300,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Métodos de acción
  Future<void> _sendEvidence(BuildContext context) async {
    final success = await context.read<PhotoEvidenceCubit>().sendData();

    if (success) {
      widget.onNext();
    }
  }

  Future<void> _saveLocally(BuildContext context) async {
    final success = await context.read<PhotoEvidenceCubit>().saveLocally();

    if (success) {
      final state = context.read<PhotoEvidenceCubit>().state;
      if (state is PhotoEvidenceSuccess) {
        _showSnackbar(
          state.captureResults.length == 1
              ? "Evidencia guardada en la galería"
              : "${state.captureResults.length} evidencias guardadas en la galería",
          isError: false,
        );

        widget.onNext();
      }
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    // Mostrar un snackbar con el mensaje
  }
}
