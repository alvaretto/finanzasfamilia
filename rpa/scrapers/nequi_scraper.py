"""
Nequi bank scraper.
Extracts transactions from Nequi web portal.

NOTE: Nequi uses OTP authentication. First run requires --interactive mode.
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
    3. Enter OTP (sent to phone/email)
    4. Navigate to movements
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
        """Check if session is still valid."""
        try:
            self.page.goto(BANK_URLS["nequi"]["home"], timeout=15000)
            # If redirected to login, we're not logged in
            return "login" not in self.page.url.lower()
        except Exception:
            return False
    
    def login(self) -> bool:
        """
        Perform login to Nequi.
        
        Returns:
            True if login successful.
        """
        logger.info("Navigating to Nequi login...")
        self.page.goto(self.LOGIN_URL)
        
        try:
            # Wait for page to load
            self.page.wait_for_load_state("networkidle")
            
            # Step 1: Enter phone number
            logger.info("Entering phone number...")
            phone_input = self.page.locator('input[type="tel"], input[name*="phone"], input[placeholder*="celular"]')
            phone_input.wait_for(state="visible", timeout=10000)
            phone_input.fill(self.phone)
            
            # Click continue/next button
            continue_btn = self.page.locator('button:has-text("Continuar"), button:has-text("Siguiente")')
            continue_btn.click()
            
            # Step 2: Enter password
            logger.info("Entering password...")
            self.page.wait_for_load_state("networkidle")
            
            password_input = self.page.locator('input[type="password"]')
            password_input.wait_for(state="visible", timeout=10000)
            password_input.fill(self.password)
            
            # Click login button
            login_btn = self.page.locator('button:has-text("Ingresar"), button:has-text("Iniciar")')
            login_btn.click()
            
            # Step 3: Handle OTP
            logger.info("Checking for OTP screen...")
            self.page.wait_for_load_state("networkidle")
            
            # Check if OTP is required
            otp_input = self.page.locator('input[name*="otp"], input[name*="code"], input[maxlength="6"]')
            if otp_input.count() > 0:
                logger.info("OTP required!")
                self._wait_for_otp(timeout_seconds=180)
            
            # Verify login success
            self.page.wait_for_url(lambda url: "home" in url.lower(), timeout=30000)
            logger.info("Login successful!")
            
            return True
            
        except Exception as e:
            logger.error(f"Login failed: {e}")
            self._screenshot_error("login_failed")
            return False
    
    def fetch_transactions(self, days: int = 30) -> list[Transaction]:
        """
        Fetch transactions from Nequi.
        
        Args:
            days: Number of days to fetch.
            
        Returns:
            List of Transaction objects.
        """
        logger.info(f"Fetching transactions for last {days} days...")
        transactions = []
        
        try:
            # Navigate to movements/history
            logger.info("Navigating to movements...")
            self.page.goto(BANK_URLS["nequi"]["movements"])
            self.page.wait_for_load_state("networkidle")
            
            # Wait for transaction list to load
            # Nequi typically shows transactions in a list or cards
            tx_container = self.page.locator('[class*="transaction"], [class*="movement"], [class*="historial"]')
            tx_container.first.wait_for(state="visible", timeout=15000)
            
            # Get all transaction elements
            tx_items = self.page.locator('[class*="transaction-item"], [class*="movement-item"], li[class*="item"]')
            count = tx_items.count()
            logger.info(f"Found {count} transaction elements")
            
            # Calculate date threshold
            date_threshold = datetime.now() - timedelta(days=days)
            
            for i in range(count):
                try:
                    item = tx_items.nth(i)
                    tx = self._parse_transaction_element(item, i)
                    
                    if tx:
                        # Check if within date range
                        tx_date = datetime.strptime(tx.date, "%Y-%m-%d")
                        if tx_date >= date_threshold:
                            transactions.append(tx)
                        else:
                            # Transactions are usually sorted by date desc
                            # So we can stop when we hit older ones
                            logger.info(f"Reached transactions older than {days} days, stopping...")
                            break
                            
                except Exception as e:
                    logger.warning(f"Error parsing transaction {i}: {e}")
                    continue
            
            # Try to load more if pagination exists
            transactions.extend(self._load_more_transactions(date_threshold))
            
        except Exception as e:
            logger.error(f"Error fetching transactions: {e}")
            self._screenshot_error("fetch_failed")
        
        return transactions
    
    def _parse_transaction_element(self, element, index: int) -> Transaction | None:
        """
        Parse a single transaction element from the page.
        
        Args:
            element: Playwright locator for the transaction element.
            index: Index for generating unique ID.
            
        Returns:
            Transaction object or None if parsing fails.
        """
        try:
            # Extract text content
            text = element.text_content() or ""
            
            # Try to find specific elements within
            # Date (various formats)
            date_elem = element.locator('[class*="date"], [class*="fecha"], time')
            date_str = date_elem.first.text_content() if date_elem.count() > 0 else ""
            
            # Description
            desc_elem = element.locator('[class*="description"], [class*="descripcion"], [class*="title"], [class*="nombre"]')
            description = desc_elem.first.text_content() if desc_elem.count() > 0 else text[:100]
            
            # Amount
            amount_elem = element.locator('[class*="amount"], [class*="monto"], [class*="valor"]')
            amount_str = amount_elem.first.text_content() if amount_elem.count() > 0 else ""
            
            # Parse amount
            amount = self.parse_colombian_amount(amount_str) if amount_str else 0.0
            
            # Determine transaction type
            tx_type = "expense" if amount < 0 else "income"
            
            # Parse date
            parsed_date = self._parse_date(date_str)
            
            # Generate unique ID
            tx_id = f"NEQUI_{parsed_date}_{index}_{abs(hash(description)) % 10000}"
            
            return Transaction(
                id=tx_id,
                date=parsed_date,
                description=description.strip(),
                amount=amount,
                type=tx_type,
                raw_data={"original_text": text},
            )
            
        except Exception as e:
            logger.debug(f"Could not parse transaction element: {e}")
            return None
    
    def _parse_date(self, date_str: str) -> str:
        """
        Parse various date formats to YYYY-MM-DD.
        
        Nequi may show dates like:
        - "Hoy"
        - "Ayer"
        - "15 de enero"
        - "15/01/2026"
        - "2026-01-15"
        """
        date_str = date_str.strip().lower()
        today = datetime.now()
        
        if "hoy" in date_str:
            return today.strftime("%Y-%m-%d")
        
        if "ayer" in date_str:
            return (today - timedelta(days=1)).strftime("%Y-%m-%d")
        
        # Try common formats
        formats = [
            "%d/%m/%Y",
            "%Y-%m-%d",
            "%d-%m-%Y",
            "%d de %B",  # "15 de enero"
            "%d de %B de %Y",
        ]
        
        # Spanish month names
        months_es = {
            "enero": "01", "febrero": "02", "marzo": "03", "abril": "04",
            "mayo": "05", "junio": "06", "julio": "07", "agosto": "08",
            "septiembre": "09", "octubre": "10", "noviembre": "11", "diciembre": "12"
        }
        
        # Replace Spanish months with numbers
        for month_es, month_num in months_es.items():
            if month_es in date_str:
                date_str = date_str.replace(f"de {month_es}", f"/{month_num}")
                date_str = date_str.replace(month_es, month_num)
        
        # Try to extract day/month
        numbers = re.findall(r'\d+', date_str)
        if len(numbers) >= 2:
            day = int(numbers[0])
            month = int(numbers[1])
            year = int(numbers[2]) if len(numbers) > 2 else today.year
            return f"{year:04d}-{month:02d}-{day:02d}"
        
        # Default to today if parsing fails
        logger.warning(f"Could not parse date: {date_str}, using today")
        return today.strftime("%Y-%m-%d")
    
    def _load_more_transactions(self, date_threshold: datetime) -> list[Transaction]:
        """
        Handle pagination/infinite scroll to load more transactions.
        
        Returns:
            Additional transactions found.
        """
        additional = []
        
        try:
            # Look for "load more" button or pagination
            load_more = self.page.locator('button:has-text("Ver más"), button:has-text("Cargar más"), [class*="load-more"]')
            
            max_pages = 5  # Limit to avoid infinite loops
            page_count = 0
            
            while load_more.count() > 0 and page_count < max_pages:
                logger.info(f"Loading more transactions (page {page_count + 1})...")
                load_more.first.click()
                self.page.wait_for_load_state("networkidle")
                
                # Small delay for content to render
                self.page.wait_for_timeout(1000)
                
                page_count += 1
                
                # Check if button still exists
                load_more = self.page.locator('button:has-text("Ver más"), button:has-text("Cargar más"), [class*="load-more"]')
                
        except Exception as e:
            logger.debug(f"No more pages to load: {e}")
        
        return additional
