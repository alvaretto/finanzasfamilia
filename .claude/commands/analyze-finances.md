---
name: analyze-finances
description: Analiza la implementacion de calculos financieros
---

# Analyze Finances

Analiza la correcta implementacion de calculos financieros:

1. Verificar clasificacion de cuentas:
   - AccountType.isAsset para bank, cash, savings, investment
   - AccountType.isLiability para credit, loan, payable
   - Caso especial: receivable (por cobrar)

2. Verificar calculos de patrimonio neto:
   - assets = sum(cuentas donde isAsset)
   - liabilities = sum(abs(cuentas donde isLiability))
   - netWorth = assets - liabilities

3. Verificar calculos de presupuesto:
   - percentSpent = spent / amount * 100 (con proteccion division por cero)
   - remaining = amount - spent
   - isOverBudget = spent > amount

4. Verificar calculos de metas:
   - percentComplete = currentAmount / targetAmount * 100 (con proteccion)
   - isCompleted = currentAmount >= targetAmount

5. Reportar cualquier problema encontrado en los calculos.
