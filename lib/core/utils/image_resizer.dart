import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Utilidad para redimensionar imágenes antes de enviar a APIs con límites
/// 
/// Esta clase resuelve el error:
/// "At least one of the image dimensions exceed max allowed size for 
/// many-image requests: 2000 pixels"
/// 
/// Ver documentación completa: docs/fixes/FIX_IMAGE_DIMENSION_EXCEEDED.md
class ImageResizer {
  /// Límite máximo de dimensión para APIs multi-imagen (Anthropic/Claude)
  static const int maxDimension = 2000;

  /// Límite recomendado para mejor rendimiento y compatibilidad
  static const int recommendedDimension = 1500;

  /// Límite para thumbnails
  static const int thumbnailDimension = 300;

  /// Redimensiona una imagen si excede las dimensiones máximas
  /// 
  /// [imageBytes] - Bytes de la imagen original
  /// [maxSize] - Dimensión máxima permitida (default: 2000)
  /// 
  /// Mantiene el aspect ratio y devuelve la imagen redimensionada como bytes.
  /// Si la imagen ya está dentro de los límites, la devuelve sin modificar.
  /// 
  /// Ejemplo:
  /// ```dart
  /// final safeBytes = await ImageResizer.resizeIfNeeded(imageBytes);
  /// ```
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

    // Redimensionar con interpolación linear (buena calidad/rendimiento)
    final resized = img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );

    // Codificar como PNG (sin pérdida de calidad)
    return Uint8List.fromList(img.encodePng(resized));
  }

  /// Redimensiona una imagen a un tamaño específico
  /// 
  /// Útil para crear thumbnails o imágenes de tamaño fijo
  static Future<Uint8List> resizeToSize(
    Uint8List imageBytes, {
    required int width,
    required int height,
    bool maintainAspectRatio = true,
  }) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw ImageResizeException('No se pudo decodificar la imagen');
    }

    img.Image resized;

    if (maintainAspectRatio) {
      // Calcular dimensiones manteniendo aspect ratio
      final aspectRatio = image.width / image.height;
      final targetRatio = width / height;

      int finalWidth;
      int finalHeight;

      if (aspectRatio > targetRatio) {
        finalWidth = width;
        finalHeight = (width / aspectRatio).round();
      } else {
        finalHeight = height;
        finalWidth = (height * aspectRatio).round();
      }

      resized = img.copyResize(
        image,
        width: finalWidth,
        height: finalHeight,
        interpolation: img.Interpolation.linear,
      );
    } else {
      resized = img.copyResize(
        image,
        width: width,
        height: height,
        interpolation: img.Interpolation.linear,
      );
    }

    return Uint8List.fromList(img.encodePng(resized));
  }

  /// Crea un thumbnail de la imagen
  static Future<Uint8List> createThumbnail(
    Uint8List imageBytes, {
    int size = thumbnailDimension,
  }) async {
    return resizeIfNeeded(imageBytes, maxSize: size);
  }

  /// Verifica las dimensiones de una imagen sin modificarla
  /// 
  /// Útil para determinar si una imagen necesita ser redimensionada
  /// antes de procesarla
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
      fileSizeBytes: imageBytes.length,
    );
  }

  /// Verifica si una imagen es válida y puede ser procesada
  static bool isValidImage(Uint8List imageBytes) {
    try {
      final image = img.decodeImage(imageBytes);
      return image != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el tipo de imagen basado en los bytes
  static String? getImageType(Uint8List imageBytes) {
    if (imageBytes.length < 4) return null;

    // PNG: 89 50 4E 47
    if (imageBytes[0] == 0x89 &&
        imageBytes[1] == 0x50 &&
        imageBytes[2] == 0x4E &&
        imageBytes[3] == 0x47) {
      return 'png';
    }

    // JPEG: FF D8 FF
    if (imageBytes[0] == 0xFF &&
        imageBytes[1] == 0xD8 &&
        imageBytes[2] == 0xFF) {
      return 'jpeg';
    }

    // WebP: 52 49 46 46 ... 57 45 42 50
    if (imageBytes.length > 12 &&
        imageBytes[0] == 0x52 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46 &&
        imageBytes[3] == 0x46 &&
        imageBytes[8] == 0x57 &&
        imageBytes[9] == 0x45 &&
        imageBytes[10] == 0x42 &&
        imageBytes[11] == 0x50) {
      return 'webp';
    }

    // GIF: 47 49 46 38
    if (imageBytes[0] == 0x47 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46 &&
        imageBytes[3] == 0x38) {
      return 'gif';
    }

    return null;
  }

  /// Convierte una imagen a JPEG con compresión
  /// 
  /// Útil para reducir el tamaño de archivo de fotos
  static Future<Uint8List> convertToJpeg(
    Uint8List imageBytes, {
    int quality = 85,
  }) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw ImageResizeException('No se pudo decodificar la imagen');
    }

    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }

  /// Redimensiona y convierte a JPEG en una sola operación
  /// 
  /// Optimiza tanto dimensiones como tamaño de archivo
  static Future<Uint8List> optimizeForApi(
    Uint8List imageBytes, {
    int maxSize = recommendedDimension,
    int jpegQuality = 85,
  }) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw ImageResizeException('No se pudo decodificar la imagen');
    }

    // Redimensionar si es necesario
    img.Image finalImage = image;
    if (image.width > maxSize || image.height > maxSize) {
      int newWidth;
      int newHeight;

      if (image.width > image.height) {
        newWidth = maxSize;
        newHeight = (image.height * maxSize / image.width).round();
      } else {
        newHeight = maxSize;
        newWidth = (image.width * maxSize / image.height).round();
      }

      finalImage = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
    }

    // Convertir a JPEG con compresión
    return Uint8List.fromList(img.encodeJpg(finalImage, quality: jpegQuality));
  }
}

/// Información sobre las dimensiones de una imagen
class ImageDimensionInfo {
  final int width;
  final int height;
  final bool exceedsLimit;
  final bool recommendedResize;
  final int fileSizeBytes;

  const ImageDimensionInfo({
    required this.width,
    required this.height,
    required this.exceedsLimit,
    required this.recommendedResize,
    required this.fileSizeBytes,
  });

  /// Aspect ratio de la imagen
  double get aspectRatio => width / height;

  /// Si la imagen es landscape (más ancha que alta)
  bool get isLandscape => width > height;

  /// Si la imagen es portrait (más alta que ancha)
  bool get isPortrait => height > width;

  /// Tamaño del archivo en KB
  double get fileSizeKB => fileSizeBytes / 1024;

  /// Tamaño del archivo en MB
  double get fileSizeMB => fileSizeBytes / (1024 * 1024);

  /// Descripción legible de las dimensiones
  String get dimensionString => '${width}x$height';

  @override
  String toString() {
    return 'ImageDimensionInfo($dimensionString, '
        '${fileSizeKB.toStringAsFixed(1)}KB, '
        'exceedsLimit: $exceedsLimit)';
  }
}

/// Excepción para errores de redimensionamiento de imágenes
class ImageResizeException implements Exception {
  final String message;

  ImageResizeException(this.message);

  @override
  String toString() => 'ImageResizeException: $message';
}
