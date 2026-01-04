"""
Importador de archivos JSON.
Normaliza estructuras JSON variadas al formato de la app.
"""

import uuid
import json
from datetime import datetime
from typing import List, Dict, Any, Optional
from pathlib import Path


class JSONImporter:
    """Importa y normaliza transacciones desde archivos JSON."""

    # Mapeo de campos comunes
    FIELD_MAPPINGS = {
        "id": ["id", "uuid", "transaction_id", "transactionId"],
        "account_id": ["account_id", "accountId", "cuenta_id", "cuentaId"],
        "amount": ["amount", "monto", "valor", "value", "cantidad"],
        "description": ["description", "descripcion", "concepto", "detail", "detalle", "name"],
        "category": ["category", "categoria", "type", "tipo"],
        "date": ["date", "fecha", "timestamp", "created", "datetime"],
        "type": ["transaction_type", "tipo_transaccion", "movement_type", "kind"],
    }

    # Categorias validas
    VALID_CATEGORIES = [
        "groceries", "food", "transport", "utilities", "entertainment",
        "health", "shopping", "salary", "freelance", "transfer",
        "investment", "housing", "education", "other"
    ]

    def __init__(self):
        """Inicializa el importador."""
        pass

    def import_file(
        self,
        file_path: str,
        account_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Importa transacciones desde archivo JSON.

        Args:
            file_path: Ruta al archivo JSON
            account_id: ID de cuenta destino

        Returns:
            Lista de transacciones normalizadas
        """
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        # Manejar diferentes estructuras
        if isinstance(data, list):
            raw_transactions = data
        elif isinstance(data, dict):
            # Buscar array de transacciones
            raw_transactions = self._find_transactions_array(data)
        else:
            raise ValueError("Estructura JSON no soportada")

        # Normalizar cada transaccion
        transactions = []
        acc_id = account_id or str(uuid.uuid4())

        for raw_tx in raw_transactions:
            tx = self._normalize_transaction(raw_tx, acc_id)
            if tx:
                transactions.append(tx)

        return transactions

    def _find_transactions_array(self, data: Dict) -> List:
        """Busca el array de transacciones en un objeto."""
        # Claves comunes
        possible_keys = [
            "transactions", "transacciones", "data", "items",
            "records", "registros", "movements", "movimientos"
        ]

        for key in possible_keys:
            if key in data and isinstance(data[key], list):
                return data[key]

        # Buscar cualquier array
        for value in data.values():
            if isinstance(value, list) and len(value) > 0:
                if isinstance(value[0], dict):
                    return value

        raise ValueError("No se encontro array de transacciones en el JSON")

    def _normalize_transaction(
        self,
        raw: Dict[str, Any],
        account_id: str
    ) -> Optional[Dict[str, Any]]:
        """Normaliza una transaccion al formato de la app."""
        try:
            # Extraer campos
            tx_id = self._find_field(raw, "id") or str(uuid.uuid4())
            acc_id = self._find_field(raw, "account_id") or account_id
            amount = self._parse_amount(self._find_field(raw, "amount"))
            description = str(self._find_field(raw, "description") or "Sin descripcion")
            category = self._normalize_category(self._find_field(raw, "category"))
            date = self._parse_date(self._find_field(raw, "date"))
            tx_type = self._determine_type(raw, amount)

            if amount is None:
                return None

            return {
                "id": str(tx_id),
                "account_id": str(acc_id),
                "amount": amount,
                "description": description[:200],
                "category": category,
                "type": tx_type,
                "date": date.isoformat(),
                "created_at": datetime.now().isoformat(),
                "is_synced": False,
                "source": "json_import",
            }
        except Exception:
            return None

    def _find_field(self, raw: Dict, field_type: str) -> Optional[Any]:
        """Busca un campo usando el mapeo."""
        possible_keys = self.FIELD_MAPPINGS.get(field_type, [field_type])

        for key in possible_keys:
            if key in raw:
                return raw[key]
            # Buscar case-insensitive
            for raw_key in raw.keys():
                if raw_key.lower() == key.lower():
                    return raw[raw_key]

        return None

    def _parse_amount(self, value: Any) -> Optional[int]:
        """Parsea el monto a entero."""
        if value is None:
            return None

        if isinstance(value, (int, float)):
            return int(value)

        # Limpiar string
        amount_str = str(value)
        amount_str = amount_str.replace("$", "")
        amount_str = amount_str.replace(",", "")
        amount_str = amount_str.replace(" ", "")

        try:
            return int(float(amount_str))
        except ValueError:
            return None

    def _parse_date(self, value: Any) -> datetime:
        """Parsea diferentes formatos de fecha."""
        if value is None:
            return datetime.now()

        if isinstance(value, datetime):
            return value

        date_str = str(value)

        # ISO format
        try:
            return datetime.fromisoformat(date_str.replace("Z", "+00:00"))
        except ValueError:
            pass

        # Otros formatos
        from dateutil import parser
        try:
            return parser.parse(date_str)
        except:
            return datetime.now()

    def _normalize_category(self, value: Any) -> str:
        """Normaliza la categoria."""
        if not value:
            return "other"

        cat = str(value).lower().strip()

        # Mapeo de categorias en español
        spanish_mapping = {
            "mercado": "groceries",
            "supermercado": "groceries",
            "comida": "food",
            "restaurante": "food",
            "transporte": "transport",
            "servicios": "utilities",
            "entretenimiento": "entertainment",
            "salud": "health",
            "compras": "shopping",
            "salario": "salary",
            "transferencia": "transfer",
            "inversion": "investment",
            "vivienda": "housing",
            "educacion": "education",
        }

        if cat in spanish_mapping:
            return spanish_mapping[cat]

        if cat in self.VALID_CATEGORIES:
            return cat

        return "other"

    def _determine_type(self, raw: Dict, amount: int) -> str:
        """Determina el tipo de transaccion."""
        # Primero revisar campo explicito
        tx_type = self._find_field(raw, "type")
        if tx_type:
            type_lower = str(tx_type).lower()
            if type_lower in ["income", "ingreso", "credit", "credito"]:
                return "income"
            if type_lower in ["expense", "gasto", "debit", "debito"]:
                return "expense"

        # Basarse en el monto
        return "income" if amount > 0 else "expense"
