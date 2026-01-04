"""
Configuration module for RPA Bank Scrapers.
Uses pydantic-settings for type-safe environment variable handling.
"""

from pathlib import Path
from typing import Literal

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class NequiConfig(BaseSettings):
    """Nequi bank credentials."""
    
    model_config = SettingsConfigDict(env_prefix="NEQUI_")
    
    phone: str = Field(default="", description="Phone number registered with Nequi")
    password: str = Field(default="", description="Nequi password")
    
    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        if v and not v.isdigit():
            raise ValueError("Phone must contain only digits")
        if v and len(v) != 10:
            raise ValueError("Phone must be 10 digits")
        return v


class DaviviendaConfig(BaseSettings):
    """Davivienda bank credentials."""
    
    model_config = SettingsConfigDict(env_prefix="DAVIVIENDA_")
    
    user: str = Field(default="", description="Davivienda username")
    password: str = Field(default="", description="Davivienda password")
    document_type: Literal["CC", "CE", "TI", "PA", "NIT"] = Field(
        default="CC",
        description="Document type"
    )


class EmailConfig(BaseSettings):
    """Email configuration for scraping payment notifications."""
    
    model_config = SettingsConfigDict(env_prefix="EMAIL_")
    
    provider: Literal["gmail", "outlook"] = Field(
        default="gmail",
        description="Email provider"
    )
    address: str = Field(default="", description="Email address")
    app_password: str = Field(default="", description="App password for IMAP")
    
    @property
    def imap_server(self) -> str:
        """Get IMAP server based on provider."""
        servers = {
            "gmail": "imap.gmail.com",
            "outlook": "outlook.office365.com",
        }
        return servers.get(self.provider, "imap.gmail.com")


class SupabaseConfig(BaseSettings):
    """Supabase configuration for direct sync."""
    
    model_config = SettingsConfigDict(env_prefix="SUPABASE_")
    
    url: str = Field(default="", description="Supabase project URL")
    key: str = Field(default="", description="Supabase anon key")
    user_id: str = Field(default="", description="User UUID for RLS")


class ScraperSettings(BaseSettings):
    """General scraper settings."""
    
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")
    
    # Timeouts (milliseconds)
    page_timeout: int = Field(default=30000, description="Page load timeout")
    element_timeout: int = Field(default=10000, description="Element wait timeout")
    
    # Browser settings
    headless: bool = Field(default=True, description="Run in headless mode")
    screenshot_on_error: bool = Field(default=True, description="Screenshot on error")
    debug: bool = Field(default=False, description="Enable debug mode")
    
    # Directories
    output_dir: Path = Field(default=Path("./output"))
    log_dir: Path = Field(default=Path("./logs"))
    storage_dir: Path = Field(default=Path("./storage"))
    
    def ensure_dirs(self) -> None:
        """Create necessary directories if they don't exist."""
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.log_dir.mkdir(parents=True, exist_ok=True)
        self.storage_dir.mkdir(parents=True, exist_ok=True)


class Config:
    """Main configuration container."""
    
    def __init__(self) -> None:
        self.nequi = NequiConfig()
        self.davivienda = DaviviendaConfig()
        self.email = EmailConfig()
        self.supabase = SupabaseConfig()
        self.settings = ScraperSettings()
        
        # Ensure directories exist
        self.settings.ensure_dirs()
    
    def validate_bank(self, bank: str) -> bool:
        """Check if credentials are configured for a bank."""
        if bank == "nequi":
            return bool(self.nequi.phone and self.nequi.password)
        elif bank == "davivienda":
            return bool(self.davivienda.user and self.davivienda.password)
        return False
    
    def validate_email(self) -> bool:
        """Check if email credentials are configured."""
        return bool(self.email.address and self.email.app_password)


# Global config instance
config = Config()


# Bank URLs
BANK_URLS = {
    "nequi": {
        "login": "https://transacciones.nequi.com.co/",
        "home": "https://transacciones.nequi.com.co/home",
        "movements": "https://transacciones.nequi.com.co/movements",
    },
    "davivienda": {
        "login": "https://www.davivienda.com/wps/portal/personas/nuevo/ingresar",
        "home": "https://www.davivienda.com/wps/portal/personas/nuevo/home",
        "movements": "https://www.davivienda.com/wps/portal/personas/nuevo/consultas/movimientos",
    },
}

# Category mapping hints (for auto-categorization)
CATEGORY_HINTS = {
    "netflix": "entretenimiento",
    "spotify": "entretenimiento",
    "youtube": "entretenimiento",
    "amazon": "compras",
    "mercadolibre": "compras",
    "rappi": "comida",
    "ifood": "comida",
    "uber": "transporte",
    "didi": "transporte",
    "epm": "servicios",
    "claro": "servicios",
    "movistar": "servicios",
    "tigo": "servicios",
    "gas": "servicios",
    "agua": "servicios",
    "luz": "servicios",
    "farmacia": "salud",
    "drogueria": "salud",
    "supermercado": "mercado",
    "exito": "mercado",
    "jumbo": "mercado",
    "d1": "mercado",
    "ara": "mercado",
    "carulla": "mercado",
}
