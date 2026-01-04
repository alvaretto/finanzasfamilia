"""
Importador de archivos CSV de bancos colombianos.
Soporta formatos de Bancolombia, Davivienda, Nequi y generico.
"""

import uuid
import pandas as pd
from datetime import datetime
from typing import List, Dict, Any, Optional
from pathlib import Path


class CSVImporter:
    """Importa transacciones desde archivos CSV de bancos."""

    # Mapeo de columnas por banco
    COLUMN_MAPPINGS = {
        "bancolombia": {
            "date": ["Fecha", "FECHA", "fecha"],
            "description": ["Descripcion", "DESCRIPCION", "Concepto"],
            "amount": ["Valor", "VALOR", "Monto"],
            "type": ["Tipo", "TIPO", "Movimiento"],
        },
        "davivienda": {
            "date": ["Fecha Movimiento", "Fecha"],
            "description": ["Descripcion", "Concepto"],
            "amount": ["Valor", "Monto"],
            "type": ["Tipo Movimiento", "Tipo"],
        },
        "nequi": {
            "date": ["Fecha", "fecha"],
            "description": ["Descripcion", "descripcion", "Detalle"],
            "amount": ["Monto", "monto", "Valor"],
            "type": ["Tipo", "tipo"],
        },
        "generic": {
            "date": ["date", "fecha", "Date", "Fecha"],
            "description": ["description", "descripcion", "Description", "Descripcion", "concept"],
            "amount": ["amount", "monto", "Amount", "Monto", "value", "Valor"],
            "type": ["type", "tipo", "Type", "Tipo"],
        },
    }

    # Categorias por palabras clave
    CATEGORY_KEYWORDS = {
        "groceries": ["exito", "carulla", "d1", "ara", "olimpica", "jumbo", "metro", "supermercado"],
        "food": ["rappi", "ifood", "restaurante", "comida", "almuerzo", "cena"],
        "transport": ["uber", "didi", "indriver", "gasolina", "transmilenio", "sitp", "taxi"],
        "utilities": ["epm", "claro", "movistar", "tigo", "etb", "gas natural", "acueducto"],
        "entertainment": ["netflix", "spotify", "hbo", "disney", "amazon", "cine"],
        "health": ["farmacia", "drogueria", "eps", "medicina", "salud"],
        "shopping": ["zara", "falabella", "exito", "homecenter", "alkosto"],
        "salary": ["nomina", "salario", "sueldo", "pago mensual"],
        "transfer": ["transferencia", "envio", "recibido de"],
    }

    def __init__(self):
        """Inicializa el importador."""
        pass

    def import_file(
        self,
        file_path: str,
        format: str = "auto",
        account_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Importa transacciones desde archivo CSV.

        Args:
            file_path: Ruta al archivo CSV
            format: Formato del banco (auto, bancolombia, davivienda, nequi, generic)
            account_id: ID de cuenta destino

        Returns:
            Lista de transacciones normalizadas
        """
        # Detectar encoding
        encodings = ["utf-8", "latin-1", "cp1252"]
        df = None

        for encoding in encodings:
            try:
                df = pd.read_csv(file_path, encoding=encoding)
                break
            except UnicodeDecodeError:
                continue

        if df is None:
            raise ValueError(f"No se pudo leer el archivo con encodings: {encodings}")

        # Auto-detectar formato si es necesario
        if format == "auto":
            format = self._detect_format(df)

        # Obtener mapeo de columnas
        mapping = self.COLUMN_MAPPINGS.get(format, self.COLUMN_MAPPINGS["generic"])

        # Normalizar columnas
        transactions = []
        acc_id = account_id or str(uuid.uuid4())

        for _, row in df.iterrows():
            tx = self._parse_row(row, mapping, acc_id)
            if tx:
                transactions.append(tx)

        return transactions

    def _detect_format(self, df: pd.DataFrame) -> str:
        """Detecta el formato del banco basado en las columnas."""
        columns = [col.lower() for col in df.columns]

        # Bancolombia tiene columnas especificas
        if any("bancolombia" in col for col in columns):
            return "bancolombia"

        # Davivienda
        if "fecha movimiento" in columns:
            return "davivienda"

        # Nequi
        if any("nequi" in col for col in columns):
            return "nequi"

        return "generic"

    def _parse_row(
        self,
        row: pd.Series,
        mapping: Dict[str, List[str]],
        account_id: str
    ) -> Optional[Dict[str, Any]]:
        """Parsea una fila del CSV a transaccion."""
        try:
            # Buscar columnas
            date_val = self._find_column_value(row, mapping["date"])
            desc_val = self._find_column_value(row, mapping["description"])
            amount_val = self._find_column_value(row, mapping["amount"])
            type_val = self._find_column_value(row, mapping.get("type", []))

            if not all([date_val, desc_val, amount_val]):
                return None

            # Parsear fecha
            date = self._parse_date(date_val)

            # Parsear monto
            amount = self._parse_amount(amount_val)

            # Determinar tipo
            tx_type = self._determine_type(amount, type_val, desc_val)

            # Inferir categoria
            category = self._infer_category(desc_val)

            return {
                "id": str(uuid.uuid4()),
                "account_id": account_id,
                "amount": amount,
                "description": str(desc_val)[:200],
                "category": category,
                "type": tx_type,
                "date": date.isoformat(),
                "created_at": datetime.now().isoformat(),
                "is_synced": False,
                "source": "csv_import",
            }
        except Exception:
            return None

    def _find_column_value(self, row: pd.Series, column_names: List[str]) -> Optional[Any]:
        """Busca el valor en las posibles columnas."""
        for col in column_names:
            if col in row.index:
                return row[col]
        return None

    def _parse_date(self, date_val: Any) -> datetime:
        """Parsea diferentes formatos de fecha."""
        if isinstance(date_val, datetime):
            return date_val

        date_str = str(date_val)

        # Formatos comunes en Colombia
        formats = [
            "%Y-%m-%d",
            "%d/%m/%Y",
            "%d-%m-%Y",
            "%Y/%m/%d",
            "%d/%m/%y",
            "%d-%m-%y",
        ]

        for fmt in formats:
            try:
                return datetime.strptime(date_str, fmt)
            except ValueError:
                continue

        # Fallback
        from dateutil import parser
        return parser.parse(date_str)

    def _parse_amount(self, amount_val: Any) -> int:
        """Parsea el monto a entero (COP no usa decimales)."""
        if isinstance(amount_val, (int, float)):
            return int(amount_val)

        amount_str = str(amount_val)

        # Limpiar formato colombiano
        amount_str = amount_str.replace("$", "")
        amount_str = amount_str.replace(".", "")  # Separador de miles
        amount_str = amount_str.replace(",", ".")  # Posible decimal
        amount_str = amount_str.replace(" ", "")

        return int(float(amount_str))

    def _determine_type(
        self,
        amount: int,
        type_val: Optional[str],
        description: str
    ) -> str:
        """Determina si es ingreso o gasto."""
        if amount > 0:
            return "income"
        elif amount < 0:
            return "expense"

        # Revisar tipo explicito
        if type_val:
            type_lower = str(type_val).lower()
            if any(w in type_lower for w in ["credito", "abono", "ingreso"]):
                return "income"
            if any(w in type_lower for w in ["debito", "cargo", "gasto"]):
                return "expense"

        return "expense"

    def _infer_category(self, description: str) -> str:
        """Infiere la categoria basada en la descripcion."""
        desc_lower = str(description).lower()

        for category, keywords in self.CATEGORY_KEYWORDS.items():
            if any(kw in desc_lower for kw in keywords):
                return category

        return "other"
