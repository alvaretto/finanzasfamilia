#!/usr/bin/env python3
"""
RPA Bank Scrapers - Main CLI Entry Point
Finanzas Familiares - Transaction Import Automation
"""

import json
import sys
from datetime import datetime
from pathlib import Path

import click
from loguru import logger
from rich.console import Console
from rich.table import Table

from config import config
from scrapers import NequiScraper, DaviviendaScraper, EmailScraper


# Configure logging
logger.remove()
logger.add(
    sys.stderr,
    format="<green>{time:HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{message}</cyan>",
    level="INFO",
)
logger.add(
    config.settings.log_dir / "rpa_{time:YYYY-MM-DD}.log",
    rotation="1 day",
    retention="7 days",
    level="DEBUG",
)

console = Console()


SCRAPERS = {
    "nequi": NequiScraper,
    "davivienda": DaviviendaScraper,
}


@click.group()
@click.version_option(version="1.0.0")
def cli():
    """
    RPA Bank Scrapers - Extract transactions from Colombian banks.
    
    \b
    Supported banks:
      - Nequi (digital wallet)
      - Davivienda (traditional bank)
    
    \b
    Also supports:
      - Email notifications parsing (Gmail/Outlook)
    """
    pass


@cli.command()
@click.option(
    "--bank", "-b",
    type=click.Choice(["nequi", "davivienda"]),
    required=True,
    help="Bank to scrape transactions from",
)
@click.option(
    "--days", "-d",
    type=int,
    default=30,
    help="Number of days to fetch (default: 30)",
)
@click.option(
    "--interactive", "-i",
    is_flag=True,
    help="Run in interactive mode (visible browser for OTP)",
)
@click.option(
    "--debug",
    is_flag=True,
    help="Enable debug mode with verbose logging",
)
def bank(bank: str, days: int, interactive: bool, debug: bool):
    """
    Scrape transactions from a specific bank.
    
    \b
    Examples:
      python main.py bank --bank nequi --days 30
      python main.py bank -b davivienda -d 15 --interactive
    """
    if debug:
        logger.remove()
        logger.add(sys.stderr, level="DEBUG")
    
    console.print(f"\n[bold blue]🏦 Starting {bank.upper()} scraper[/bold blue]\n")
    
    # Check credentials
    if not config.validate_bank(bank):
        console.print(f"[bold red]❌ Credentials not configured for {bank}[/bold red]")
        console.print(f"   Please check your .env file\n")
        sys.exit(1)
    
    try:
        ScraperClass = SCRAPERS[bank]
        scraper = ScraperClass(
            headless=not interactive,
            interactive=interactive,
        )
        
        transactions = scraper.run(days=days)
        
        _display_results(transactions, bank)
        
    except Exception as e:
        console.print(f"[bold red]❌ Error: {e}[/bold red]")
        logger.exception("Scraper error")
        sys.exit(1)


@cli.command()
@click.option(
    "--days", "-d",
    type=int,
    default=7,
    help="Number of days to fetch (default: 7)",
)
@click.option(
    "--debug",
    is_flag=True,
    help="Enable debug mode",
)
def email(days: int, debug: bool):
    """
    Scrape transaction notifications from email.
    
    \b
    Parses payment confirmation emails from:
      - Bancolombia
      - Davivienda  
      - Nequi
      - Payment processors (PSE, PayU, etc.)
    
    \b
    Examples:
      python main.py email --days 7
      python main.py email -d 30
    """
    if debug:
        logger.remove()
        logger.add(sys.stderr, level="DEBUG")
    
    console.print(f"\n[bold blue]📧 Starting email scraper[/bold blue]\n")
    
    # Check credentials
    if not config.validate_email():
        console.print("[bold red]❌ Email credentials not configured[/bold red]")
        console.print("   Please check your .env file\n")
        sys.exit(1)
    
    try:
        scraper = EmailScraper()
        transactions = scraper.run(days=days)
        
        _display_results(transactions, "email")
        
        # Export to JSON
        _export_json(transactions, "email")
        
    except Exception as e:
        console.print(f"[bold red]❌ Error: {e}[/bold red]")
        logger.exception("Email scraper error")
        sys.exit(1)


