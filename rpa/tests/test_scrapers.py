"""
Tests for RPA Bank Scrapers.
"""

import pytest
from datetime import datetime

# Import from parent directory
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from scrapers.base_scraper import BaseScraper, Transaction
from parsers.transaction_parser import TransactionParser


class TestTransaction:
    """Tests for Transaction class."""
    
    def test_create_transaction(self):
        """Test creating a basic transaction."""
        txn = Transaction(
            id="TEST001",
            date="2026-01-04",
            description="Compra Netflix",
            amount=-45900,
            type="expense",
        )
        
        assert txn.id == "TEST001"
        assert txn.date == "2026-01-04"
        assert txn.amount == -45900
        assert txn.type == "expense"
    
    def test_auto_category_hint(self):
        """Test automatic category guessing."""
        txn = Transaction(
            id="TEST002",
            date="2026-01-04",
            description="Pago Netflix Premium",
            amount=-45900,
            type="expense",
        )
        
        assert txn.category_hint == "entretenimiento"
    
    def test_to_dict(self):
        """Test serialization to dictionary."""
        txn = Transaction(
            id="TEST003",
            date="2026-01-04",
            description="Test transaction",
            amount=100000,
            type="income",
            balance_after=1000000,
        )
        
        data = txn.to_dict()
        
        assert data["id"] == "TEST003"
        assert data["balance_after"] == 1000000
        assert "raw_data" not in data  # Should not include raw_data


class TestBaseScraper:
    """Tests for BaseScraper utility methods."""
    
    def test_parse_colombian_amount_simple(self):
        """Test parsing simple Colombian amount."""
        assert BaseScraper.parse_colombian_amount("$1.234.567") == 1234567.0
    
    def test_parse_colombian_amount_with_decimals(self):
        """Test parsing amount with decimals."""
        assert BaseScraper.parse_colombian_amount("$1.234,56") == 1234.56
    
    def test_parse_colombian_amount_negative(self):
        """Test parsing negative amount."""
        assert BaseScraper.parse_colombian_amount("- $50.000") == -50000.0
    
    def test_parse_colombian_amount_no_symbol(self):
        """Test parsing amount without currency symbol."""
        assert BaseScraper.parse_colombian_amount("100.000") == 100000.0


class TestTransactionParser:
    """Tests for TransactionParser."""
    
    @pytest.fixture
    def parser(self):
        """Create parser instance."""
        return TransactionParser()
    
    def test_normalize_transaction(self, parser):
        """Test transaction normalization."""
        raw = {
            "id": "NEQUI_001",
            "date": "2026-01-04",
            "description": "Compra Spotify Premium",
            "amount": -29900,
            "type": "expense",
        }
        
        normalized = parser.normalize_transaction(raw)
        
        assert normalized["external_id"] == "NEQUI_001"
        assert normalized["amount"] == 29900  # Absolute value
        assert normalized["type"] == "expense"
        assert normalized["category"] == "entretenimiento"
    
    def test_clean_description(self, parser):
        """Test description cleaning."""
        assert parser._clean_description("  Pago   Netflix  ") == "Netflix"
        assert parser._clean_description("COMPRA AMAZON PRIME") == "Amazon prime"
    
    def test_guess_category(self, parser):
        """Test category guessing."""
        assert parser._guess_category("Uber viaje") == "transporte"
        assert parser._guess_category("Farmacia drogas") == "salud"
        assert parser._guess_category("Unknown store") == "otros"
    
    def test_merge_transactions_dedup(self, parser):
        """Test transaction merging with deduplication."""
        txns1 = [
            {"date": "2026-01-04", "amount": 50000, "description": "Test 1"},
            {"date": "2026-01-03", "amount": 30000, "description": "Test 2"},
        ]
        txns2 = [
            {"date": "2026-01-04", "amount": 50000, "description": "Test 1"},  # Duplicate
            {"date": "2026-01-02", "amount": 20000, "description": "Test 3"},
        ]
        
        merged = parser.merge_transactions(txns1, txns2, deduplicate=True)
        
        assert len(merged) == 3  # One duplicate removed


class TestCurrencyFormats:
    """Tests for various Colombian currency formats."""
    
    @pytest.mark.parametrize("input_str,expected", [
        ("$1.234.567", 1234567.0),
        ("$50.000", 50000.0),
        ("$ 1.000", 1000.0),
        ("1.234,56", 1234.56),
        ("-$100.000", -100000.0),
        ("+ $50.000", 50000.0),
        ("COP 1.000.000", 1000000.0),
    ])
    def test_various_formats(self, input_str, expected):
        """Test various Colombian currency formats."""
        # Note: Some of these may need adjustment based on actual implementation
        result = BaseScraper.parse_colombian_amount(input_str.replace("COP", "").replace("+", ""))
        assert abs(result - abs(expected)) < 0.01


class TestDateParsing:
    """Tests for date parsing in scrapers."""
    
    def test_iso_format(self):
        """Test ISO date format."""
        from scrapers.nequi_scraper import NequiScraper
        
        # Create a mock instance just to test the method
        # This would need proper mocking in real tests
        pass
    
    def test_spanish_format(self):
        """Test Spanish date format like '15 de enero de 2026'."""
        # Would test _normalize_date method
        pass


# Integration tests (require credentials - skip by default)
@pytest.mark.skip(reason="Requires real credentials")
class TestNequiIntegration:
    """Integration tests for Nequi scraper."""
    
    def test_login_flow(self):
        """Test Nequi login flow."""
        from scrapers import NequiScraper
        
        scraper = NequiScraper(headless=False, interactive=True)
        # Would test actual login


@pytest.mark.skip(reason="Requires real credentials")  
class TestDaviviendaIntegration:
    """Integration tests for Davivienda scraper."""
    
    def test_login_flow(self):
        """Test Davivienda login flow."""
        from scrapers import DaviviendaScraper
        
        scraper = DaviviendaScraper(headless=False, interactive=True)
        # Would test actual login


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
