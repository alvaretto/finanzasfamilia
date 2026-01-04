"""
Transaction parser and normalizer.
Converts scraped transactions to Flutter-compatible format.
"""

import json
import re
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any

from config import CATEGORY_HINTS


class TransactionParser:
    """
    Parser for normalizing transactions from different sources.
    
    Outputs JSON format compatible with Finanzas Familiares Flutter app.
    """
    
    def __init__(self) -> None:
        """Initialize parser."""
        self.category_hints = CATEGORY_HINTS
    
    def parse_json_file(self, filepath: Path) -> list[dict]:
        """
        Parse a JSON export file.
        
        Args:
            filepath: Path to JSON file.
            
        Returns:
            List of normalized transaction dictionaries.
        """
        with open(filepath, "r", encoding="utf-8") as f:
            data = json.load(f)
        
        transactions = data.get("transactions", [])
        return [self.normalize_transaction(t) for t in transactions]
    
    def normalize_transaction(self, txn: dict) -> dict:
        """
        Normalize a transaction to Flutter-compatible format.
        
        Args:
            txn: Raw transaction dictionary.
            
        Returns:
            Normalized transaction for Flutter import.
        """
        # Generate UUID if not present
        txn_id = txn.get("id") or str(uuid.uuid4())
        
        # Parse date
        date_str = txn.get("date", datetime.now().strftime("%Y-%m-%d"))
        try:
            date = datetime.strptime(date_str, "%Y-%m-%d")
        except ValueError:
            date = datetime.now()
        
        # Parse amount
        amount = float(txn.get("amount", 0))
        
        # Determine type
        txn_type = txn.get("type", "expense")
        if txn_type not in ("income", "expense"):
            txn_type = "expense" if amount < 0 else "income"
        
        # Get description and clean it
        description = txn.get("description", "Transacción")
        description = self._clean_description(description)
        
        # Get or guess category
        category = txn.get("category_hint") or self._guess_category(description)
        
        return {
            "id": txn_id,
            "external_id": txn.get("id"),  # Original ID from bank
            "date": date.isoformat(),
            "description": description,
            "amount": abs(amount),  # Always positive
            "type": txn_type,
            "category": category,
            "source": txn.get("raw_data", {}).get("product", "import"),
            "imported_at": datetime.now().isoformat(),
            "metadata": {
                "original_amount": amount,
                "balance_after": txn.get("balance_after"),
            },
        }
    
    def _clean_description(self, description: str) -> str:
        """Clean and normalize description text."""
        if not description:
            return "Transacción"
        
        # Remove extra whitespace
        description = re.sub(r'\s+', ' ', description).strip()
        
        # Remove common prefixes
        prefixes_to_remove = [
            r'^Pago\s+',
            r'^Compra\s+',
            r'^Transferencia\s+',
        ]
        
        for prefix in prefixes_to_remove:
            description = re.sub(prefix, '', description, flags=re.IGNORECASE)
        
        # Capitalize first letter
        if description:
            description = description[0].upper() + description[1:]
        
        # Truncate if too long
        return description[:200]
    
    def _guess_category(self, description: str) -> str:
        """Guess category based on description keywords."""
        desc_lower = description.lower()
        
        for keyword, category in self.category_hints.items():
            if keyword in desc_lower:
                return category
        
        return "otros"
    
    def merge_transactions(
        self,
        *sources: list[dict],
        deduplicate: bool = True,
    ) -> list[dict]:
        """
        Merge transactions from multiple sources.
        
        Args:
            *sources: Lists of transaction dictionaries.
            deduplicate: Remove duplicates based on date+amount+description.
            
        Returns:
            Merged and optionally deduplicated list.
        """
        all_txns = []
        for source in sources:
            all_txns.extend(source)
        
        if not deduplicate:
            return sorted(all_txns, key=lambda t: t.get("date", ""), reverse=True)
        
        # Deduplicate
        seen = set()
        unique = []
        
        for txn in all_txns:
            key = (
                txn.get("date", "")[:10],  # Date only
                round(txn.get("amount", 0), 0),  # Rounded amount
                txn.get("description", "")[:20],  # First 20 chars of description
            )
            
            if key not in seen:
                seen.add(key)
                unique.append(txn)
        
        return sorted(unique, key=lambda t: t.get("date", ""), reverse=True)
    
    def to_flutter_import(self, transactions: list[dict], filepath: Path) -> Path:
        """
        Export transactions in Flutter import format.
        
        Args:
            transactions: List of normalized transactions.
            filepath: Output file path.
            
        Returns:
            Path to exported file.
        """
        data = {
            "version": "1.0",
            "exported_at": datetime.now().isoformat(),
            "app": "finanzas_familiares_rpa",
            "count": len(transactions),
            "transactions": transactions,
        }
        
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        return filepath
    
    def to_csv(self, transactions: list[dict], filepath: Path) -> Path:
        """
        Export transactions to CSV format.
        
        Args:
            transactions: List of normalized transactions.
            filepath: Output file path.
            
        Returns:
            Path to exported file.
        """
        import csv
        
        fieldnames = [
            "date",
            "description",
            "amount",
            "type",
            "category",
            "source",
        ]
        
        with open(filepath, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            
            for txn in transactions:
                row = {k: txn.get(k, "") for k in fieldnames}
                writer.writerow(row)
        
        return filepath
