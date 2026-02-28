import 'dart:io';
import 'package:flutter/material.dart';
import '../media_picker.dart';

/// Widget de demostración del nuevo Photo Picker
///
/// Muestra cómo usar la nueva funcionalidad que cumple con políticas de Google Play
class PhotoPickerDemo extends StatefulWidget {
  const PhotoPickerDemo({super.key});

  @override
  State<PhotoPickerDemo> createState() => _PhotoPickerDemoState();
}

class _PhotoPickerDemoState extends State<PhotoPickerDemo> {
  final MediaPickerRepository _repository = MediaPickerRepositoryImpl();
  late final PickMediaFromGalleryUseCase _pickFromGallery;
  late final TakeMediaWithCameraUseCase _takeWithCamera;

  List<String> _selectedImages = [];
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _pickFromGallery = PickMediaFromGalleryUseCase(_repository);
    _takeWithCamera = TakeMediaWithCameraUseCase(_repository);
    _checkPhotoPickerAvailability();
  }

  Future<void> _checkPhotoPickerAvailability() async {
    final isAvailable = await _repository.isPhotoPickerAvailable();
    setState(() {
      _statusMessage = isAvailable ? '✅ Photo Picker disponible (sin permisos requeridos)' : '❌ Photo Picker no disponible';
    });
  }

  Future<void> _pickSingleImage() async {
    try {
      final result = await _pickFromGallery.pickImage();
      if (result != null && result.firstPath != null) {
        setState(() {
          _selectedImages = [result.firstPath!];
          _statusMessage = '✅ Imagen seleccionada desde galería (Photo Picker)';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: ${e.toString()}';
      });
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final result = await _pickFromGallery.pickImage(allowMultiple: true);
      if (result != null && result.paths.isNotEmpty) {
        setState(() {
          _selectedImages = result.paths;
          _statusMessage = '✅ ${result.paths.length} imágenes seleccionadas desde galería';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: ${e.toString()}';
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final result = await _takeWithCamera.takePhoto();
      if (result != null && result.firstPath != null) {
        setState(() {
          _selectedImages = [result.firstPath!];
          _statusMessage = '✅ Foto tomada con cámara';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Picker Demo'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                _statusMessage.isEmpty ? 'Verificando disponibilidad...' : _statusMessage,
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botones de acción
            ElevatedButton.icon(
              onPressed: _pickSingleImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Seleccionar 1 imagen (Galería)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _pickMultipleImages,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Seleccionar múltiples (Galería)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tomar foto (Cámara)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Mostrar imágenes seleccionadas
            if (_selectedImages.isNotEmpty) ...[
              Text(
                'Imágenes seleccionadas (${_selectedImages.length}):',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _saveLocalImage,
                label: const Text('Guardar imagen'),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedImages[index]),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.error,
                                color: Colors.red,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text(
                    'No hay imágenes seleccionadas',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLocalImage() async {
    if (_selectedImages.isEmpty) return;

    try {
      for (final imagePath in _selectedImages) {
        final success = await _repository.saveImageToGallery(imagePath);
        if (!success) {
          setState(() {
            _statusMessage = '❌ Error al guardar la imagen en la galería';
          });
          return;
        }
      }
      setState(() {
        _statusMessage = '✅ Imágenes guardadas en la galería correctamente';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error al guardar imágenes: ${e.toString()}';
      });
    }
  }
}
