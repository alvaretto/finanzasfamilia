# FIX: Error de Dimensiones de Imagen Excedidas

## Fecha
2026-01-05

## Error Original
```
Read(/tmp/movimientos.png)
 ⎿  Read image (143.1KB)
 ⎿ API Error: 400 {"type":"error","error":{"type":"invalid_request_error",
   "message":"messages.27.content.13.image.source.base64.data: At least one 
   of the image dimensions exceed max allowed size for many-image requests: 
   2000 pixels"},"request_id":"req_011CWqRmqVNgPHoGJoUV3xLe"}
```

## Síntomas
- Error 400 (Bad Request) al intentar procesar imágenes
- Mensaje indica que una dimensión de la imagen excede 2000 píxeles
- Ocurre en requests con múltiples imágenes ("many-image requests")
- La imagen se lee correctamente (143.1KB) pero falla al enviar a la API

## Causa Raíz
La API de Claude/Anthropic tiene límites en las dimensiones de imágenes para requests multi-imagen:
- **Límite máximo por dimensión**: 2000 píxeles
- **Aplica a**: width O height (cualquier dimensión)
- **Contexto**: Requests con múltiples imágenes tienen límites más estrictos

## Solución Implementada

### 1. Crear Image Resizer Helper
Crear un helper que automáticamente redimensione imágenes antes de procesarlas:

```dart
// lib/core/utils/image_resizer.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Utilidad para redimensionar imágenes antes de enviar a APIs con límites
class ImageResizer {
  /// Límite máximo de dimensión para APIs multi-imagen
  static const int maxDimension = 2000;
  
  /// Límite recomendado para mejor rendimiento
  static const int recommendedDimension = 1500;

  /// Redimensiona una imagen si excede las dimensiones máximas
  /// 
  /// Mantiene el aspect ratio y devuelve la imagen redimensionada como bytes
  /// Si la imagen ya está dentro de los límites, la devuelve sin modificar
  static Future<Uint8List> resizeIfNeeded(
    Uint8List imageBytes, {
    int maxSize = maxDimension,
  }) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw ImageResizeException('No se pudo decodificar la imagen');
    }

    // Verificar si necesita redimensionarse
    if (image.width <= maxSize && image.height <= maxSize) {
      return imageBytes; // Ya está dentro del límite
    }

    // Calcular nuevas dimensiones manteniendo aspect ratio
    int newWidth;
    int newHeight;

    if (image.width > image.height) {
      // Landscape
      newWidth = maxSize;
      newHeight = (image.height * maxSize / image.width).round();
    } else {
      // Portrait o cuadrado
      newHeight = maxSize;
      newWidth = (image.width * maxSize / image.height).round();
    }

    // Redimensionar
    final resized = img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );

    // Codificar como PNG (sin pérdida)
    return Uint8List.fromList(img.encodePng(resized));
  }

  /// Redimensiona un archivo de imagen y lo guarda
  static Future<File> resizeFile(
    File inputFile, {
    String? outputPath,
    int maxSize = maxDimension,
  }) async {
    final bytes = await inputFile.readAsBytes();
    final resizedBytes = await resizeIfNeeded(bytes, maxSize: maxSize);

    final output = outputPath != null
        ? File(outputPath)
        : File('${inputFile.path}_resized.png');

    await output.writeAsBytes(resizedBytes);
    return output;
  }

  /// Verifica si una imagen necesita ser redimensionada
  static Future<ImageDimensionInfo> checkDimensions(Uint8List imageBytes) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw ImageResizeException('No se pudo decodificar la imagen');
    }

    return ImageDimensionInfo(
      width: image.width,
      height: image.height,
      exceedsLimit: image.width > maxDimension || image.height > maxDimension,
      recommendedResize: image.width > recommendedDimension || 
                         image.height > recommendedDimension,
    );
  }
}

/// Información sobre las dimensiones de una imagen
class ImageDimensionInfo {
  final int width;
  final int height;
  final bool exceedsLimit;
  final bool recommendedResize;

  const ImageDimensionInfo({
    required this.width,
    required this.height,
    required this.exceedsLimit,
    required this.recommendedResize,
  });

  @override
  String toString() {
    return 'ImageDimensionInfo(${width}x${height}, exceedsLimit: $exceedsLimit)';
  }
}

/// Excepción para errores de redimensionamiento
class ImageResizeException implements Exception {
  final String message;
  ImageResizeException(this.message);

  @override
  String toString() => 'ImageResizeException: $message';
}
```

### 2. Dependencia Requerida
Agregar al `pubspec.yaml`:
```yaml
dependencies:
  image: ^4.1.7  # Para manipulación de imágenes
```

### 3. Uso en el Código
Antes de enviar imágenes a la API:

```dart
import 'package:finanzasfamilia/core/utils/image_resizer.dart';

Future<void> processImageForApi(Uint8List imageBytes) async {
  // Verificar y redimensionar si es necesario
  final safeBytes = await ImageResizer.resizeIfNeeded(imageBytes);
  
  // Ahora enviar safeBytes a la API
  await sendToApi(safeBytes);
}
```