@cli.command()
@click.option(
    "--days", "-d",
    type=int,
    default=30,
    help="Number of days to fetch (default: 30)",
)
@click.option(
    "--interactive", "-i",
    is_flag=True,
    help="Run in interactive mode for OTP",
)
def all(days: int, interactive: bool):
    """
    Run all scrapers (banks + email).
    
    \b
    Examples:
      python main.py all --days 30
      python main.py all -d 15 --interactive
    """
    console.print("\n[bold blue]🚀 Running all scrapers[/bold blue]\n")
    
    all_transactions = []
    
    # Run bank scrapers
    for bank_name, ScraperClass in SCRAPERS.items():
        if config.validate_bank(bank_name):
            console.print(f"\n[yellow]→ Processing {bank_name}...[/yellow]")
            try:
                scraper = ScraperClass(
                    headless=not interactive,
                    interactive=interactive,
                )
                txns = scraper.run(days=days)
                all_transactions.extend(txns)
                console.print(f"[green]  ✓ {len(txns)} transactions[/green]")
            except Exception as e:
                console.print(f"[red]  ✗ Error: {e}[/red]")
    
    # Run email scraper
    if config.validate_email():
        console.print(f"\n[yellow]→ Processing email...[/yellow]")
        try:
            scraper = EmailScraper()
            txns = scraper.run(days=days)
            all_transactions.extend(txns)
            console.print(f"[green]  ✓ {len(txns)} transactions[/green]")
        except Exception as e:
            console.print(f"[red]  ✗ Error: {e}[/red]")
    
    # Display combined results
    console.print(f"\n[bold green]Total: {len(all_transactions)} transactions[/bold green]\n")
    
    # Export combined JSON
    _export_combined_json(all_transactions)


@cli.command()
def status():
    """Check configuration and connection status."""
    console.print("\n[bold blue]🔍 Configuration Status[/bold blue]\n")
    
    table = Table(show_header=True, header_style="bold magenta")
    table.add_column("Service")
    table.add_column("Status")
    table.add_column("Details")
    
    # Check Nequi
    if config.validate_bank("nequi"):
        table.add_row("Nequi", "[green]✓ Configured[/green]", f"Phone: {config.nequi.phone[:3]}***")
    else:
        table.add_row("Nequi", "[red]✗ Not configured[/red]", "Missing credentials")
    
    # Check Davivienda
    if config.validate_bank("davivienda"):
        table.add_row("Davivienda", "[green]✓ Configured[/green]", f"User: {config.davivienda.user[:3]}***")
    else:
        table.add_row("Davivienda", "[red]✗ Not configured[/red]", "Missing credentials")
    
    # Check Email
    if config.validate_email():
        table.add_row("Email", "[green]✓ Configured[/green]", f"{config.email.provider}: {config.email.address}")
    else:
        table.add_row("Email", "[red]✗ Not configured[/red]", "Missing credentials")
    
    # Check Supabase
    if config.supabase.url and config.supabase.key:
        table.add_row("Supabase", "[green]✓ Configured[/green]", "Sync enabled")
    else:
        table.add_row("Supabase", "[yellow]○ Not configured[/yellow]", "Sync disabled")
    
    console.print(table)
    
    # Check directories
    console.print("\n[bold]Directories:[/bold]")
    console.print(f"  Output: {config.settings.output_dir.absolute()}")
    console.print(f"  Logs: {config.settings.log_dir.absolute()}")
    console.print(f"  Storage: {config.settings.storage_dir.absolute()}")
    console.print()


