"""
Tests unitarios para el generador de transacciones fake.
"""

import pytest
from datetime import datetime, timedelta
from generators.fake_transactions import FakeTransactionGenerator


class TestFakeTransactionGenerator:
    """Tests para FakeTransactionGenerator."""

    def setup_method(self):
        """Setup para cada test."""
        self.generator = FakeTransactionGenerator(locale="es_CO", seed=42)

    def test_generate_returns_list(self):
        """Genera una lista de transacciones."""
        result = self.generator.generate(count=10)
        assert isinstance(result, list)
        assert len(result) == 10

    def test_generate_transaction_structure(self):
        """Cada transaccion tiene la estructura correcta."""
        result = self.generator.generate(count=1)
        tx = result[0]

        required_fields = [
            "id", "account_id", "amount", "description",
            "category", "type", "date", "created_at", "is_synced"
        ]

        for field in required_fields:
            assert field in tx, f"Falta campo: {field}"

    def test_generate_valid_types(self):
        """Los tipos son income o expense."""
        result = self.generator.generate(count=100)

        for tx in result:
            assert tx["type"] in ["income", "expense"]

    def test_generate_valid_categories(self):
        """Las categorias son validas."""
        valid_categories = [
            "groceries", "food", "transport", "utilities", "entertainment",
            "health", "shopping", "salary", "freelance", "transfer",
            "investment", "other"
        ]

        result = self.generator.generate(count=100)

        for tx in result:
            assert tx["category"] in valid_categories, f"Categoria invalida: {tx['category']}"

    def test_generate_amounts_cop(self):
        """Los montos son enteros (COP no usa decimales)."""
        result = self.generator.generate(count=100)

        for tx in result:
            assert isinstance(tx["amount"], int)

    def test_generate_income_positive(self):
        """Los ingresos tienen montos positivos."""
        result = self.generator.generate(count=100)
        incomes = [tx for tx in result if tx["type"] == "income"]

        for tx in incomes:
            assert tx["amount"] > 0

    def test_generate_expense_negative(self):
        """Los gastos tienen montos negativos."""
        result = self.generator.generate(count=100)
        expenses = [tx for tx in result if tx["type"] == "expense"]

        for tx in expenses:
            assert tx["amount"] < 0

    def test_generate_dates_in_range(self):
        """Las fechas estan dentro del rango especificado."""
        days_back = 30
        result = self.generator.generate(count=50, days_back=days_back)

        now = datetime.now()
        min_date = now - timedelta(days=days_back + 1)

        for tx in result:
            tx_date = datetime.fromisoformat(tx["date"])
            assert tx_date >= min_date
            assert tx_date <= now + timedelta(hours=1)

    def test_generate_sorted_by_date(self):
        """Las transacciones estan ordenadas por fecha descendente."""
        result = self.generator.generate(count=50)

        dates = [datetime.fromisoformat(tx["date"]) for tx in result]

        for i in range(len(dates) - 1):
            assert dates[i] >= dates[i + 1]

    def test_generate_with_account_id(self):
        """Usa el account_id proporcionado."""
        custom_id = "test-account-123"
        result = self.generator.generate(count=10, account_id=custom_id)

        for tx in result:
            assert tx["account_id"] == custom_id

    def test_generate_unique_ids(self):
        """Cada transaccion tiene ID unico."""
        result = self.generator.generate(count=100)
        ids = [tx["id"] for tx in result]

        assert len(ids) == len(set(ids))

    def test_pattern_salary_low_income_ratio(self):
        """Patron salary tiene bajo ratio de ingresos."""
        result = self.generator.generate(count=200, pattern="salary")
        incomes = [tx for tx in result if tx["type"] == "income"]

        # Deberia ser ~8% ingresos
        ratio = len(incomes) / len(result)
        assert ratio < 0.20  # Menos del 20%

    def test_pattern_freelance_higher_income_ratio(self):
        """Patron freelance tiene mayor ratio de ingresos."""
        result = self.generator.generate(count=200, pattern="freelance")
        incomes = [tx for tx in result if tx["type"] == "income"]

        # Deberia ser ~20% ingresos
        ratio = len(incomes) / len(result)
        assert ratio > 0.10  # Mas del 10%

    def test_generate_monthly_pattern(self):
        """Genera patron mensual con salario y gastos fijos."""
        result = self.generator.generate_monthly_pattern(months=2)

        # Deberia tener salarios
        salaries = [tx for tx in result if tx["category"] == "salary"]
        assert len(salaries) >= 2  # Al menos 2 meses de salario

        # Deberia tener gastos de servicios
        utilities = [tx for tx in result if tx["category"] == "utilities"]
        assert len(utilities) > 0

    def test_reproducibility_with_seed(self):
        """El seed produce resultados reproducibles."""
        gen1 = FakeTransactionGenerator(seed=123)
        gen2 = FakeTransactionGenerator(seed=123)

        result1 = gen1.generate(count=10)
        result2 = gen2.generate(count=10)

        # Deberian ser identicos
        for tx1, tx2 in zip(result1, result2):
            assert tx1["amount"] == tx2["amount"]
            assert tx1["description"] == tx2["description"]

    def test_colombian_merchants(self):
        """Incluye comercios colombianos."""
        result = self.generator.generate(count=200)
        descriptions = [tx["description"] for tx in result]

        colombian_merchants = ["Exito", "Carulla", "D1", "Ara", "Rappi", "Uber"]

        found_any = any(
            any(merchant in desc for merchant in colombian_merchants)
            for desc in descriptions
        )

        assert found_any, "Deberia incluir comercios colombianos"


class TestFakeTransactionGeneratorEdgeCases:
    """Tests de casos limite."""

    def test_generate_zero_count(self):
        """Genera lista vacia con count=0."""
        generator = FakeTransactionGenerator()
        result = generator.generate(count=0)
        assert result == []

    def test_generate_large_count(self):
        """Puede generar muchas transacciones."""
        generator = FakeTransactionGenerator()
        result = generator.generate(count=1000)
        assert len(result) == 1000

    def test_generate_one_day_range(self):
        """Funciona con rango de 1 dia."""
        generator = FakeTransactionGenerator()
        result = generator.generate(count=10, days_back=1)

        now = datetime.now()
        yesterday = now - timedelta(days=2)

        for tx in result:
            tx_date = datetime.fromisoformat(tx["date"])
            assert tx_date >= yesterday


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
