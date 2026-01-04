"""
Davivienda bank scraper.
Extracts transactions from Davivienda web portal.

NOTE: Davivienda uses OTP/token authentication. First run requires --interactive mode.
"""

import re
from datetime import datetime, timedelta

from loguru import logger

from config import config, BANK_URLS
from .base_scraper import BaseScraper, Transaction


class DaviviendaScraper(BaseScraper):
    """
    Scraper for Davivienda bank.
    
    Login flow:
    1. Select document type
    2. Enter document number (user)
    3. Enter password
    4. Handle security questions or OTP
    5. Navigate to account movements
    """
    
    BANK_NAME = "davivienda"
    LOGIN_URL = BANK_URLS["davivienda"]["login"]
    
    def __init__(self, **kwargs) -> None:
        super().__init__(**kwargs)
        self.user = config.davivienda.user
        self.password = config.davivienda.password
        self.document_type = config.davivienda.document_type
        
        if not self.user or not self.password:
            raise ValueError("Davivienda credentials not configured. Check .env file.")
    
    def is_logged_in(self) -> bool:
        """Check if session is still valid."""
        try:
            self.page.goto(BANK_URLS["davivienda"]["home"], timeout=15000)
            self.page.wait_for_load_state("networkidle")
            # Check if we're on the authenticated home page
            return "ingresar" not in self.page.url.lower() and "login" not in self.page.url.lower()
        except Exception:
            return False
    
    def login(self) -> bool:
        """
        Perform login to Davivienda.
        
        Returns:
            True if login successful.
        """
        logger.info("Navigating to Davivienda login...")
        self.page.goto(self.LOGIN_URL)
        
        try:
            self.page.wait_for_load_state("networkidle")
            
            # Step 1: Select document type
            logger.info(f"Selecting document type: {self.document_type}")
            doc_type_select = self.page.locator('select[name*="tipo"], select[id*="tipo"], select[class*="documento"]')
            
            if doc_type_select.count() > 0:
                doc_type_select.first.select_option(value=self.document_type)
            else:
                # Try radio buttons or dropdown
                doc_type_btn = self.page.locator(f'input[value="{self.document_type}"], label:has-text("{self.document_type}")')
                if doc_type_btn.count() > 0:
                    doc_type_btn.first.click()
            
            # Step 2: Enter document number
            logger.info("Entering document number...")
            user_input = self.page.locator('input[name*="usuario"], input[name*="documento"], input[id*="usuario"], input[type="text"]:visible')
            user_input.first.wait_for(state="visible", timeout=10000)
            user_input.first.fill(self.user)
            
            # Click continue if there's a step
            continue_btn = self.page.locator('button:has-text("Continuar"), input[type="submit"][value*="Continuar"]')
            if continue_btn.count() > 0:
                continue_btn.first.click()
                self.page.wait_for_load_state("networkidle")
            
            # Step 3: Enter password
            logger.info("Entering password...")
            password_input = self.page.locator('input[type="password"]')
            password_input.first.wait_for(state="visible", timeout=10000)
            password_input.first.fill(self.password)
            
            # Click login button
            login_btn = self.page.locator('button:has-text("Ingresar"), input[type="submit"][value*="Ingresar"], button[type="submit"]')
            login_btn.first.click()
            
            # Step 4: Handle security verification
            logger.info("Checking for security verification...")
            self.page.wait_for_load_state("networkidle")
            self.page.wait_for_timeout(2000)  # Give time for OTP/security screen
            
            # Check for OTP screen
            otp_indicators = [
                'input[name*="otp"]',
                'input[name*="codigo"]',
                'input[maxlength="6"]',
                'text="código de verificación"',
                'text="token"',
            ]
            
            for indicator in otp_indicators:
                if self.page.locator(indicator).count() > 0:
                    logger.info("OTP/Token required!")
                    self._wait_for_otp(timeout_seconds=180)
                    break
            
            # Check for security questions
            security_question = self.page.locator('text="pregunta de seguridad", text="imagen de seguridad"')
            if security_question.count() > 0:
                logger.info("Security question detected - requires manual intervention")
                self._wait_for_otp(timeout_seconds=120)
            
            # Verify login success
            self.page.wait_for_timeout(3000)
            
            # Check if we're logged in
            if "home" in self.page.url.lower() or "inicio" in self.page.url.lower():
                logger.info("Login successful!")
                return True
            
            # Check for error messages
            error = self.page.locator('[class*="error"], [class*="alert-danger"], text="incorrecto"')
            if error.count() > 0:
                error_text = error.first.text_content()
                logger.error(f"Login error: {error_text}")
                return False
            
            # Assume success if no errors
            logger.info("Login appears successful")
            return True
            
        except Exception as e:
            logger.error(f"Login failed: {e}")
            self._screenshot_error("login_failed")
            return False
    
    def fetch_transactions(self, days: int = 30) -> list[Transaction]:
        """
        Fetch transactions from Davivienda.
        
        Args:
            days: Number of days to fetch.
            
        Returns:
            List of Transaction objects.
        """
        logger.info(f"Fetching transactions for last {days} days...")
        transactions = []
        
        try:
            # Navigate to movements/consultas
            logger.info("Navigating to account movements...")
            
            # Try direct URL first
            self.page.goto(BANK_URLS["davivienda"]["movements"])
            self.page.wait_for_load_state("networkidle")
            
            # If direct URL doesn't work, navigate through menu
            if "movimientos" not in self.page.url.lower() and "consultas" not in self.page.url.lower():
                # Click on accounts/consultas menu
                menu_items = [
                    'text="Mis productos"',
                    'text="Consultas"',
                    'text="Cuentas"',
                    'a:has-text("Movimientos")',
                ]
                
                for menu in menu_items:
                    menu_elem = self.page.locator(menu)
                    if menu_elem.count() > 0:
                        menu_elem.first.click()
                        self.page.wait_for_load_state("networkidle")
                        break
            
            # Select account if multiple accounts
            account_selector = self.page.locator('select[name*="cuenta"], [class*="account-selector"]')
            if account_selector.count() > 0:
                # Select first account (or could be configurable)
                logger.info("Selecting account...")
                account_selector.first.select_option(index=0)
                self.page.wait_for_load_state("networkidle")
            
            # Set date range if filter available
            self._set_date_filter(days)
            
            # Wait for transaction table/list
            tx_table = self.page.locator('table[class*="movimiento"], table[class*="transaction"], [class*="lista-movimientos"]')
            tx_table.first.wait_for(state="visible", timeout=15000)
            
            # Get transaction rows
            tx_rows = self.page.locator('table tbody tr, [class*="movement-row"], [class*="transaction-item"]')
            count = tx_rows.count()
            logger.info(f"Found {count} transaction rows")
            
            # Calculate date threshold
            date_threshold = datetime.now() - timedelta(days=days)
            
            for i in range(count):
                try:
                    row = tx_rows.nth(i)
                    tx = self._parse_transaction_row(row, i)
                    
                    if tx:
                        tx_date = datetime.strptime(tx.date, "%Y-%m-%d")
                        if tx_date >= date_threshold:
                            transactions.append(tx)
                            
                except Exception as e:
                    logger.warning(f"Error parsing row {i}: {e}")
                    continue
            
            # Handle pagination
            transactions.extend(self._handle_pagination(date_threshold))
            
        except Exception as e:
            logger.error(f"Error fetching transactions: {e}")
            self._screenshot_error("fetch_failed")
        
        return transactions
    
    def _set_date_filter(self, days: int) -> None:
        """Set date filter if available."""
        try:
            # Look for date inputs
            date_from = self.page.locator('input[name*="desde"], input[name*="from"], input[id*="fechaInicio"]')
            date_to = self.page.locator('input[name*="hasta"], input[name*="to"], input[id*="fechaFin"]')
            
            if date_from.count() > 0 and date_to.count() > 0:
                from_date = (datetime.now() - timedelta(days=days)).strftime("%d/%m/%Y")
                to_date = datetime.now().strftime("%d/%m/%Y")
                
                logger.info(f"Setting date filter: {from_date} - {to_date}")
                
                date_from.first.fill(from_date)
                date_to.first.fill(to_date)
                
                # Click search/filter button
                filter_btn = self.page.locator('button:has-text("Consultar"), button:has-text("Buscar"), input[type="submit"]')
                if filter_btn.count() > 0:
                    filter_btn.first.click()
                    self.page.wait_for_load_state("networkidle")
                    
        except Exception as e:
            logger.debug(f"Could not set date filter: {e}")
    
    def _parse_transaction_row(self, row, index: int) -> Transaction | None:
        """
        Parse a transaction table row.
        
        Davivienda typically shows:
        | Fecha | Descripción | Oficina | Débito | Crédito | Saldo |
        """
        try:
            cells = row.locator('td')
            cell_count = cells.count()
            
            if cell_count < 3:
                return None
            
            # Extract cell contents
            cell_texts = []
            for i in range(cell_count):
                text = cells.nth(i).text_content() or ""
                cell_texts.append(text.strip())
            
            # Parse based on common Davivienda format
            # Column indices may vary
            date_str = cell_texts[0] if cell_count > 0 else ""
            description = cell_texts[1] if cell_count > 1 else ""
            
            # Find debit/credit columns
            debit = ""
            credit = ""
            balance = ""
            
            for i, text in enumerate(cell_texts[2:], start=2):
                if self._looks_like_amount(text):
                    if not debit:
                        debit = text
                    elif not credit:
                        credit = text
                    else:
                        balance = text
            
            # Determine amount and type
            if debit and self._looks_like_amount(debit):
                amount = -abs(self.parse_colombian_amount(debit))
                tx_type = "expense"
            elif credit and self._looks_like_amount(credit):
                amount = abs(self.parse_colombian_amount(credit))
                tx_type = "income"
            else:
                return None
            
            # Parse date
            parsed_date = self._parse_date(date_str)
            
            # Parse balance if available
            balance_after = self.parse_colombian_amount(balance) if balance and self._looks_like_amount(balance) else None
            
            # Generate ID
            tx_id = f"DAVI_{parsed_date}_{index}_{abs(hash(description)) % 10000}"
            
            return Transaction(
                id=tx_id,
                date=parsed_date,
                description=description,
                amount=amount,
                type=tx_type,
                balance_after=balance_after,
                raw_data={"cells": cell_texts},
            )
            
        except Exception as e:
            logger.debug(f"Could not parse row: {e}")
            return None
    
    def _looks_like_amount(self, text: str) -> bool:
        """Check if text looks like a currency amount."""
        if not text:
            return False
        # Contains digits and possibly $ . ,
        cleaned = text.replace("$", "").replace(".", "").replace(",", "").replace(" ", "").replace("-", "")
        return cleaned.isdigit() and len(cleaned) > 0
    
    def _parse_date(self, date_str: str) -> str:
        """Parse Davivienda date formats to YYYY-MM-DD."""
        date_str = date_str.strip()
        
        # Common formats in Davivienda
        formats = [
            "%d/%m/%Y",
            "%d-%m-%Y",
            "%Y-%m-%d",
            "%d %b %Y",
            "%d/%m/%y",
        ]
        
        for fmt in formats:
            try:
                dt = datetime.strptime(date_str, fmt)
                return dt.strftime("%Y-%m-%d")
            except ValueError:
                continue
        
        # Try to extract numbers
        numbers = re.findall(r'\d+', date_str)
        if len(numbers) >= 3:
            day, month, year = int(numbers[0]), int(numbers[1]), int(numbers[2])
            if year < 100:
                year += 2000
            return f"{year:04d}-{month:02d}-{day:02d}"
        
        logger.warning(f"Could not parse date: {date_str}")
        return datetime.now().strftime("%Y-%m-%d")
    
    def _handle_pagination(self, date_threshold: datetime) -> list[Transaction]:
        """Handle pagination to get more transactions."""
        additional = []
        
        try:
            # Look for pagination controls
            next_page = self.page.locator('a:has-text("Siguiente"), button:has-text("Siguiente"), [class*="next"]')
            
            max_pages = 10
            page_num = 1
            
            while next_page.count() > 0 and next_page.first.is_enabled() and page_num < max_pages:
                logger.info(f"Loading page {page_num + 1}...")
                next_page.first.click()
                self.page.wait_for_load_state("networkidle")
                self.page.wait_for_timeout(1000)
                
                # Parse new rows
                tx_rows = self.page.locator('table tbody tr')
                for i in range(tx_rows.count()):
                    tx = self._parse_transaction_row(tx_rows.nth(i), i + page_num * 100)
                    if tx:
                        tx_date = datetime.strptime(tx.date, "%Y-%m-%d")
                        if tx_date >= date_threshold:
                            additional.append(tx)
                        else:
                            return additional  # Stop if we've gone too far back
                
                page_num += 1
                next_page = self.page.locator('a:has-text("Siguiente"), button:has-text("Siguiente"), [class*="next"]')
                
        except Exception as e:
            logger.debug(f"Pagination ended: {e}")
        
        return additional
