"""
Nequi bank scraper for extracting transactions.
Nequi is a digital wallet by Bancolombia.
"""

import re
from datetime import datetime, timedelta

from loguru import logger

from config import config, BANK_URLS
from .base_scraper import BaseScraper, Transaction


class NequiScraper(BaseScraper):
    """
    Scraper for Nequi digital wallet.
    
    Login flow:
    1. Enter phone number
    2. Enter password
    3. OTP verification (SMS or push notification)
    
    Note: OTP requires manual intervention in interactive mode.
    """
    
    BANK_NAME = "nequi"
    LOGIN_URL = BANK_URLS["nequi"]["login"]
    
    def __init__(self, **kwargs) -> None:
        super().__init__(**kwargs)
        self.phone = config.nequi.phone
        self.password = config.nequi.password
        
        if not self.phone or not self.password:
            raise ValueError("Nequi credentials not configured. Check .env file.")
    
    def is_logged_in(self) -> bool:
        """Check if currently logged in to Nequi."""
        try:
            self.page.goto(BANK_URLS["nequi"]["home"], timeout=10000)
            # If we can access home without redirect to login, we're logged in
            return "home" in self.page.url.lower() or "dashboard" in self.page.url.lower()
        except Exception:
            return False
    
    def login(self) -> bool:
        """
        Perform login to Nequi.
        
        Returns:
            True if login successful, False otherwise.
        """
        logger.info("Navigating to Nequi login...")
        self.page.goto(self.LOGIN_URL)
        
        try:
            # Wait for login form to load
            self.page.wait_for_load_state("networkidle")
            
            # Step 1: Enter phone number
            logger.info("Entering phone number...")
            phone_input = self.page.locator('input[type="tel"], input[name*="phone"], input[placeholder*="celular"]').first
            phone_input.wait_for(state="visible", timeout=config.settings.element_timeout)
            phone_input.fill(self.phone)
            
            # Click continue/next button
            continue_btn = self.page.locator('button:has-text("Continuar"), button:has-text("Siguiente"), button[type="submit"]').first
            continue_btn.click()
            
            # Wait for password field
            self.page.wait_for_timeout(2000)
            
            # Step 2: Enter password
            logger.info("Entering password...")
            password_input = self.page.locator('input[type="password"]').first
            password_input.wait_for(state="visible", timeout=config.settings.element_timeout)
            password_input.fill(self.password)
            
            # Click login button
            login_btn = self.page.locator('button:has-text("Ingresar"), button:has-text("Iniciar"), button[type="submit"]').first
            login_btn.click()
            
            # Step 3: Handle OTP
            self.page.wait_for_timeout(3000)
            
            # Check if OTP is required
            otp_indicators = [
                'input[name*="otp"]',
                'input[name*="code"]',
                'text=código',
                'text=verificación',
                'text=SMS',
            ]
            
            for indicator in otp_indicators:
                if self.page.locator(indicator).count() > 0:
                    logger.info("OTP verification required")
                    self._wait_for_otp()
                    break
            
            # Verify login success
            self.page.wait_for_timeout(3000)
            
            if self.is_logged_in():
                logger.info("Login successful!")
                return True
            else:
                logger.error("Login failed - not redirected to home")
                self._screenshot_error("login_failed")
                return False
                
        except Exception as e:
            logger.error(f"Login error: {e}")
            self._screenshot_error("login_error")
            return False
    
    def fetch_transactions(self, days: int = 30) -> list[Transaction]:
        """
        Fetch transactions from Nequi.
        
        Args:
            days: Number of days to fetch transactions for.
            
        Returns:
            List of Transaction objects.
        """
        logger.info(f"Fetching transactions for last {days} days...")
        transactions = []
        
        try:
            # Navigate to movements/transactions page
            self.page.goto(BANK_URLS["nequi"]["movements"])
            self.page.wait_for_load_state("networkidle")
            
            # Wait for transactions to load
            self.page.wait_for_timeout(3000)
            
            # Try to find transaction list container
            # Nequi uses various selectors, try common patterns
            transaction_selectors = [
                '[data-testid*="transaction"]',
                '[class*="transaction"]',
                '[class*="movement"]',
                '[class*="activity"]',
                '.transaction-item',
                '.movement-item',
                'li[class*="item"]',
            ]
            
            transactions_container = None
            for selector in transaction_selectors:
                if self.page.locator(selector).count() > 0:
                    transactions_container = self.page.locator(selector)
                    break
            
            if not transactions_container:
                logger.warning("Could not find transactions container. Taking screenshot for debug.")
                self._screenshot_error("no_transactions_container")
                return []
            
            # Calculate date threshold
            date_threshold = datetime.now() - timedelta(days=days)
            
            # Iterate through transactions
            count = transactions_container.count()
            logger.info(f"Found {count} transaction elements")
            
            for i in range(count):
                try:
                    item = transactions_container.nth(i)
                    txn = self._parse_transaction_element(item, i)
                    
                    if txn:
                        # Check if within date range
                        txn_date = datetime.strptime(txn.date, "%Y-%m-%d")
                        if txn_date >= date_threshold:
                            transactions.append(txn)
                        else:
                            # Transactions are usually sorted by date desc
                            # If we hit an old one, we can stop
                            logger.info(f"Reached transactions older than {days} days")
                            break
                            
                except Exception as e:
                    logger.warning(f"Error parsing transaction {i}: {e}")
                    continue
            
            # Try to load more if pagination exists
            self._load_more_transactions(days, transactions, date_threshold)
            
        except Exception as e:
            logger.error(f"Error fetching transactions: {e}")
            self._screenshot_error("fetch_error")
        
        return transactions
    
    def _parse_transaction_element(self, element, index: int) -> Transaction | None:
        """
        Parse a single transaction element from the page.
        
        Args:
            element: Playwright Locator for the transaction element.
            index: Index for generating unique ID.
            
        Returns:
            Transaction object or None if parsing fails.
        """
        try:
            # Get all text content
            text_content = element.text_content() or ""
            
            # Try to extract date
            date_patterns = [
                r'(\d{1,2})\s+(?:de\s+)?(\w+)(?:\s+(?:de\s+)?(\d{4}))?',  # "15 de enero 2026"
                r'(\d{1,2})/(\d{1,2})/(\d{4})',  # "15/01/2026"
                r'(\d{4})-(\d{2})-(\d{2})',  # "2026-01-15"
            ]
            
            date_str = None
            for pattern in date_patterns:
                match = re.search(pattern, text_content, re.IGNORECASE)
                if match:
                    date_str = self._normalize_date(match.group(0))
                    break
            
            if not date_str:
                date_str = datetime.now().strftime("%Y-%m-%d")
            
            # Try to extract amount
            amount_pattern = r'[\$]?\s*[\d.,]+(?:\s*(?:COP)?)?'
            amounts = re.findall(amount_pattern, text_content)
            
            amount = 0.0
            if amounts:
                # Usually the first or largest amount is the transaction amount
                for amt in amounts:
                    try:
                        parsed = self.parse_colombian_amount(amt)
                        if abs(parsed) > abs(amount):
                            amount = parsed
                    except ValueError:
                        continue
            
            # Determine transaction type
            is_expense = any(word in text_content.lower() for word in [
                'pago', 'compra', 'retiro', 'transferencia enviada', 
                'débito', 'cargo', '-'
            ])
            txn_type = "expense" if is_expense else "income"
            
            # Make amount negative for expenses
            if txn_type == "expense" and amount > 0:
                amount = -amount
            
            # Extract description (remove amounts and dates)
            description = text_content
            for amt in amounts:
                description = description.replace(amt, "")
            description = re.sub(r'\d{1,2}/\d{1,2}/\d{4}', '', description)
            description = re.sub(r'\s+', ' ', description).strip()[:100]
            
            # Generate unique ID
            txn_id = f"NEQUI_{datetime.now().strftime('%Y%m%d')}_{index:04d}"
            
            return Transaction(
                id=txn_id,
                date=date_str,
                description=description,
                amount=amount,
                type=txn_type,
                raw_data={"original_text": text_content[:500]},
            )
            
        except Exception as e:
            logger.debug(f"Failed to parse transaction element: {e}")
            return None
    
    def _normalize_date(self, date_str: str) -> str:
        """
        Normalize various date formats to YYYY-MM-DD.
        
        Args:
            date_str: Date string in various formats.
            
        Returns:
            Date in YYYY-MM-DD format.
        """
        months_es = {
            'enero': 1, 'febrero': 2, 'marzo': 3, 'abril': 4,
            'mayo': 5, 'junio': 6, 'julio': 7, 'agosto': 8,
            'septiembre': 9, 'octubre': 10, 'noviembre': 11, 'diciembre': 12,
            'ene': 1, 'feb': 2, 'mar': 3, 'abr': 4, 'may': 5, 'jun': 6,
            'jul': 7, 'ago': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dic': 12,
        }
        
        try:
            # Try ISO format first
            if re.match(r'\d{4}-\d{2}-\d{2}', date_str):
                return date_str[:10]
            
            # Try DD/MM/YYYY
            match = re.match(r'(\d{1,2})/(\d{1,2})/(\d{4})', date_str)
            if match:
                return f"{match.group(3)}-{match.group(2):0>2}-{match.group(1):0>2}"
            
            # Try Spanish format "15 de enero 2026"
            match = re.match(r'(\d{1,2})\s+(?:de\s+)?(\w+)(?:\s+(?:de\s+)?(\d{4}))?', date_str, re.IGNORECASE)
            if match:
                day = int(match.group(1))
                month_str = match.group(2).lower()
                year = int(match.group(3)) if match.group(3) else datetime.now().year
                month = months_es.get(month_str, 1)
                return f"{year}-{month:02d}-{day:02d}"
            
        except Exception:
            pass
        
        # Fallback to today
        return datetime.now().strftime("%Y-%m-%d")
    
    def _load_more_transactions(
        self, 
        days: int, 
        transactions: list[Transaction], 
        date_threshold: datetime
    ) -> None:
        """
        Try to load more transactions if pagination exists.
        
        Args:
            days: Number of days to fetch.
            transactions: List to append transactions to.
            date_threshold: Minimum date to fetch.
        """
        max_pages = 10  # Safety limit
        current_page = 1
        
        while current_page < max_pages:
            # Look for "load more" or pagination buttons
            load_more = self.page.locator(
                'button:has-text("cargar más"), '
                'button:has-text("ver más"), '
                'button:has-text("mostrar más"), '
                '[class*="load-more"], '
                '[class*="pagination"] button:last-child'
            ).first
            
            if load_more.count() == 0 or not load_more.is_visible():
                break
            
            try:
                load_more.click()
                self.page.wait_for_timeout(2000)
                current_page += 1
                logger.info(f"Loaded page {current_page}")
            except Exception:
                break
