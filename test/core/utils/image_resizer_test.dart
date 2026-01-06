import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

import 'package:finanzasfamilia/core/utils/image_resizer.dart';

void main() {
  group('ImageResizer', () {
    group('resizeIfNeeded', () {
      test('should not resize image within limits', () async {
        // Crear imagen pequeña (1000x1000)
        final smallImage = img.Image(width: 1000, height: 1000);
        img.fill(smallImage, color: img.ColorRgb8(255, 0, 0));
        final bytes = Uint8List.fromList(img.encodePng(smallImage));

        final result = await ImageResizer.resizeIfNeeded(bytes);

        // Debería ser la misma imagen (o muy similar en tamaño)
        final decoded = img.decodeImage(result);
        expect(decoded!.width, equals(1000));
        expect(decoded.height, equals(1000));
      });

      test('should resize landscape image exceeding limits', () async {
        // Crear imagen grande landscape (3000x2000)
        final largeImage = img.Image(width: 3000, height: 2000);
        img.fill(largeImage, color: img.ColorRgb8(0, 255, 0));
        final bytes = Uint8List.fromList(img.encodePng(largeImage));

        final result = await ImageResizer.resizeIfNeeded(bytes);

        // Verificar nueva dimensión
        final resized = img.decodeImage(result);
        expect(resized!.width, equals(2000)); // maxDimension
        expect(resized.height, lessThanOrEqualTo(2000));
      });

      test('should resize portrait image exceeding limits', () async {
        // Crear imagen grande portrait (1500x2500)
        final largeImage = img.Image(width: 1500, height: 2500);
        img.fill(largeImage, color: img.ColorRgb8(0, 0, 255));
        final bytes = Uint8List.fromList(img.encodePng(largeImage));

        final result = await ImageResizer.resizeIfNeeded(bytes);

        // Verificar nueva dimensión
        final resized = img.decodeImage(result);
        expect(resized!.height, equals(2000)); // maxDimension
        expect(resized.width, lessThanOrEqualTo(2000));
      });

      test('should maintain aspect ratio when resizing', () async {
        // Crear imagen 4:3 (4000x3000)
        final image = img.Image(width: 4000, height: 3000);
        img.fill(image, color: img.ColorRgb8(128, 128, 128));
        final bytes = Uint8List.fromList(img.encodePng(image));

        final result = await ImageResizer.resizeIfNeeded(bytes);
        final resized = img.decodeImage(result);

        // Verificar aspect ratio (4:3 = 1.333...)
        final originalRatio = 4000 / 3000;
        final newRatio = resized!.width / resized.height;

        expect(newRatio, closeTo(originalRatio, 0.01));
      });

      test('should handle custom max size', () async {
        final image = img.Image(width: 2000, height: 2000);
        img.fill(image, color: img.ColorRgb8(255, 255, 0));
        final bytes = Uint8List.fromList(img.encodePng(image));

        final result = await ImageResizer.resizeIfNeeded(bytes, maxSize: 1000);
        final resized = img.decodeImage(result);

        expect(resized!.width, equals(1000));
        expect(resized.height, equals(1000));
      });

      test('should throw exception for invalid image', () async {
        final invalidBytes = Uint8List.fromList([0, 1, 2, 3, 4, 5]);

        expect(
          () => ImageResizer.resizeIfNeeded(invalidBytes),
          throwsA(isA<ImageResizeException>()),
        );
      });
    });

    group('checkDimensions', () {
      test('should detect image exceeding limits', () async {
        final largeImage = img.Image(width: 2500, height: 1500);
        final bytes = Uint8List.fromList(img.encodePng(largeImage));

        final info = await ImageResizer.checkDimensions(bytes);

        expect(info.exceedsLimit, isTrue);
        expect(info.width, equals(2500));
        expect(info.height, equals(1500));
      });

      test('should detect image within limits', () async {
        final smallImage = img.Image(width: 1000, height: 800);
        final bytes = Uint8List.fromList(img.encodePng(smallImage));

        final info = await ImageResizer.checkDimensions(bytes);

        expect(info.exceedsLimit, isFalse);
        expect(info.recommendedResize, isFalse);
      });

      test('should recommend resize for large but valid images', () async {
        // 1800px está dentro del límite (2000) pero fuera del recomendado (1500)
        final image = img.Image(width: 1800, height: 1200);
        final bytes = Uint8List.fromList(img.encodePng(image));

        final info = await ImageResizer.checkDimensions(bytes);

        expect(info.exceedsLimit, isFalse);
        expect(info.recommendedResize, isTrue);
      });

      test('should calculate correct aspect ratio', () async {
        final image = img.Image(width: 1920, height: 1080);
        final bytes = Uint8List.fromList(img.encodePng(image));

        final info = await ImageResizer.checkDimensions(bytes);

        expect(info.aspectRatio, closeTo(16 / 9, 0.01));
        expect(info.isLandscape, isTrue);
        expect(info.isPortrait, isFalse);
      });
    });

    group('createThumbnail', () {
      test('should create thumbnail with default size', () async {
        final image = img.Image(width: 2000, height: 1500);
        final bytes = Uint8List.fromList(img.encodePng(image));

        final result = await ImageResizer.createThumbnail(bytes);
        final thumbnail = img.decodeImage(result);

        expect(thumbnail!.width, lessThanOrEqualTo(300));
        expect(thumbnail.height, lessThanOrEqualTo(300));
      });

      test('should create thumbnail with custom size', () async {
        final image = img.Image(width: 2000, height: 1500);
        final bytes = Uint8List.fromList(img.encodePng(image));

        final result = await ImageResizer.createThumbnail(bytes, size: 200);
        final thumbnail = img.decodeImage(result);

        expect(thumbnail!.width, lessThanOrEqualTo(200));
        expect(thumbnail.height, lessThanOrEqualTo(200));
      });
    });

    group('isValidImage', () {
      test('should return true for valid PNG', () {
        final image = img.Image(width: 100, height: 100);
        final bytes = Uint8List.fromList(img.encodePng(image));

        expect(ImageResizer.isValidImage(bytes), isTrue);
      });

      test('should return true for valid JPEG', () {
        final image = img.Image(width: 100, height: 100);
        final bytes = Uint8List.fromList(img.encodeJpg(image));

        expect(ImageResizer.isValidImage(bytes), isTrue);
      });

      test('should return false for invalid bytes', () {
        final invalidBytes = Uint8List.fromList([0, 1, 2, 3, 4, 5]);

        expect(ImageResizer.isValidImage(invalidBytes), isFalse);
      });
    });

    group('getImageType', () {
      test('should detect PNG', () {
        final image = img.Image(width: 100, height: 100);
        final bytes = Uint8List.fromList(img.encodePng(image));

        expect(ImageResizer.getImageType(bytes), equals('png'));
      });

      test('should detect JPEG', () {
        final image = img.Image(width: 100, height: 100);
        final bytes = Uint8List.fromList(img.encodeJpg(image));

        expect(ImageResizer.getImageType(bytes), equals('jpeg'));
      });

      test('should return null for unknown format', () {
        final invalidBytes = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]);

        expect(ImageResizer.getImageType(invalidBytes), isNull);
      });
    });

    group('optimizeForApi', () {
      test('should resize and convert to JPEG', () async {
        final largeImage = img.Image(width: 3000, height: 2000);
        img.fill(largeImage, color: img.ColorRgb8(100, 150, 200));
        final bytes = Uint8List.fromList(img.encodePng(largeImage));

        final result = await ImageResizer.optimizeForApi(bytes);

        // Verificar que es JPEG
        expect(ImageResizer.getImageType(result), equals('jpeg'));

        // Verificar dimensiones
        final optimized = img.decodeImage(result);
        expect(optimized!.width, lessThanOrEqualTo(1500));
        expect(optimized.height, lessThanOrEqualTo(1500));

        // Verificar que el tamaño se redujo
        expect(result.length, lessThan(bytes.length));
      });

      test('should not resize small images but convert to JPEG', () async {
        final smallImage = img.Image(width: 800, height: 600);
        img.fill(smallImage, color: img.ColorRgb8(50, 100, 150));
        final bytes = Uint8List.fromList(img.encodePng(smallImage));

        final result = await ImageResizer.optimizeForApi(bytes);

        // Verificar que es JPEG
        expect(ImageResizer.getImageType(result), equals('jpeg'));

        // Verificar que las dimensiones no cambiaron
        final optimized = img.decodeImage(result);
        expect(optimized!.width, equals(800));
        expect(optimized.height, equals(600));
      });
    });
  });

  group('ImageDimensionInfo', () {
    test('should calculate file size in KB', () {
      final info = ImageDimensionInfo(
        width: 1000,
        height: 800,
        exceedsLimit: false,
        recommendedResize: false,
        fileSizeBytes: 102400, // 100 KB
      );

      expect(info.fileSizeKB, equals(100));
    });

    test('should calculate file size in MB', () {
      final info = ImageDimensionInfo(
        width: 1000,
        height: 800,
        exceedsLimit: false,
        recommendedResize: false,
        fileSizeBytes: 1048576, // 1 MB
      );

      expect(info.fileSizeMB, equals(1));
    });

    test('should generate dimension string', () {
      final info = ImageDimensionInfo(
        width: 1920,
        height: 1080,
        exceedsLimit: false,
        recommendedResize: false,
        fileSizeBytes: 500000,
      );

      expect(info.dimensionString, equals('1920x1080'));
    });
  });

  group('ImageResizeException', () {
    test('should have correct message', () {
      final exception = ImageResizeException('Test error message');

      expect(exception.message, equals('Test error message'));
      expect(exception.toString(), equals('ImageResizeException: Test error message'));
    });
  });

  group('Edge Cases - API Error Prevention', () {
    test('should handle exactly 2000px width', () async {
      final image = img.Image(width: 2000, height: 1500);
      final bytes = Uint8List.fromList(img.encodePng(image));

      final result = await ImageResizer.resizeIfNeeded(bytes);
      final resized = img.decodeImage(result);

      // Should not resize since it's exactly at the limit
      expect(resized!.width, equals(2000));
      expect(resized.height, equals(1500));
    });

    test('should handle exactly 2001px width (just over limit)', () async {
      final image = img.Image(width: 2001, height: 1500);
      final bytes = Uint8List.fromList(img.encodePng(image));

      final result = await ImageResizer.resizeIfNeeded(bytes);
      final resized = img.decodeImage(result);

      // Should resize to 2000px
      expect(resized!.width, equals(2000));
    });

    test('should handle square image at limit', () async {
      final image = img.Image(width: 2001, height: 2001);
      final bytes = Uint8List.fromList(img.encodePng(image));

      final result = await ImageResizer.resizeIfNeeded(bytes);
      final resized = img.decodeImage(result);

      expect(resized!.width, equals(2000));
      expect(resized.height, equals(2000));
    });

    test('should prevent API Error 400 for typical screenshot dimensions', () async {
      // iPhone 15 Pro Max screenshot: 1290x2796
      final iphoneScreenshot = img.Image(width: 1290, height: 2796);
      final iphoneBytes = Uint8List.fromList(img.encodePng(iphoneScreenshot));

      final iphoneResult = await ImageResizer.resizeIfNeeded(iphoneBytes);
      final iphoneResized = img.decodeImage(iphoneResult);

      expect(iphoneResized!.width, lessThanOrEqualTo(2000));
      expect(iphoneResized.height, lessThanOrEqualTo(2000));

      // 4K monitor screenshot: 3840x2160
      final screenshot4k = img.Image(width: 3840, height: 2160);
      final screenshot4kBytes = Uint8List.fromList(img.encodePng(screenshot4k));

      final result4k = await ImageResizer.resizeIfNeeded(screenshot4kBytes);
      final resized4k = img.decodeImage(result4k);

      expect(resized4k!.width, lessThanOrEqualTo(2000));
      expect(resized4k.height, lessThanOrEqualTo(2000));
    });
  });
}
