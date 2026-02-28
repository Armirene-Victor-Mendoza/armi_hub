# Receipt Recognition Feature 🧾

Esta funcionalidad implementa el reconocimiento automático de texto en recibos/facturas utilizando Google ML Kit Text Recognition v0.15.0. Incluye patrón Repository para una arquitectura limpia y mantenible.

## Características

- ✅ Reconocimiento de texto OCR con ML Kit
- ✅ Patrones específicos para Venezuela y Colombia
- ✅ Detección automática del país basada en palabras clave
- ✅ Extracción de campos comunes: fecha, hora, monto, lote, autorización
- ✅ Campos específicos por país (afiliado, terminal, CU, TER, etc.)
- ✅ Validación de recibos reales vs texto aleatorio
- ✅ Widget de prueba incluido

## Estructura del Proyecto

```
lib/features/receipt_capture/
├── domain/
│   ├── models/
│   │   └── receipt_models.dart          # Modelos de datos
│   ├── patterns/
│   │   └── receipt_patterns.dart        # Patrones regex por país
│   └── use_cases/
│       └── process_receipt_use_case.dart  # Caso de uso principal
├── data/
│   └── services/
│       ├── mlkit_text_recognition_service.dart  # Servicio ML Kit
│       └── receipt_data_extractor.dart          # Extractor de datos
├── presentation/
│   └── widgets/
│       ├── receipt_recognition_demo.dart  # Demo completo
│       └── receipt_test_widget.dart      # Widget de prueba simple
└── receipt_recognition.dart              # Barrel export
```

## Uso Básico

### 1. Importar la funcionalidad

```dart
import 'package:armi_hub/features/receipt_capture/receipt_recognition.dart';
```

### 2. Procesar un recibo desde archivo

```dart
final processReceiptUseCase = ProcessReceiptUseCase();

// Desde archivo
final result = await processReceiptUseCase.processReceiptFromFile('/path/to/image.jpg');

if (result.success && result.receiptData != null) {
  final data = result.receiptData!;
  print('País: ${data.country}');
  print('Monto: ${data.monto}');
  print('Fecha: ${data.fecha}');
  // ... otros campos
} else {
  print('Error: ${result.error}');
}
```

### 3. Procesar desde bytes de imagen

```dart
final Uint8List imageBytes = ...; // tus bytes de imagen
final result = await processReceiptUseCase.processReceiptFromBytes(
  imageBytes, 
  width, 
  height
);
```

### 4. Usar el widget de prueba

```dart
import 'package:armi_hub/features/receipt_capture/presentation/widgets/receipt_test_widget.dart';

// En tu navegación
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ReceiptTestWidget()),
);
```

## Modelos de Datos

### ReceiptData
Contiene todos los datos extraídos del recibo:

```dart
class ReceiptData {
  // Campos comunes
  final String? fecha;
  final String? hora;
  final String? monto;
  final String? lote;
  final String? numeroAutorizacion;
  final String? ultimosDigitosTarjeta;
  final ReceiptCountry country;
  
  // Campos adicionales por país
  final Map<String, String> additionalFields;
  final String rawText; // Texto completo extraído
  
  // Getters específicos por país
  String? get afiliado; // Venezuela
  String? get terminal; // Venezuela
  String? get cu;       // Colombia
  String? get ter;      // Colombia
  // ...
}
```

### TextRecognitionResult
Resultado del reconocimiento OCR:

```dart
class TextRecognitionResult {
  final bool success;
  final String? text;
  final String? error;
  final double confidence;
}
```

### ReceiptProcessingResult
Resultado final del procesamiento:

```dart
class ReceiptProcessingResult {
  final bool success;
  final ReceiptData? receiptData;
  final String? error;
  final List<String> warnings;
}
```

## Patrones Soportados

### Venezuela
- Fecha: `DD/MM/YYYY`, `DD-MM-YYYY`
- Monto: `VALOR: $123.45`, `MONTO: 123,45`
- Lote: `LOTE: 123456`
- Autorización: `AUTORIZACIÓN: 789123`
- Afiliado: `AFILIADO: 12345`
- Terminal: `TERMINAL: ABC123`

