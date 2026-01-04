"""
Email scraper for payment notifications.
Extracts transaction data from bank notification emails.

Supports:
- Gmail (IMAP)
- Outlook (IMAP)

Parses notifications from:
- Davivienda
- Bancolombia
- Nequi
- Other Colombian banks
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
    Scraper for bank notification emails.
    
    Connects via IMAP to read emails and extract transaction data
    from payment notifications.
    """
    
    # Email subjects that indicate payment notifications
    NOTIFICATION_SUBJECTS = [
        "compra",
        "pago",
        "transacción",
        "retiro",
        "transferencia",
        "débito",
        "cargo",
        "movimiento",
        "notificación",
        "alerta",
    ]
    
    # Bank sender patterns
    BANK_SENDERS = {
        "davivienda": ["davivienda", "daviplata"],
        "bancolombia": ["bancolombia", "nequi"],
        "banco de bogota": ["bancodebogota"],
        "bbva": ["bbva"],
        "scotiabank": ["scotiabank", "colpatria"],
    }
    
    def __init__(self) -> None:
        self.email_address = config.email.address
        self.password = config.email.app_password
        self.imap_server = config.email.imap_server
        self.provider = config.email.provider
        
        if not self.email_address or not self.password:
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
        self.client.login(self.email_address, self.password)
        
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
        Fetch transactions from email notifications.
        
        Args:
            days: Number of days to search back.
            
        Returns:
            List of Transaction objects.
        """
        logger.info(f"Searching emails from last {days} days...")
        
        with self:
            # Select inbox
            self.client.select_folder("INBOX")
            
            # Calculate date range
            since_date = datetime.now() - timedelta(days=days)
            
            # Search for bank notification emails
            messages = self._search_bank_emails(since_date)
            logger.info(f"Found {len(messages)} potential notification emails")
            
            # Process each email
            for msg_id in messages:
                try:
                    tx = self._process_email(msg_id)
                    if tx:
                        self.transactions.append(tx)
                except Exception as e:
                    logger.warning(f"Error processing email {msg_id}: {e}")
                    continue
            
            logger.info(f"Extracted {len(self.transactions)} transactions from emails")
        
        return self.transactions
    
    def _search_bank_emails(self, since_date: datetime) -> list[int]:
        """
        Search for bank notification emails.
        
        Args:
            since_date: Search emails after this date.
            
        Returns:
            List of message IDs.
        """
        all_messages = set()
        
        # Search by subject keywords
        for keyword in self.NOTIFICATION_SUBJECTS:
            try:
                criteria = [
                    "SINCE", since_date.strftime("%d-%b-%Y"),
                    "SUBJECT", keyword,
                ]
                messages = self.client.search(criteria)
                all_messages.update(messages)
            except Exception as e:
                logger.debug(f"Search for '{keyword}' failed: {e}")
        
        # Search by sender (bank domains)
        bank_domains = ["davivienda", "bancolombia", "nequi", "daviplata"]
        for domain in bank_domains:
            try:
                criteria = [
                    "SINCE", since_date.strftime("%d-%b-%Y"),
                    "FROM", domain,
                ]
                messages = self.client.search(criteria)
                all_messages.update(messages)
            except Exception as e:
                logger.debug(f"Search for sender '{domain}' failed: {e}")
        
        return list(all_messages)
    
    def _process_email(self, msg_id: int) -> Transaction | None:
        """
        Process a single email and extract transaction data.
        
        Args:
            msg_id: IMAP message ID.
            
        Returns:
            Transaction object or None.
        """
        # Fetch email content
        response = self.client.fetch(msg_id, ["RFC822", "ENVELOPE"])
        
        if msg_id not in response:
            return None
        
        raw_email = response[msg_id][b"RFC822"]
        envelope = response[msg_id][b"ENVELOPE"]
        
        # Parse email
        msg = email.message_from_bytes(raw_email)
        
        # Get sender
        sender = self._decode_header(envelope.from_[0].mailbox.decode() + "@" + envelope.from_[0].host.decode())
        
        # Get subject
        subject = self._decode_header(envelope.subject.decode() if envelope.subject else "")
        
        # Get date
        email_date = envelope.date
        
        # Get body
        body = self._get_email_body(msg)
        
        # Identify bank
        bank = self._identify_bank(sender, subject, body)
        
        if not bank:
            return None
        
        # Extract transaction data based on bank
        return self._extract_transaction(bank, subject, body, email_date)
    
    def _decode_header(self, header: str) -> str:
        """Decode email header."""
        if not header:
            return ""
        
        try:
            decoded_parts = decode_header(header)
            result = ""
            for part, encoding in decoded_parts:
                if isinstance(part, bytes):
                    result += part.decode(encoding or "utf-8", errors="replace")
                else:
                    result += part
            return result
        except Exception:
            return str(header)
    
    def _get_email_body(self, msg: email.message.Message) -> str:
        """Extract plain text body from email."""
        body = ""
        
        if msg.is_multipart():
            for part in msg.walk():
                content_type = part.get_content_type()
                if content_type == "text/plain":
                    payload = part.get_payload(decode=True)
                    if payload:
                        charset = part.get_content_charset() or "utf-8"
                        body += payload.decode(charset, errors="replace")
                elif content_type == "text/html" and not body:
                    # Fallback to HTML if no plain text
                    payload = part.get_payload(decode=True)
                    if payload:
                        charset = part.get_content_charset() or "utf-8"
                        html = payload.decode(charset, errors="replace")
                        # Basic HTML to text
                        body = re.sub(r"<[^>]+>", " ", html)
        else:
            payload = msg.get_payload(decode=True)
            if payload:
                charset = msg.get_content_charset() or "utf-8"
                body = payload.decode(charset, errors="replace")
        
        return body
    
    def _identify_bank(self, sender: str, subject: str, body: str) -> str | None:
        """Identify which bank sent the notification."""
        text = f"{sender} {subject} {body}".lower()
        
        for bank, patterns in self.BANK_SENDERS.items():
            for pattern in patterns:
                if pattern in text:
                    return bank
        
        return None
    
    def _extract_transaction(
        self,
        bank: str,
        subject: str,
        body: str,
        email_date: datetime
    ) -> Transaction | None:
        """
        Extract transaction data from email content.
        
        Different banks have different email formats.
        """
        text = f"{subject}\n{body}"
        
        # Extract amount
        amount = self._extract_amount(text)
        if not amount:
            return None
        
        # Extract description
        description = self._extract_description(text, bank)
        
        # Determine transaction type
        expense_keywords = ["compra", "pago", "débito", "cargo", "retiro"]
        income_keywords = ["abono", "crédito", "transferencia recibida", "consignación"]
        
        text_lower = text.lower()
        
        if any(kw in text_lower for kw in expense_keywords):
            tx_type = "expense"
            amount = -abs(amount)
        elif any(kw in text_lower for kw in income_keywords):
            tx_type = "income"
            amount = abs(amount)
        else:
            tx_type = "expense"  # Default to expense for card notifications
            amount = -abs(amount)
        
        # Generate ID
        date_str = email_date.strftime("%Y-%m-%d") if email_date else datetime.now().strftime("%Y-%m-%d")
        tx_id = f"EMAIL_{bank.upper()}_{date_str}_{abs(hash(description)) % 10000}"
        
        return Transaction(
            id=tx_id,
            date=date_str,
            description=description,
            amount=amount,
            type=tx_type,
            raw_data={
                "bank": bank,
                "subject": subject,
                "body_preview": body[:500],
            },
        )
    
    def _extract_amount(self, text: str) -> float | None:
        """Extract monetary amount from text."""
        # Patterns for Colombian currency
        patterns = [
            r"\$\s*([\d.,]+)",  # $1.234.567 or $1,234.567
            r"([\d.,]+)\s*(?:pesos|COP)",  # 1234567 pesos
            r"(?:valor|monto|total)[\s:]*\$?\s*([\d.,]+)",
            r"por\s*\$?\s*([\d.,]+)",
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                amount_str = match.group(1)
                try:
                    # Parse Colombian format
                    # Remove thousands separators (dots) and convert decimal comma
                    if "," in amount_str and "." in amount_str:
                        # Format: 1.234.567,89
                        if amount_str.rfind(",") > amount_str.rfind("."):
                            amount_str = amount_str.replace(".", "").replace(",", ".")
                        else:
                            amount_str = amount_str.replace(",", "")
                    elif "." in amount_str:
                        # Could be 1.234.567 (thousands) or 1234.56 (decimal)
                        parts = amount_str.split(".")
                        if len(parts[-1]) == 3 or len(parts) > 2:
                            # Thousands separator
                            amount_str = amount_str.replace(".", "")
                    elif "," in amount_str:
                        # Decimal separator
                        amount_str = amount_str.replace(",", ".")
                    
                    return float(amount_str)
                except ValueError:
                    continue
        
        return None
    
    def _extract_description(self, text: str, bank: str) -> str:
        """Extract transaction description/merchant from text."""
        # Patterns for merchant/establishment
        patterns = [
            r"(?:en|comercio|establecimiento)[\s:]+([A-Za-z0-9\s]+?)(?:\.|,|\n|$)",
            r"(?:compra en|pago a|transferencia a)[\s:]+([A-Za-z0-9\s]+?)(?:\.|,|\n|$)",
            r"(?:referencia|concepto)[\s:]+([A-Za-z0-9\s]+?)(?:\.|,|\n|$)",
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                desc = match.group(1).strip()
                if len(desc) > 3:  # Avoid very short matches
                    return desc[:100]  # Limit length
        
        # Fallback: use part of subject or first line
        lines = text.split("\n")
        for line in lines[:5]:
            line = line.strip()
            if len(line) > 10 and not line.startswith(("http", "www")):
                return line[:100]
        
        return f"Notificación {bank}"
    
    def export_json(self) -> None:
        """Export transactions to JSON file."""
        import json
        from pathlib import Path
        
        output_path = config.settings.output_dir / "email_transactions.json"
        
        data = {
            "source": "email",
            "provider": self.provider,
            "extracted_at": datetime.now().isoformat(),
            "transaction_count": len(self.transactions),
            "transactions": [t.to_dict() for t in self.transactions],
        }
        
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        logger.info(f"Exported to: {output_path}")
