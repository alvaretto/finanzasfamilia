"""
Davivienda bank scraper for extracting transactions.
Davivienda is one of Colombia's largest traditional banks.
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
    2. Enter document number (user ID)
    3. Enter password
    4. OTP verification (token/SMS)
    
    Note: Davivienda has strong anti-bot measures.
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
        """Check if currently logged in to Davivienda."""
        try:
            self.page.goto(BANK_URLS["davivienda"]["home"], timeout=15000)
            self.page.wait_for_timeout(2000)
            
            # Check for logged-in indicators
            logged_in_indicators = [
                'text=Mis productos',
                'text=Bienvenido',
                'text=Cerrar sesión',
                '[class*="dashboard"]',
                '[class*="home-logged"]',
            ]
            
            for indicator in logged_in_indicators:
                if self.page.locator(indicator).count() > 0:
                    return True
            
            return False
        except Exception:
            return False
    
    def login(self) -> bool:
        """
        Perform login to Davivienda.
        
        Returns:
            True if login successful, False otherwise.
        """
        logger.info("Navigating to Davivienda login...")
        self.page.goto(self.LOGIN_URL)
        
        try:
            self.page.wait_for_load_state("networkidle")
            self.page.wait_for_timeout(3000)
            
            # Step 1: Select document type
            logger.info(f"Selecting document type: {self.document_type}")
            doc_type_selectors = [
                f'select option[value="{self.document_type}"]',
                f'[data-value="{self.document_type}"]',
                f'text={self._get_document_type_label()}',
            ]
            
            # Try to find and click document type selector
            doc_select = self.page.locator('select[name*="tipo"], select[id*="tipo"], [class*="document-type"]').first
            if doc_select.count() > 0:
                doc_select.select_option(self.document_type)
            else:
                # Try dropdown style selector
                dropdown_trigger = self.page.locator('[class*="dropdown"] button, [class*="select"] > div').first
                if dropdown_trigger.count() > 0:
                    dropdown_trigger.click()
                    self.page.wait_for_timeout(500)
                    self.page.locator(f'text={self._get_document_type_label()}').first.click()
            
            self.page.wait_for_timeout(1000)
            
            # Step 2: Enter document number
            logger.info("Entering document number...")
            user_input = self.page.locator(
                'input[name*="documento"], '
                'input[name*="usuario"], '
                'input[id*="documento"], '
                'input[id*="usuario"], '
                'input[placeholder*="documento"], '
                'input[type="text"]:not([readonly])'
            ).first
            
            user_input.wait_for(state="visible", timeout=config.settings.element_timeout)
            user_input.fill(self.user)
            
            # Step 3: Enter password
            logger.info("Entering password...")
            
            # Some banks show password on same page, others on next
            password_input = self.page.locator('input[type="password"]').first
            
            if password_input.count() == 0:
                # Click continue to go to password page
                continue_btn = self.page.locator(
                    'button:has-text("Continuar"), '
                    'button:has-text("Siguiente"), '
                    'button[type="submit"]'
                ).first
                continue_btn.click()
                self.page.wait_for_timeout(2000)
                password_input = self.page.locator('input[type="password"]').first
            
            password_input.wait_for(state="visible", timeout=config.settings.element_timeout)
            password_input.fill(self.password)
            
            # Click login button
            login_btn = self.page.locator(
                'button:has-text("Ingresar"), '
                'button:has-text("Iniciar sesión"), '
                'button:has-text("Entrar"), '
                'button[type="submit"]'
            ).first
            login_btn.click()
            
            # Wait for response
            self.page.wait_for_timeout(5000)
            
            # Step 4: Handle OTP/Token
            otp_indicators = [
                'input[name*="token"]',
                'input[name*="otp"]',
                'input[name*="clave"]',
                'text=token',
                'text=código de seguridad',
                'text=clave dinámica',
                '[class*="otp"]',
                '[class*="token"]',
            ]
            
            for indicator in otp_indicators:
                if self.page.locator(indicator).count() > 0:
                    logger.info("OTP/Token verification required")
                    self._wait_for_otp(timeout_seconds=180)  # Longer timeout for physical token
                    break
            
            # Verify login success
            self.page.wait_for_timeout(3000)
            
            if self.is_logged_in():
                logger.info("Login successful!")
                return True
            else:
                logger.error("Login failed - checking for error messages")
                self._check_login_errors()
                self._screenshot_error("login_failed")
                return False
                
        except Exception as e:
            logger.error(f"Login error: {e}")
            self._screenshot_error("login_error")
            return False
    
    def _get_document_type_label(self) -> str:
        """Get human-readable label for document type."""
        labels = {
            "CC": "Cédula de Ciudadanía",
            "CE": "Cédula de Extranjería",
            "TI": "Tarjeta de Identidad",
            "PA": "Pasaporte",
            "NIT": "NIT",
        }
        return labels.get(self.document_type, self.document_type)
    
    def _check_login_errors(self) -> None:
        """Check and log any login error messages."""
        error_selectors = [
            '[class*="error"]',
            '[class*="alert"]',
            '[role="alert"]',
            'text=incorrecto',
            'text=inválido',
            'text=bloqueado',
        ]
        
        for selector in error_selectors:
            errors = self.page.locator(selector)
            if errors.count() > 0:
                for i in range(errors.count()):
                    text = errors.nth(i).text_content()
                    if text:
                        logger.error(f"Login error message: {text.strip()}")
    
    def fetch_transactions(self, days: int = 30) -> list[Transaction]:
        """
        Fetch transactions from Davivienda.
        
        Args:
            days: Number of days to fetch transactions for.
            
        Returns:
            List of Transaction objects.
        """
        logger.info(f"Fetching transactions for last {days} days...")
        transactions = []
        
        try:
            # Navigate to movements page
            self._navigate_to_movements()
            
            # Set date range filter if available
            self._set_date_filter(days)
            
            # Wait for transactions to load
            self.page.wait_for_timeout(3000)
            
            # Find and iterate through products (accounts/cards)
            products = self._get_products()
            
            for product in products:
                logger.info(f"Fetching transactions for: {product['name']}")
                product_txns = self._fetch_product_transactions(product, days)
                transactions.extend(product_txns)
            
        except Exception as e:
            logger.error(f"Error fetching transactions: {e}")
            self._screenshot_error("fetch_error")
        
        return transactions
    
    def _navigate_to_movements(self) -> None:
        """Navigate to the movements/transactions page."""
        # Try direct URL first
        try:
            self.page.goto(BANK_URLS["davivienda"]["movements"])
            self.page.wait_for_load_state("networkidle")
            return
        except Exception:
            pass
        
        # Try navigation through menu
        menu_items = [
            'text=Consultas',
            'text=Movimientos',
            'text=Extractos',
            'text=Mis productos',
        ]
        
        for item in menu_items:
            try:
                link = self.page.locator(item).first
                if link.count() > 0 and link.is_visible():
                    link.click()
                    self.page.wait_for_timeout(2000)
                    break
            except Exception:
                continue
    
    def _set_date_filter(self, days: int) -> None:
        """Set date range filter for transactions."""
        try:
            # Calculate dates
            end_date = datetime.now()
            start_date = end_date - timedelta(days=days)
            
            # Look for date filter inputs
            date_from = self.page.locator(
                'input[name*="desde"], '
                'input[name*="inicio"], '
                'input[id*="from"], '
                'input[placeholder*="Desde"]'
            ).first
            
            date_to = self.page.locator(
                'input[name*="hasta"], '
                'input[name*="fin"], '
                'input[id*="to"], '
                'input[placeholder*="Hasta"]'
            ).first
            
            if date_from.count() > 0 and date_to.count() > 0:
                date_from.fill(start_date.strftime("%d/%m/%Y"))
                date_to.fill(end_date.strftime("%d/%m/%Y"))
                
                # Click search/filter button
                filter_btn = self.page.locator(
                    'button:has-text("Consultar"), '
                    'button:has-text("Buscar"), '
                    'button:has-text("Filtrar")'
                ).first
                
                if filter_btn.count() > 0:
                    filter_btn.click()
                    self.page.wait_for_timeout(2000)
                    
        except Exception as e:
            logger.warning(f"Could not set date filter: {e}")
    
    def _get_products(self) -> list[dict]:
        """Get list of financial products (accounts, cards)."""
        products = []
        
        # Look for product cards/sections
        product_selectors = [
            '[class*="product-card"]',
            '[class*="cuenta"]',
            '[class*="tarjeta"]',
            '[class*="product-item"]',
            '[data-product-type]',
        ]
        
        for selector in product_selectors:
            items = self.page.locator(selector)
            if items.count() > 0:
                for i in range(items.count()):
                    item = items.nth(i)
                    name = item.text_content() or f"Product {i+1}"
                    products.append({
                        "name": name[:50],
                        "index": i,
                        "selector": selector,
                    })
                break
        
        # If no products found, assume single default product
        if not products:
            products.append({
                "name": "Cuenta Principal",
                "index": 0,
                "selector": None,
            })
        
        return products
    
    def _fetch_product_transactions(self, product: dict, days: int) -> list[Transaction]:
        """
        Fetch transactions for a specific product.
        
        Args:
            product: Product dictionary with name and selector.
            days: Number of days to fetch.
            
        Returns:
            List of Transaction objects.
        """
        transactions = []
        date_threshold = datetime.now() - timedelta(days=days)
        
        # Click on product if needed
        if product["selector"]:
            try:
                self.page.locator(product["selector"]).nth(product["index"]).click()
                self.page.wait_for_timeout(2000)
            except Exception:
                pass
        
        # Find transaction rows
        row_selectors = [
            'table tbody tr',
            '[class*="transaction-row"]',
            '[class*="movement-row"]',
            '[class*="list-item"]',
            '.transaction',
            '.movement',
        ]
        
        rows = None
        for selector in row_selectors:
            candidate = self.page.locator(selector)
            if candidate.count() > 0:
                rows = candidate
                break
        
        if not rows:
            logger.warning(f"No transaction rows found for {product['name']}")
            return []
        
        count = rows.count()
        logger.info(f"Found {count} rows for {product['name']}")
        
        for i in range(count):
            try:
                row = rows.nth(i)
                txn = self._parse_davivienda_row(row, i, product["name"])
                
                if txn:
                    txn_date = datetime.strptime(txn.date, "%Y-%m-%d")
                    if txn_date >= date_threshold:
                        transactions.append(txn)
                        
            except Exception as e:
                logger.debug(f"Error parsing row {i}: {e}")
                continue
        
        return transactions
    
    def _parse_davivienda_row(self, row, index: int, product_name: str) -> Transaction | None:
        """
        Parse a transaction row from Davivienda.
        
        Args:
            row: Playwright Locator for the row.
            index: Row index.
            product_name: Name of the product/account.
            
        Returns:
            Transaction object or None.
        """
        try:
            # Try to get cells if it's a table
            cells = row.locator('td')
            
            if cells.count() >= 3:
                # Table format: Date | Description | Amount
                date_text = cells.nth(0).text_content() or ""
                description = cells.nth(1).text_content() or ""
                amount_text = cells.nth(-1).text_content() or ""  # Last cell is usually amount
            else:
                # Non-table format: get all text
                text = row.text_content() or ""
                date_text = text
                description = text
                amount_text = text
            
            # Parse date
            date_str = self._extract_date(date_text)
            
            # Parse amount
            amount = self._extract_amount(amount_text)
            
            # Determine type
            txn_type = "expense" if amount < 0 else "income"
            
            # Clean description
            description = re.sub(r'[\d.,]+', '', description)
            description = re.sub(r'\s+', ' ', description).strip()[:100]
            
            if not description:
                description = "Transacción Davivienda"
            
            # Generate ID
            txn_id = f"DAVI_{datetime.now().strftime('%Y%m%d')}_{product_name[:10]}_{index:04d}"
            txn_id = re.sub(r'[^A-Za-z0-9_]', '', txn_id)
            
            return Transaction(
                id=txn_id,
                date=date_str,
                description=description,
                amount=amount,
                type=txn_type,
                raw_data={"product": product_name},
            )
            
        except Exception as e:
            logger.debug(f"Failed to parse Davivienda row: {e}")
            return None
    
    def _extract_date(self, text: str) -> str:
        """Extract and normalize date from text."""
        patterns = [
            (r'(\d{2})/(\d{2})/(\d{4})', lambda m: f"{m.group(3)}-{m.group(2)}-{m.group(1)}"),
            (r'(\d{4})-(\d{2})-(\d{2})', lambda m: m.group(0)),
            (r'(\d{2})-(\d{2})-(\d{4})', lambda m: f"{m.group(3)}-{m.group(2)}-{m.group(1)}"),
            (r'(\d{1,2})\s+(\w{3,})\s+(\d{4})', self._parse_spanish_date),
        ]
        
        for pattern, handler in patterns:
            match = re.search(pattern, text)
            if match:
                try:
                    return handler(match)
                except Exception:
                    continue
        
        return datetime.now().strftime("%Y-%m-%d")
    
    def _parse_spanish_date(self, match) -> str:
        """Parse Spanish date format like '15 Enero 2026'."""
        months = {
            'ene': '01', 'feb': '02', 'mar': '03', 'abr': '04',
            'may': '05', 'jun': '06', 'jul': '07', 'ago': '08',
            'sep': '09', 'oct': '10', 'nov': '11', 'dic': '12',
        }
        day = match.group(1).zfill(2)
        month_str = match.group(2)[:3].lower()
        month = months.get(month_str, '01')
        year = match.group(3)
        return f"{year}-{month}-{day}"
    
    def _extract_amount(self, text: str) -> float:
        """Extract monetary amount from text."""
        # Find all potential amounts
        amounts = re.findall(r'[\-\+]?\s*\$?\s*[\d.,]+', text)
        
        for amt_str in amounts:
            try:
                amount = self.parse_colombian_amount(amt_str)
                if amount != 0:
                    return amount
            except ValueError:
                continue
        
        return 0.0
