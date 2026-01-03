---
name: sync-check
description: Verifica la implementacion de sync en todos los providers
---

# Sync Check

Verifica que todos los providers implementan sync silencioso correctamente:

1. Revisar account_provider.dart:
   - Verificar que `syncAccounts` tiene parametro `showError`
   - Verificar que syncs automaticos usan `showError: false`

2. Revisar transaction_provider.dart:
   - Verificar que `syncTransactions` tiene parametro `showError`
   - Verificar que syncs automaticos usan `showError: false`

3. Revisar budget_provider.dart:
   - Verificar que `syncBudgets` tiene parametro `showError`
   - Verificar que syncs automaticos usan `showError: false`

4. Revisar goal_provider.dart:
   - Verificar que `syncGoals` tiene parametro `showError`
   - Verificar que syncs automaticos usan `showError: false`

5. Reportar el estado de cada provider:
   - OK: Implementa sync silencioso correctamente
   - WARNING: Falta parametro showError o uso incorrecto
