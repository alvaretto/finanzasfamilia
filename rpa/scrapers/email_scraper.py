"""
Email scraper for extracting transaction notifications from Gmail/Outlook.
Parses payment confirmation emails from banks and payment processors.
"""

import email
import re
from datetime import datetime, timedelta
from email.header import decode_header
from typing import Generator

from imapclient import IMAPClient
from loguru import logger

from config import config
from .base_scraper import Transaction


class EmailScraper:
    """
    Scraper for bank transaction notifications via email.
    
    Supported email providers:
    - Gmail (requires App Password)
    - Outlook/Hotmail
    
    Parses emails from:
    - Bancolombia
    - Davivienda
    - Nequi
    - Payment processors (PSE, PayU, etc.)
    """
    
    # Email senders to look for
    BANK_SENDERS = [
        "notificaciones@bancolombia.com.co",
        "alertas@bancolombia.com.co",
        "notificaciones@davivienda.com",
        "alertas@davivienda.com",
        "notificaciones@nequi.com",
        "nequi@bancolombia.com.co",
        "daviplata@davivienda.com",
        "pse@ach.com.co",
        "notificaciones@payu.com",
        "no-reply@mercadopago.com",
    ]
    
    # Keywords indicating transaction emails
    TRANSACTION_KEYWORDS = [
        "compra",
        "pago",
        "transacción",
        "retiro",
        "transferencia",
        "débito",
        "cargo",
        "abono",
        "consignación",
    ]
    
    def __init__(self) -> None:
        """Initialize email scraper."""
        self.provider = config.email.provider
        self.address = config.email.address
        self.password = config.email.app_password
        self.imap_server = config.email.imap_server
        
        if not self.address or not self.password:
            raise ValueError("Email credentials not configured. Check .env file.")
        
        self.client: IMAPClient | None = None
        self.transactions: list[Transaction] = []
    
    def __enter__(self) -> "EmailScraper":
        """Context manager entry - connect to IMAP."""
        self.connect()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        """Context manager exit - disconnect."""
        self.disconnect()
    
    def connect(self) -> None:
        """Connect to IMAP server."""
        logger.info(f"Connecting to {self.imap_server}...")
        
        self.client = IMAPClient(self.imap_server, ssl=True)
        self.client.login(self.address, self.password)
        
        logger.info("Connected successfully")
    
    def disconnect(self) -> None:
        """Disconnect from IMAP server."""
        if self.client:
            try:
                self.client.logout()
            except Exception:
                pass
            self.client = None
    
    def fetch_transactions(self, days: int = 7) -> list[Transaction]:
        """
        Fetch transaction notifications from email.
        
        Args:
            days: Number of days to look back.
            
        Returns:
            List of Transaction objects.
        """
        logger.info(f"Fetching email transactions for last {days} days...")
        
        with self:
            # Select inbox
            self.client.select_folder("INBOX")
            
            # Calculate date threshold
            since_date = datetime.now() - timedelta(days=days)
            
            # Search for bank emails
            transactions = []
            
            for sender in self.BANK_SENDERS:
                try:
                    txns = self._fetch_from_sender(sender, since_date)
                    transactions.extend(txns)
                except Exception as e:
                    logger.warning(f"Error fetching from {sender}: {e}")
            
            # Also search by keywords in subject
            keyword_txns = self._fetch_by_keywords(since_date)
            
            # Merge and deduplicate
            all_txns = transactions + keyword_txns
            self.transactions = self._deduplicate(all_txns)
            
            logger.info(f"Found {len(self.transactions)} transaction emails")
            
            return self.transactions
    
    def _fetch_from_sender(self, sender: str, since_date: datetime) -> list[Transaction]:
        """Fetch and parse emails from a specific sender."""
        transactions = []
        
        # Search criteria
        criteria = [
            "FROM", sender,
            "SINCE", since_date.strftime("%d-%b-%Y"),
        ]
        
        message_ids = self.client.search(criteria)
        
        if not message_ids:
            return []
        
        logger.debug(f"Found {len(message_ids)} emails from {sender}")
        
        # Fetch messages
        for msg_id in message_ids[:100]:  # Limit to 100 per sender
            try:
                txn = self._parse_email(msg_id)
                if txn:
                    transactions.append(txn)
            except Exception as e:
                logger.debug(f"Error parsing email {msg_id}: {e}")
        
        return transactions
    
    def _fetch_by_keywords(self, since_date: datetime) -> list[Transaction]:
        """Fetch emails matching transaction keywords in subject."""
        transactions = []
        
        for keyword in self.TRANSACTION_KEYWORDS:
            try:
                criteria = [
                    "SUBJECT", keyword,
                    "SINCE", since_date.strftime("%d-%b-%Y"),
                ]
                
                message_ids = self.client.search(criteria)
                
                for msg_id in message_ids[:50]:  # Limit per keyword
                    try:
                        txn = self._parse_email(msg_id)
                        if txn:
                            transactions.append(txn)
                    except Exception:
                        continue
                        
            except Exception as e:
                logger.debug(f"Error searching for '{keyword}': {e}")
        
        return transactions
    
    def _parse_email(self, msg_id: int) -> Transaction | None:
        """
        Parse a single email into a Transaction.
        
        Args:
            msg_id: IMAP message ID.
            
        Returns:
            Transaction object or None.
        """
        # Fetch message
        response = self.client.fetch([msg_id], ["RFC822", "ENVELOPE"])
        
        if msg_id not in response:
            return None
        
        raw_email = response[msg_id][b"RFC822"]
        envelope = response[msg_id][b"ENVELOPE"]
        
        # Parse email
        msg = email.message_from_bytes(raw_email)
        
        # Get subject
        subject = self._decode_header(envelope.subject)
        
        # Get date
        email_date = envelope.date
        if email_date:
            date_str = email_date.strftime("%Y-%m-%d")
        else:
            date_str = datetime.now().strftime("%Y-%m-%d")
        
        # Get body
        body = self._get_email_body(msg)
        
        if not body:
            return None
        
        # Check if it's a transaction email
        if not self._is_transaction_email(subject, body):
            return None
        
        # Extract transaction details
        amount = self._extract_amount(body)
        description = self._extract_description(subject, body)
        txn_type = self._determine_type(subject, body)
        
        if amount == 0:
            return None
        
        # Make expenses negative
        if txn_type == "expense" and amount > 0:
            amount = -amount
        
        # Generate ID from email
        txn_id = f"EMAIL_{date_str.replace('-', '')}_{msg_id}"
        
        return Transaction(
            id=txn_id,
            date=date_str,
            description=description,
            amount=amount,
            type=txn_type,
            raw_data={
                "subject": subject,
                "email_id": msg_id,
            },
        )
    
    def _decode_header(self, header) -> str:
        """Decode email header to string."""
        if header is None:
            return ""
        
        if isinstance(header, bytes):
            header = header.decode("utf-8", errors="ignore")
        
        try:
            decoded_parts = decode_header(str(header))
            result = ""
            for part, encoding in decoded_parts:
                if isinstance(part, bytes):
                    result += part.decode(encoding or "utf-8", errors="ignore")
                else:
                    result += str(part)
            return result
        except Exception:
            return str(header)
    
    def _get_email_body(self, msg) -> str:
        """Extract text body from email message."""
        body = ""
        
        if msg.is_multipart():
            for part in msg.walk():
                content_type = part.get_content_type()
                content_disposition = str(part.get("Content-Disposition"))
                
                if content_type == "text/plain" and "attachment" not in content_disposition:
                    try:
                        payload = part.get_payload(decode=True)
                        charset = part.get_content_charset() or "utf-8"
                        body += payload.decode(charset, errors="ignore")
                    except Exception:
                        continue
                        
                elif content_type == "text/html" and not body:
                    try:
                        payload = part.get_payload(decode=True)
                        charset = part.get_content_charset() or "utf-8"
                        html = payload.decode(charset, errors="ignore")
                        # Strip HTML tags
                        body = re.sub(r'<[^>]+>', ' ', html)
                        body = re.sub(r'\s+', ' ', body)
                    except Exception:
                        continue
        else:
            try:
                payload = msg.get_payload(decode=True)
                charset = msg.get_content_charset() or "utf-8"
                body = payload.decode(charset, errors="ignore")
            except Exception:
                pass
        
        return body.strip()
    
    def _is_transaction_email(self, subject: str, body: str) -> bool:
        """Check if email is about a financial transaction."""
        text = f"{subject} {body}".lower()
        
        # Must contain at least one transaction keyword
        has_keyword = any(kw in text for kw in self.TRANSACTION_KEYWORDS)
        
        # Must contain currency indicator
        has_currency = "$" in text or "cop" in text or "pesos" in text
        
        # Must have a number that looks like an amount
        has_amount = bool(re.search(r'\$?\s*[\d.,]{3,}', text))
        
        return has_keyword and (has_currency or has_amount)
    
    def _extract_amount(self, body: str) -> float:
        """Extract transaction amount from email body."""
        # Common patterns in Colombian bank emails
        patterns = [
            r'valor[:\s]+\$?\s*([\d.,]+)',
            r'monto[:\s]+\$?\s*([\d.,]+)',
            r'total[:\s]+\$?\s*([\d.,]+)',
            r'por\s+\$?\s*([\d.,]+)',
            r'\$\s*([\d.,]+)',
            r'([\d.,]+)\s*(?:pesos|cop)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, body.lower())
            if match:
                try:
                    amount_str = match.group(1)
                    # Parse Colombian format
                    return self._parse_amount(amount_str)
                except ValueError:
                    continue
        
        return 0.0
    
    def _parse_amount(self, amount_str: str) -> float:
        """Parse Colombian currency format."""
        # Remove non-numeric except . and ,
        cleaned = re.sub(r'[^\d.,]', '', amount_str)
        
        if not cleaned:
            return 0.0
        
        # Colombian format: dots for thousands, comma for decimals
        if ',' in cleaned and '.' in cleaned:
            # Has both - dots are thousands
            cleaned = cleaned.replace('.', '').replace(',', '.')
        elif ',' in cleaned:
            # Only comma - could be decimal or thousands
            parts = cleaned.split(',')
            if len(parts[-1]) == 2:  # Likely decimal
                cleaned = cleaned.replace(',', '.')
            else:  # Likely thousands
                cleaned = cleaned.replace(',', '')
        else:
            # Only dots - likely thousands separators
            cleaned = cleaned.replace('.', '')
        
        return float(cleaned)
    
    def _extract_description(self, subject: str, body: str) -> str:
        """Extract transaction description."""
        # Try to find merchant/establishment name
        patterns = [
            r'en\s+([A-Z][A-Za-z0-9\s]+?)(?:\.|,|\s+por)',
            r'establecimiento[:\s]+([^\n,]+)',
            r'comercio[:\s]+([^\n,]+)',
            r'(?:compra|pago)\s+(?:en\s+)?([A-Z][A-Za-z0-9\s]+)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, body, re.IGNORECASE)
            if match:
                desc = match.group(1).strip()
                if len(desc) > 3:
                    return desc[:100]
        
        # Fall back to cleaned subject
        subject_clean = re.sub(r'\$[\d.,]+', '', subject)
        subject_clean = re.sub(r'\s+', ' ', subject_clean).strip()
        
        return subject_clean[:100] if subject_clean else "Transacción por email"
    
    def _determine_type(self, subject: str, body: str) -> str:
        """Determine if transaction is income or expense."""
        text = f"{subject} {body}".lower()
        
        expense_keywords = [
            "compra", "pago", "retiro", "débito", "cargo",
            "transferencia enviada", "gasto",
        ]
        
        income_keywords = [
            "abono", "consignación", "transferencia recibida",
            "depósito", "ingreso", "recibido",
        ]
        
        expense_count = sum(1 for kw in expense_keywords if kw in text)
        income_count = sum(1 for kw in income_keywords if kw in text)
        
        return "income" if income_count > expense_count else "expense"
    
    def _deduplicate(self, transactions: list[Transaction]) -> list[Transaction]:
        """Remove duplicate transactions based on date + amount + description."""
        seen = set()
        unique = []
        
        for txn in transactions:
            key = (txn.date, txn.amount, txn.description[:30])
            if key not in seen:
                seen.add(key)
                unique.append(txn)
        
        return unique
    
    def run(self, days: int = 7) -> list[Transaction]:
        """
        Main execution flow.
        
        Args:
            days: Number of days to fetch.
            
        Returns:
            List of Transaction objects.
        """
        return self.fetch_transactions(days)
