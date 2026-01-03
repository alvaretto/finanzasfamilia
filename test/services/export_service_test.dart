import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/core/services/export_service.dart';

void main() {
  group('ExportService', () {
    test('instance es singleton', () {
      final instance1 = ExportService.instance;
      final instance2 = ExportService.instance;

      expect(identical(instance1, instance2), true);
    });
  });

  group('ExportFormat', () {
    test('tiene valores csv y pdf', () {
      expect(ExportFormat.values.length, 2);
      expect(ExportFormat.values.contains(ExportFormat.csv), true);
      expect(ExportFormat.values.contains(ExportFormat.pdf), true);
    });
  });
}
