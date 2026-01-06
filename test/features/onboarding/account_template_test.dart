import 'package:flutter_test/flutter_test.dart';
import 'package:finanzasfamilia/features/onboarding/models/account_template.dart';
import 'package:finanzasfamilia/features/accounts/domain/models/account_model.dart';

void main() {
  group('AccountTemplate', () {
    test('templates list should not be empty', () {
      expect(AccountTemplate.templates, isNotEmpty);
    });

    test('all templates should have valid AccountType', () {
      for (final template in AccountTemplate.templates) {
        expect(template.type, isA<AccountType>());
        expect(template.defaultName, isNotEmpty);
        expect(template.emoji, isNotEmpty);
        expect(template.description, isNotEmpty);
        expect(template.defaultColor, startsWith('#'));
      }
    });

    test('getByType should return correct template', () {
      final bankTemplate = AccountTemplate.getByType(AccountType.bank);
      expect(bankTemplate, isNotNull);
      expect(bankTemplate!.type, AccountType.bank);
      expect(bankTemplate.defaultName, 'Banco');
    });

    test('getByType should return null for non-existent type', () {
      final template = AccountTemplate.getByType(AccountType.cash);
      // cash no está en templates predefinidos (se crea automático)
      expect(template, isNull);
    });

    group('assets', () {
      test('should return only asset templates', () {
        final assets = AccountTemplate.assets;
        expect(assets, isNotEmpty);
        expect(assets.every((t) => t.isAsset), isTrue);
      });

      test('should include bank, wallet, savings, investment', () {
        final assets = AccountTemplate.assets;
        final types = assets.map((t) => t.type).toSet();
        
        expect(types.contains(AccountType.bank), isTrue);
        expect(types.contains(AccountType.wallet), isTrue);
        expect(types.contains(AccountType.savings), isTrue);
        expect(types.contains(AccountType.investment), isTrue);
      });
    });

    group('liabilities', () {
      test('should return only liability templates', () {
        final liabilities = AccountTemplate.liabilities;
        expect(liabilities, isNotEmpty);
        expect(liabilities.every((t) => !t.isAsset), isTrue);
      });

      test('should include credit, loan, payable', () {
        final liabilities = AccountTemplate.liabilities;
        final types = liabilities.map((t) => t.type).toSet();
        
        expect(types.contains(AccountType.credit), isTrue);
        expect(types.contains(AccountType.loan), isTrue);
        expect(types.contains(AccountType.payable), isTrue);
      });
    });

    group('suggestedNames', () {
      test('bank template should have Colombian banks', () {
        final bankTemplate = AccountTemplate.getByType(AccountType.bank);
        expect(bankTemplate!.suggestedNames, isNotNull);
        expect(bankTemplate.suggestedNames!.contains('Bancolombia'), isTrue);
        expect(bankTemplate.suggestedNames!.contains('Davivienda'), isTrue);
        expect(bankTemplate.suggestedNames!.contains('BBVA'), isTrue);
      });

      test('wallet template should have Colombian digital wallets', () {
        final walletTemplate = AccountTemplate.getByType(AccountType.wallet);
        expect(walletTemplate!.suggestedNames, isNotNull);
        expect(walletTemplate.suggestedNames!.contains('Nequi'), isTrue);
        expect(walletTemplate.suggestedNames!.contains('DaviPlata'), isTrue);
        expect(walletTemplate.suggestedNames!.contains('DollarApp'), isTrue);
      });
    });

    group('requiresCreditLimit', () {
      test('credit card should require credit limit', () {
        final creditTemplate = AccountTemplate.getByType(AccountType.credit);
        expect(creditTemplate!.requiresCreditLimit, isTrue);
      });

      test('bank should not require credit limit', () {
        final bankTemplate = AccountTemplate.getByType(AccountType.bank);
        expect(bankTemplate!.requiresCreditLimit, isFalse);
      });
    });

    group('requiresBankSelection', () {
      test('bank template should require bank selection', () {
        final bankTemplate = AccountTemplate.getByType(AccountType.bank);
        expect(bankTemplate!.requiresBankSelection, isTrue);
      });

      test('loan template should require bank selection', () {
        final loanTemplate = AccountTemplate.getByType(AccountType.loan);
        expect(loanTemplate!.requiresBankSelection, isTrue);
      });

      test('wallet should not require bank selection', () {
        final walletTemplate = AccountTemplate.getByType(AccountType.wallet);
        expect(walletTemplate!.requiresBankSelection, isFalse);
      });
    });
  });

  group('AccountConfigData', () {
    test('should create from template', () {
      final template = AccountTemplate.getByType(AccountType.bank)!;
      final config = AccountConfigData.fromTemplate(template);

      expect(config.type, AccountType.bank);
      expect(config.name, template.defaultName);
      expect(config.initialBalance, 0);
      expect(config.color, template.defaultColor);
      expect(config.emoji, template.emoji);
    });

    test('should serialize to JSON', () {
      final config = AccountConfigData(
        type: AccountType.bank,
        name: 'Mi Bancolombia',
        initialBalance: 1000000,
        bankName: 'Bancolombia',
        creditLimit: null,
        color: '#2196F3',
        emoji: '🏦',
      );

      final json = config.toJson();
      expect(json['type'], 'bank');
      expect(json['name'], 'Mi Bancolombia');
      expect(json['initialBalance'], 1000000);
      expect(json['bankName'], 'Bancolombia');
    });

    test('should deserialize from JSON', () {
      final json = {
        'type': 'credit',
        'name': 'Visa Bancolombia',
        'initialBalance': 500000.0,
        'bankName': 'Bancolombia',
        'creditLimit': 5000000.0,
        'color': '#F44336',
        'emoji': '💳',
      };

      final config = AccountConfigData.fromJson(json);
      expect(config.type, AccountType.credit);
      expect(config.name, 'Visa Bancolombia');
      expect(config.initialBalance, 500000);
      expect(config.creditLimit, 5000000);
    });

    test('should handle copyWith', () {
      final config = AccountConfigData(
        type: AccountType.wallet,
        name: 'Nequi',
        color: '#9C27B0',
        emoji: '📱',
      );

      final updated = config.copyWith(
        initialBalance: 200000,
        bankName: 'Nequi',
      );

      expect(updated.type, AccountType.wallet);
      expect(updated.name, 'Nequi');
      expect(updated.initialBalance, 200000);
      expect(updated.bankName, 'Nequi');
    });
  });

  group('Colombian Financial Context', () {
    test('should support major Colombian banks', () {
      final bankTemplate = AccountTemplate.getByType(AccountType.bank)!;
      final colombianBanks = [
        'Bancolombia',
        'Davivienda',
        'Banco de Bogotá',
        'BBVA',
        'Scotiabank Colpatria',
      ];

      for (final bank in colombianBanks) {
        expect(
          bankTemplate.suggestedNames!.contains(bank),
          isTrue,
          reason: '$bank should be in suggested names',
        );
      }
    });

    test('should support major Colombian fintech wallets', () {
      final walletTemplate = AccountTemplate.getByType(AccountType.wallet)!;
      final fintechs = ['Nequi', 'DaviPlata', 'DollarApp', 'Movii'];

      for (final fintech in fintechs) {
        expect(
          walletTemplate.suggestedNames!.contains(fintech),
          isTrue,
          reason: '$fintech should be in suggested names',
        );
      }
    });

    test('investment template should include CDT (Colombian term deposit)', () {
      final investmentTemplate = AccountTemplate.getByType(AccountType.investment)!;
      expect(investmentTemplate.suggestedNames!.contains('CDT'), isTrue);
    });
  });
}
