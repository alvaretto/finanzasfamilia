"""
Base scraper class with common functionality for all bank scrapers.
Uses Playwright for browser automation.
"""

import json
from abc import ABC, abstractmethod
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any

from loguru import logger
from playwright.sync_api import Browser, BrowserContext, Page, Playwright, sync_playwright

from config import config, CATEGORY_HINTS


class Transaction:
    """Represents a single bank transaction."""
    
    def __init__(
        self,
        id: str,
        date: str,
        description: str,
        amount: float,
        type: str,  # "income" or "expense"
        balance_after: float | None = None,
        category_hint: str | None = None,
        raw_data: dict | None = None,
    ) -> None:
        self.id = id
        self.date = date
        self.description = description
        self.amount = amount
        self.type = type
        self.balance_after = balance_after
        self.category_hint = category_hint or self._guess_category()
        self.raw_data = raw_data or {}
    
    def _guess_category(self) -> str:
        """Attempt to guess category based on description."""
        desc_lower = self.description.lower()
        for keyword, category in CATEGORY_HINTS.items():
            if keyword in desc_lower:
                return category
        return "otros"
    
    def to_dict(self) -> dict:
        """Convert to dictionary for JSON serialization."""
        return {
            "id": self.id,
            "date": self.date,
            "description": self.description,
            "amount": self.amount,
            "type": self.type,
            "balance_after": self.balance_after,
            "category_hint": self.category_hint,
        }