@cli.command()
@click.argument("filepath", type=click.Path(exists=True))
def preview(filepath: str):
    """
    Preview a JSON export file.
    
    \b
    Examples:
      python main.py preview output/nequi_transactions.json
    """
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    console.print(f"\n[bold blue]📄 Preview: {filepath}[/bold blue]\n")
    console.print(f"Bank: {data.get('bank', 'N/A')}")
    console.print(f"Extracted: {data.get('extracted_at', 'N/A')}")
    console.print(f"Count: {data.get('transaction_count', 0)}")
    
    transactions = data.get("transactions", [])
    if transactions:
        _display_results_from_dict(transactions[:20])
        
        if len(transactions) > 20:
            console.print(f"\n[dim]... and {len(transactions) - 20} more[/dim]")


def _display_results(transactions: list, source: str) -> None:
    """Display transactions in a formatted table."""
    if not transactions:
        console.print("[yellow]No transactions found[/yellow]\n")
        return
    
    table = Table(
        title=f"{source.upper()} Transactions",
        show_header=True,
        header_style="bold cyan",
    )
    table.add_column("Date", style="dim")
    table.add_column("Description")
    table.add_column("Amount", justify="right")
    table.add_column("Type")
    
    for txn in transactions[:20]:  # Show first 20
        amount_str = f"${abs(txn.amount):,.0f}"
        amount_style = "red" if txn.type == "expense" else "green"
        
        table.add_row(
            txn.date,
            txn.description[:40],
            f"[{amount_style}]{'-' if txn.type == 'expense' else '+'}{amount_str}[/{amount_style}]",
            txn.type,
        )
    
    console.print(table)
    
    if len(transactions) > 20:
        console.print(f"\n[dim]Showing 20 of {len(transactions)} transactions[/dim]")
    
    # Summary
    total_income = sum(t.amount for t in transactions if t.type == "income")
    total_expense = sum(t.amount for t in transactions if t.type == "expense")
    
    console.print(f"\n[bold]Summary:[/bold]")
    console.print(f"  Income:  [green]+${total_income:,.0f}[/green]")
    console.print(f"  Expense: [red]-${abs(total_expense):,.0f}[/red]")
    console.print(f"  Net:     ${total_income + total_expense:,.0f}")
    console.print()


def _display_results_from_dict(transactions: list[dict]) -> None:
    """Display transactions from dictionary format."""
    table = Table(show_header=True, header_style="bold cyan")
    table.add_column("Date", style="dim")
    table.add_column("Description")
    table.add_column("Amount", justify="right")
    table.add_column("Category")
    
    for txn in transactions:
        amount = txn.get("amount", 0)
        amount_str = f"${abs(amount):,.0f}"
        txn_type = txn.get("type", "expense")
        amount_style = "red" if txn_type == "expense" else "green"
        
        table.add_row(
            txn.get("date", ""),
            txn.get("description", "")[:40],
            f"[{amount_style}]{'-' if amount < 0 else '+'}{amount_str}[/{amount_style}]",
            txn.get("category_hint", "otros"),
        )
    
    console.print(table)


def _export_json(transactions: list, source: str) -> None:
    """Export transactions to JSON file."""
    output_path = config.settings.output_dir / f"{source}_transactions.json"
    
    data = {
        "bank": source,
        "extracted_at": datetime.now().isoformat(),
        "transaction_count": len(transactions),
        "transactions": [t.to_dict() for t in transactions],
    }
    
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    console.print(f"[green]✓ Exported to: {output_path}[/green]\n")


def _export_combined_json(transactions: list) -> None:
    """Export all transactions to a combined JSON file."""
    output_path = config.settings.output_dir / f"all_transactions_{datetime.now().strftime('%Y%m%d')}.json"
    
    data = {
        "source": "combined",
        "extracted_at": datetime.now().isoformat(),
        "transaction_count": len(transactions),
        "transactions": [t.to_dict() for t in transactions],
    }
    
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    console.print(f"[green]✓ Combined export: {output_path}[/green]\n")


if __name__ == "__main__":
    cli()