### Colombia
- Fecha: `DD/MM/YYYY`, `DD-MM-YYYY`
- Monto: `TOTAL: $123.45`
- CU: `CU: ABC123`
- TER: `TER: 456`
- Tienda: `TIENDA: STORE01`

## Detección Automática de País

El sistema detecta automáticamente el país basándose en:

### Palabras clave Venezuela:
- bolívares, bs, venezuela, afiliado
- bancos: mercantil, banesco, provincial, bicentenario

### Palabras clave Colombia:
- pesos, cop, colombia, tienda
- bancos: bancolombia, davivienda, banco bogotá

## Configuración Requerida

### 1. Dependencias en pubspec.yaml
```yaml
dependencies:
  google_mlkit_text_recognition: ^0.15.0
  image_picker: ^1.1.2
  permission_handler: ^11.4.0
```

### 2. Permisos Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### 3. Configuración iOS (ios/Runner/Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>La app necesita acceso a la cámara para escanear recibos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>La app necesita acceso a la galería para seleccionar recibos</string>
```

## Validación de Recibos

El sistema incluye validación automática que verifica:

1. **Detección de recibos reales**: Busca palabras clave como "total", "monto", "lote", "terminal"
2. **Campos mínimos**: Requiere al menos fecha y monto
3. **Formato de datos**: Valida formatos de fecha, hora y montos
4. **Consistencia por país**: Verifica patrones específicos del país detectado

## Ejemplo Completo

```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:armi_hub/features/receipt_capture/receipt_recognition.dart';

class MyReceiptScanner extends StatefulWidget {
  @override
  _MyReceiptScannerState createState() => _MyReceiptScannerState();
}

class _MyReceiptScannerState extends State<MyReceiptScanner> {
  final ProcessReceiptUseCase _useCase = ProcessReceiptUseCase();
  
  Future<void> _scanReceipt() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      final result = await _useCase.processReceiptFromFile(image.path);
      