class BaseScraper(ABC):
    """
    Abstract base class for bank scrapers.
    
    Provides common functionality:
    - Browser lifecycle management
    - Session persistence (storage state)
    - Screenshot on error
    - Logging
    - Transaction export
    """
    
    # Override in subclasses
    BANK_NAME: str = "base"
    LOGIN_URL: str = ""
    
    def __init__(self, headless: bool | None = None, interactive: bool = False) -> None:
        """
        Initialize the scraper.
        
        Args:
            headless: Run browser in headless mode. Defaults to config value.
            interactive: If True, wait for user input during OTP.
        """
        self.headless = headless if headless is not None else config.settings.headless
        self.interactive = interactive
        
        self.playwright: Playwright | None = None
        self.browser: Browser | None = None
        self.context: BrowserContext | None = None
        self.page: Page | None = None
        
        self.transactions: list[Transaction] = []
        
        # Paths
        self.storage_path = config.settings.storage_dir / f"{self.BANK_NAME}_state.json"
        self.output_path = config.settings.output_dir / f"{self.BANK_NAME}_transactions.json"
    
    def __enter__(self) -> "BaseScraper":
        """Context manager entry - start browser."""
        self.start()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        """Context manager exit - close browser."""
        if exc_type is not None:
            self._screenshot_error(f"error_{datetime.now().strftime('%Y%m%d_%H%M%S')}")
        self.stop()
    
    def start(self) -> None:
        """Start Playwright and browser."""
        logger.info(f"Starting {self.BANK_NAME} scraper...")
        
        self.playwright = sync_playwright().start()
        self.browser = self.playwright.chromium.launch(
            headless=self.headless,
            args=[
                "--disable-blink-features=AutomationControlled",
                "--no-sandbox",
            ]
        )
        
        # Try to load existing session
        if self.storage_path.exists():
            logger.info("Loading existing session...")
            self.context = self.browser.new_context(
                storage_state=str(self.storage_path),
                viewport={"width": 1280, "height": 720},
                user_agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            )
        else:
            logger.info("Creating new session...")
            self.context = self.browser.new_context(
                viewport={"width": 1280, "height": 720},
                user_agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            )
        
        self.page = self.context.new_page()
        self.page.set_default_timeout(config.settings.page_timeout)
    
    def stop(self) -> None:
        """Stop browser and cleanup."""
        logger.info(f"Stopping {self.BANK_NAME} scraper...")
        
        if self.context:
            # Save session state
            try:
                self.context.storage_state(path=str(self.storage_path))
                logger.info("Session state saved.")
            except Exception as e:
                logger.warning(f"Could not save session state: {e}")
            
            self.context.close()
        
        if self.browser:
            self.browser.close()
        
        if self.playwright:
            self.playwright.stop()
    
    def _screenshot_error(self, name: str) -> None:
        """Take screenshot on error."""
        if config.settings.screenshot_on_error and self.page:
            path = config.settings.log_dir / f"{self.BANK_NAME}_{name}.png"
            self.page.screenshot(path=str(path))
            logger.info(f"Screenshot saved: {path}")
    
    def _wait_for_otp(self, timeout_seconds: int = 120) -> None:
        """
        Wait for user to enter OTP in interactive mode.
        
        Args:
            timeout_seconds: Maximum time to wait for OTP entry.
        """
        if not self.interactive:
            logger.warning("OTP required but not in interactive mode!")
            raise RuntimeError("OTP required. Run with --interactive flag.")
        
        logger.info("=" * 50)
        logger.info("OTP REQUIRED - Please enter the code in the browser")
        logger.info(f"Waiting up to {timeout_seconds} seconds...")
        logger.info("=" * 50)
        
        # Wait for navigation after OTP (user clicks continue)
        try:
            self.page.wait_for_url(
                lambda url: "login" not in url.lower() and "otp" not in url.lower(),
                timeout=timeout_seconds * 1000
            )
            logger.info("OTP verified successfully!")
        except Exception as e:
            logger.error(f"OTP timeout or error: {e}")
            raise
    
    @abstractmethod
    def login(self) -> bool:
        """
        Perform login to the bank website.
        
        Returns:
            True if login successful, False otherwise.
        """
        pass
    
    @abstractmethod
    def fetch_transactions(self, days: int = 30) -> list[Transaction]:
        """
        Fetch transactions from the bank.
        
        Args:
            days: Number of days to fetch transactions for.
            
        Returns:
            List of Transaction objects.
        """
        pass
    
    def is_logged_in(self) -> bool:
        """
        Check if currently logged in.
        Override in subclasses with bank-specific logic.
        """
        return False
    
    def run(self, days: int = 30) -> list[Transaction]:
        """
        Main execution flow: login and fetch transactions.
        
        Args:
            days: Number of days to fetch transactions for.
            
        Returns:
            List of Transaction objects.
        """
        with self:
            # Check if already logged in from saved session
            if not self.is_logged_in():
                logger.info("Not logged in, performing login...")
                if not self.login():
                    raise RuntimeError("Login failed")
            else:
                logger.info("Already logged in from saved session")
            
            # Fetch transactions
            self.transactions = self.fetch_transactions(days)
            logger.info(f"Fetched {len(self.transactions)} transactions")
            
            # Export to JSON
            self.export_json()
            
            return self.transactions
    
    def export_json(self) -> Path:
        """
        Export transactions to JSON file.
        
        Returns:
            Path to the exported file.
        """
        data = {
            "bank": self.BANK_NAME,
            "extracted_at": datetime.now().isoformat(),
            "transaction_count": len(self.transactions),
            "transactions": [t.to_dict() for t in self.transactions],
        }
        
        with open(self.output_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        logger.info(f"Exported to: {self.output_path}")
        return self.output_path
    
    @staticmethod
    def parse_colombian_amount(amount_str: str) -> float:
        """
        Parse Colombian currency format to float.
        
        Examples:
            "$1.234.567" -> 1234567.0
            "- $50.000" -> -50000.0
            "$1.234,56" -> 1234.56
        """
        # Remove currency symbol and whitespace
        cleaned = amount_str.replace("$", "").replace(" ", "").strip()
        
        # Check for negative
        is_negative = "-" in cleaned
        cleaned = cleaned.replace("-", "")
        
        # Handle Colombian format (dots as thousands, comma as decimal)
        if "," in cleaned:
            # Has decimal separator
            parts = cleaned.split(",")
            integer_part = parts[0].replace(".", "")
            decimal_part = parts[1] if len(parts) > 1 else "0"
            value = float(f"{integer_part}.{decimal_part}")
        else:
            # No decimal, dots are thousands separators
            value = float(cleaned.replace(".", ""))
        
        return -value if is_negative else value
