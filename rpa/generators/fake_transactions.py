"""
Generador de transacciones fake con patrones colombianos.
Incluye comercios, categorias y montos realistas para COP.
"""

import uuid
import random
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from faker import Faker


class FakeTransactionGenerator:
    """Genera transacciones fake con patrones realistas para Colombia."""

    # Patrones de comercios colombianos
    MERCHANTS = {
        "supermercado": [
            ("Exito", "groceries", (-50000, -350000)),
            ("Carulla", "groceries", (-80000, -500000)),
            ("D1", "groceries", (-20000, -150000)),
            ("Ara", "groceries", (-25000, -180000)),
            ("Olimpica", "groceries", (-40000, -280000)),
            ("Jumbo", "groceries", (-60000, -400000)),
            ("Metro", "groceries", (-45000, -300000)),
        ],
        "restaurante": [
            ("Rappi - Restaurante", "food", (-15000, -80000)),
            ("iFood", "food", (-12000, -60000)),
            ("Crepes & Waffles", "food", (-35000, -120000)),
            ("El Corral", "food", (-20000, -60000)),
            ("Archies", "food", (-25000, -80000)),
            ("Wok", "food", (-30000, -100000)),
            ("Frisby", "food", (-18000, -50000)),
        ],
        "transporte": [
            ("Uber", "transport", (-8000, -45000)),
            ("DiDi", "transport", (-7000, -40000)),
            ("InDriver", "transport", (-6000, -35000)),
            ("Gasolina Terpel", "transport", (-50000, -200000)),
            ("Gasolina Primax", "transport", (-45000, -180000)),
            ("TransMilenio", "transport", (-2950, -2950)),
            ("SITP", "transport", (-2650, -2650)),
        ],
        "servicios": [
            ("EPM Servicios", "utilities", (-80000, -350000)),
            ("Claro Internet", "utilities", (-60000, -150000)),
            ("Movistar", "utilities", (-40000, -120000)),
            ("Tigo", "utilities", (-35000, -100000)),
            ("ETB", "utilities", (-50000, -130000)),
            ("Gas Natural", "utilities", (-30000, -150000)),
        ],
        "suscripciones": [
            ("Netflix", "entertainment", (-26900, -44900)),
            ("Spotify", "entertainment", (-16900, -26900)),
            ("HBO Max", "entertainment", (-24900, -34900)),
            ("Disney+", "entertainment", (-28900, -28900)),
            ("Amazon Prime", "entertainment", (-14900, -14900)),
            ("YouTube Premium", "entertainment", (-22900, -22900)),
        ],
        "salud": [
            ("Farmatodo", "health", (-15000, -120000)),
            ("Drogas La Rebaja", "health", (-10000, -80000)),
            ("Locatel", "health", (-20000, -200000)),
            ("Cruz Verde", "health", (-12000, -100000)),
        ],
        "ropa": [
            ("Zara", "shopping", (-80000, -400000)),
            ("Falabella", "shopping", (-50000, -500000)),
            ("Arturo Calle", "shopping", (-100000, -600000)),
            ("Tennis", "shopping", (-40000, -200000)),
            ("Studio F", "shopping", (-60000, -350000)),
        ],
    }

    INCOME_SOURCES = [
        ("Salario mensual", "salary", (2500000, 15000000)),
        ("Bonificacion", "salary", (500000, 3000000)),
        ("Freelance", "freelance", (200000, 5000000)),
        ("Transferencia recibida", "transfer", (50000, 2000000)),
        ("Rendimientos", "investment", (10000, 500000)),
        ("Reembolso", "other", (20000, 300000)),
    ]

    CATEGORIES = [
        "groceries", "food", "transport", "utilities", "entertainment",
        "health", "shopping", "salary", "freelance", "transfer",
        "investment", "other"
    ]

    def __init__(self, locale: str = "es_CO", seed: Optional[int] = None):
        """
        Inicializa el generador.

        Args:
            locale: Locale para Faker (default: es_CO)
            seed: Seed para reproducibilidad
        """
        self.faker = Faker(locale)
        if seed:
            Faker.seed(seed)
            random.seed(seed)

    def generate(
        self,
        count: int = 100,
        days_back: int = 30,
        pattern: str = "mixed",
        account_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Genera transacciones fake.

        Args:
            count: Numero de transacciones
            days_back: Rango de dias hacia atras
            pattern: Patron de generacion (mixed, salary, freelance, student)
            account_id: ID de cuenta (genera uno si no se proporciona)

        Returns:
            Lista de transacciones
        """
        transactions = []
        acc_id = account_id or str(uuid.uuid4())

        # Configurar distribucion segun patron
        income_ratio = self._get_income_ratio(pattern)

        for _ in range(count):
            # Decidir si es ingreso o gasto
            is_income = random.random() < income_ratio

            if is_income:
                tx = self._generate_income(acc_id, days_back)
            else:
                tx = self._generate_expense(acc_id, days_back)

            transactions.append(tx)

        # Ordenar por fecha
        transactions.sort(key=lambda x: x["date"], reverse=True)

        return transactions

    def _get_income_ratio(self, pattern: str) -> float:
        """Obtiene ratio de ingresos segun patron."""
        ratios = {
            "mixed": 0.15,      # 15% ingresos
            "salary": 0.08,    # 8% ingresos (solo salario mensual)
            "freelance": 0.20, # 20% ingresos (mas variados)
            "student": 0.05,   # 5% ingresos (mesada/trabajos esporadicos)
        }
        return ratios.get(pattern, 0.15)

    def _generate_income(self, account_id: str, days_back: int) -> Dict[str, Any]:
        """Genera una transaccion de ingreso."""
        source = random.choice(self.INCOME_SOURCES)
        description, category, (min_amount, max_amount) = source

        return {
            "id": str(uuid.uuid4()),
            "account_id": account_id,
            "amount": random.randint(min_amount, max_amount),
            "description": description,
            "category": category,
            "type": "income",
            "date": self._random_date(days_back).isoformat(),
            "created_at": datetime.now().isoformat(),
            "is_synced": False,
        }

    def _generate_expense(self, account_id: str, days_back: int) -> Dict[str, Any]:
        """Genera una transaccion de gasto."""
        # Elegir categoria aleatoria
        category_key = random.choice(list(self.MERCHANTS.keys()))
        merchant = random.choice(self.MERCHANTS[category_key])
        description, category, (amount_a, amount_b) = merchant

        # Los gastos son negativos - asegurar orden correcto para randint
        min_amount, max_amount = min(amount_a, amount_b), max(amount_a, amount_b)
        amount = random.randint(min_amount, max_amount)

        return {
            "id": str(uuid.uuid4()),
            "account_id": account_id,
            "amount": amount,  # Negativo
            "description": description,
            "category": category,
            "type": "expense",
            "date": self._random_date(days_back).isoformat(),
            "created_at": datetime.now().isoformat(),
            "is_synced": False,
        }

    def _random_date(self, days_back: int) -> datetime:
        """Genera una fecha aleatoria en el rango."""
        days_ago = random.randint(0, days_back)
        hours = random.randint(6, 22)  # Entre 6am y 10pm
        minutes = random.randint(0, 59)

        date = datetime.now() - timedelta(days=days_ago)
        return date.replace(hour=hours, minute=minutes, second=0, microsecond=0)

    def generate_monthly_pattern(
        self,
        months: int = 3,
        account_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Genera transacciones con patron mensual realista.
        Incluye salario fijo, gastos recurrentes y variables.

        Args:
            months: Numero de meses a generar
            account_id: ID de cuenta

        Returns:
            Lista de transacciones
        """
        transactions = []
        acc_id = account_id or str(uuid.uuid4())

        salary = random.randint(3000000, 8000000)

        for month_offset in range(months):
            base_date = datetime.now() - timedelta(days=30 * month_offset)

            # Salario el 15 y 30 de cada mes
            for day in [15, 30]:
                tx_date = base_date.replace(day=min(day, 28))
                transactions.append({
                    "id": str(uuid.uuid4()),
                    "account_id": acc_id,
                    "amount": salary // 2,
                    "description": "Salario quincenal",
                    "category": "salary",
                    "type": "income",
                    "date": tx_date.isoformat(),
                    "created_at": datetime.now().isoformat(),
                    "is_synced": False,
                })

            # Gastos fijos mensuales
            fixed_expenses = [
                ("Arriendo", "housing", -random.randint(800000, 2500000)),
                ("Servicios EPM", "utilities", -random.randint(150000, 400000)),
                ("Internet Claro", "utilities", -random.randint(60000, 120000)),
                ("Netflix", "entertainment", -26900),
                ("Spotify", "entertainment", -16900),
            ]

            for desc, cat, amount in fixed_expenses:
                tx_date = base_date.replace(day=random.randint(1, 10))
                transactions.append({
                    "id": str(uuid.uuid4()),
                    "account_id": acc_id,
                    "amount": amount,
                    "description": desc,
                    "category": cat,
                    "type": "expense",
                    "date": tx_date.isoformat(),
                    "created_at": datetime.now().isoformat(),
                    "is_synced": False,
                })

            # Gastos variables (20-40 por mes)
            variable_count = random.randint(20, 40)
            for _ in range(variable_count):
                tx = self._generate_expense(acc_id, 30)
                tx["date"] = base_date.replace(
                    day=random.randint(1, 28)
                ).isoformat()
                transactions.append(tx)

        transactions.sort(key=lambda x: x["date"], reverse=True)
        return transactions
