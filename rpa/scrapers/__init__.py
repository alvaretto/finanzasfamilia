"""Scrapers package for RPA bank automation."""

from .base_scraper import BaseScraper
from .nequi_scraper import NequiScraper
from .davivienda_scraper import DaviviendaScraper
from .email_scraper import EmailScraper

__all__ = [
    "BaseScraper",
    "NequiScraper", 
    "DaviviendaScraper",
    "EmailScraper",
]