      if (result.success) {
        _showReceiptData(result.receiptData!);
      } else {
        _showError(result.error!);
      }
    }
  }
  
  void _showReceiptData(ReceiptData data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recibo de ${data.country.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monto: ${data.monto ?? "No encontrado"}'),
            Text('Fecha: ${data.fecha ?? "No encontrada"}'),
            Text('Autorización: ${data.numeroAutorizacion ?? "No encontrada"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  // ... resto del código
}
```

## Troubleshooting

### Error: "TextRecognizer not found"
- Verifica que `google_mlkit_text_recognition: ^0.15.0` esté en pubspec.yaml
- Ejecuta `flutter pub get`
- Reinicia el IDE

### Error de permisos de cámara
- Verifica permisos en AndroidManifest.xml e Info.plist
- Solicita permisos en runtime con permission_handler

### Texto no reconocido correctamente
- Asegúrate que la imagen tenga buena calidad y contraste
- Verifica que el texto esté en caracteres latinos
- Prueba con diferentes ángulos e iluminación

### Campos no extraídos
- Revisa los patrones en `receipt_patterns.dart`
- Los patrones están optimizados para recibos de Venezuela y Colombia
- Puedes agregar patrones personalizados según tus necesidades

## 🏛️ Repository Pattern

Se ha implementado el patrón Repository para el manejo de evidencias, separando la lógica de negocio del `OrderService`.

### Estructura
```
├── domain/repositories/evidence_repository.dart      # Interface
├── domain/use_cases/send_evidence_use_case.dart     # Caso de uso
├── data/repositories/evidence_repository_impl.dart  # Implementación
└── config/receipt_recognition_di.dart               # Inyección de dependencias
```

### Uso con Repository Pattern
```dart
// Configuración de dependencias
final cubit = ReceiptRecognitionDI.createPhotoEvidenceCubit(
  config: ReceiptCaptureConfigs.deliveryEvidence,
  mediaRepository: mediaRepository,
);

// Envío de evidencias (ahora encapsulado)
await cubit.sendEvidence(
  order: order,
  denominations: [50000, 20000, 10000],
);
```

### Beneficios
- ✅ **Separación de responsabilidades**: `OrderService` ya no maneja evidencias
- ✅ **Testabilidad mejorada**: Interfaces permiten mocking fácil
- ✅ **Mantenibilidad**: Lógica centralizada en use cases
- ✅ **Reutilización**: Repository puede usarse en otros features
- ✅ **Clean Architecture**: Dependencias apuntan hacia el dominio

## 🎯 Servicio OCR de Vouchers

Se ha implementado un servicio especializado para procesar vouchers con OCR externo que se ejecuta automáticamente cuando `enableOCR: true`.

### Flujo de Procesamiento
1. **Subida de Imagen**: Usar `submitFile` para obtener el link de la imagen
2. **Envío de Metadata**: Llamar servicio con JSON que incluye orderId, imageLink y texto escaneado

### Endpoints
```
# Subida de imagen
POST https://us-central1-armi_hub-369418.cloudfunctions.net/upload-vaucher-pictures/{orderId}

# Envío de metadata  
POST https://upload-vaucher-metadata-681515725483.us-central1.run.app

Headers: x-api-key: JOJdJcar7ZgsUEioQVmEMu9vzB9jr39RwvI0TfN43ODn0nOuY8
```

### Uso Individual
```dart
// El servicio maneja automáticamente el flujo completo:
// 1. Sube cada imagen con submitFile
// 2. Extrae texto de ReceiptData  
// 3. Envía metadata JSON al servicio
final String? ocrResult = await ReceiptRecognitionDI.sendVoucherWithOCR(
  orderId: 123,
  imageFile: File('/path/to/voucher.jpg'),
);

if (ocrResult != null) {
  print('Respuesta del servicio: $ocrResult');
}
```

### Uso Automático (Recomendado)
```dart
// Con cubit - OCR se ejecuta automáticamente
final cubit = ReceiptRecognitionDI.createPhotoEvidenceCubit(
  config: ReceiptCaptureConfigs.voucherWithOCR, // enableOCR: true
  mediaRepository: mediaRepository,
);

// El OCR se procesa automáticamente al enviar evidencias
await cubit.sendEvidence(order: order, denominations: denominations);
```

### Configuraciones OCR
```dart
// Específica para vouchers de datafonos
ReceiptCaptureConfigs.voucherWithOCR

// Para múltiples recibos con OCR
ReceiptCaptureConfigs.deliveryEvidence

// Para desarrollo con debug
ReceiptCaptureConfigs.development
```

### Formato JSON de Metadata
```json
{
  "id": "8f14e45f-ea9b-4c25-a1ee-1a2d9b3f7c25",
  "order_id": 1237,
  "reference": "REF-01237",
  "status": "COMPLETED",
  "image_url": "https://storage.googleapis.com/...",
  "scanned_text": "Fecha: 15/11/2025 | Monto: $45.99 | Lote: 123456",
  "payload": {
    "capture_info": {
      "success": true,
      "has_ocr_data": true,
      "warnings": []
    },
    "receipt_data": {
      "fecha": "15/11/2025",
      "monto": "$45.99",
      "lote": "123456",
      "country": "colombia"
    },
    "processing_metadata": {
      "processed_at": "2025-11-15T14:23:05Z",
      "image_path": "/path/to/image.jpg"
    }
  },
  "created_at": "2025-11-15T14:23:05Z"
}
```

### Funcionamiento
1. **Detección**: Si `enableOCR: true` en la configuración
2. **Subida**: Cada imagen se sube con `submitFile` para obtener URL
3. **Extracción**: Se extrae texto de `ReceiptData` procesado localmente
4. **Metadata**: Se envía JSON completo con toda la información estructurada
5. **Logging**: Resultados se registran para debugging
6. **Tolerancia a fallos**: Errores OCR no afectan el flujo principal

## Siguientes Pasos

1. **Migra a Repository Pattern** usando `ReceiptRecognitionDI`
2. **Prueba la funcionalidad** usando `ReceiptTestWidget`
3. **Personaliza los patrones** en `receipt_patterns.dart` según tus necesidades
4. **Integra en tu aplicación** usando los nuevos use cases
5. **Ajusta la UI** usando los componentes en `presentation/widgets/`

¡La funcionalidad está lista para usar con arquitectura limpia! 🚀