### 4. Integración con Sistema de Procesamiento de Imágenes
Si existe un pipeline de procesamiento de imágenes, integrar el resize:

```dart
class ImageProcessor {
  Future<ProcessedImage> processForTransaction(File imageFile) async {
    // 1. Leer imagen
    final bytes = await imageFile.readAsBytes();
    
    // 2. Verificar dimensiones
    final info = await ImageResizer.checkDimensions(bytes);
    
    // 3. Redimensionar si es necesario
    final safeBytes = info.exceedsLimit
        ? await ImageResizer.resizeIfNeeded(bytes)
        : bytes;
    
    // 4. Procesar...
    return ProcessedImage(
      bytes: safeBytes,
      originalDimensions: info,
      wasResized: info.exceedsLimit,
    );
  }
}
```

## Límites de la API

### Dimensiones Máximas
| Tipo de Request | Dimensión Máxima |
|-----------------|------------------|
| Single Image | ~5000 px |
| Multi-Image | 2000 px |
| Recomendado | 1500 px |

### Tamaño de Archivo
| Formato | Tamaño Máximo Recomendado |
|---------|---------------------------|
| PNG | 5 MB |
| JPEG | 3 MB |
| WebP | 3 MB |

## Test de Verificación

```dart
// test/core/utils/image_resizer_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

void main() {
  group('ImageResizer', () {
    test('should not resize image within limits', () async {
      // Crear imagen pequeña
      final smallImage = img.Image(width: 1000, height: 1000);
      final bytes = Uint8List.fromList(img.encodePng(smallImage));
      
      final result = await ImageResizer.resizeIfNeeded(bytes);
      
      // Debería ser la misma imagen
      expect(result.length, equals(bytes.length));
    });

    test('should resize image exceeding limits', () async {
      // Crear imagen grande
      final largeImage = img.Image(width: 3000, height: 2000);
      final bytes = Uint8List.fromList(img.encodePng(largeImage));
      
      final result = await ImageResizer.resizeIfNeeded(bytes);
      
      // Verificar nueva dimensión
      final resized = img.decodeImage(result);
      expect(resized!.width, lessThanOrEqualTo(2000));
      expect(resized.height, lessThanOrEqualTo(2000));
    });

    test('should maintain aspect ratio', () async {
      // Crear imagen 4:3
      final image = img.Image(width: 4000, height: 3000);
      final bytes = Uint8List.fromList(img.encodePng(image));
      
      final result = await ImageResizer.resizeIfNeeded(bytes);
      final resized = img.decodeImage(result);
      
      // Verificar aspect ratio (4:3 = 1.333...)
      final originalRatio = 4000 / 3000;
      final newRatio = resized!.width / resized.height;
      
      expect(newRatio, closeTo(originalRatio, 0.01));
    });

    test('checkDimensions should detect exceeding limits', () async {
      final largeImage = img.Image(width: 2500, height: 1500);
      final bytes = Uint8List.fromList(img.encodePng(largeImage));
      
      final info = await ImageResizer.checkDimensions(bytes);
      
      expect(info.exceedsLimit, isTrue);
      expect(info.width, equals(2500));
      expect(info.height, equals(1500));
    });
  });
}
```

## Prevención Futura

### 1. Validación Temprana
Validar dimensiones antes de intentar enviar:

```dart
if (info.exceedsLimit) {
  log.warning('Imagen excede límites, redimensionando...');
  bytes = await ImageResizer.resizeIfNeeded(bytes);
}
```

### 2. UI Feedback
Mostrar al usuario cuando se redimensiona automáticamente:

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('📸 Imagen redimensionada para procesamiento'),
    duration: Duration(seconds: 2),
  ),
);
```

### 3. Configuración Global
Crear configuración centralizada:

```dart
class ImageConfig {
  static const int apiMaxDimension = 2000;
  static const int recommendedMaxDimension = 1500;
  static const int thumbnailDimension = 300;
  
  static const List<String> supportedFormats = ['png', 'jpg', 'jpeg', 'webp'];
}
```

## Archivos Relacionados
- `lib/core/utils/image_resizer.dart` - Helper de redimensionamiento
- `lib/core/config/image_config.dart` - Configuración centralizada
- `test/core/utils/image_resizer_test.dart` - Tests del helper

## Notas
- El error ocurre específicamente en requests multi-imagen
- La dimensión máxima de 2000px es un límite estricto de la API
- Usar `recommendedDimension = 1500` para dejar margen de seguridad
- La calidad de la imagen puede reducirse ligeramente al redimensionar
- Considerar usar JPEG para fotos (menor tamaño) y PNG para capturas

## Referencias
- [Anthropic API - Image Inputs](https://docs.anthropic.com/claude/docs/vision)
- [Flutter image package](https://pub.dev/packages/image)
