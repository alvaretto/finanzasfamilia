#!/usr/bin/env python3
"""
RPA Testing Tools - CLI Principal
Herramientas para generar e importar datos de prueba.
"""

import click
import json
from pathlib import Path
from rich.console import Console
from rich.table import Table

from generators.fake_transactions import FakeTransactionGenerator
from importers.csv_importer import CSVImporter
from importers.json_importer import JSONImporter

console = Console()
OUTPUT_DIR = Path(__file__).parent / "output"


@click.group()
@click.version_option(version="1.0.0")
def cli():
    """RPA Testing Tools - Generador e importador de transacciones."""
    pass


@cli.command()
@click.option("--count", "-c", default=100, help="Numero de transacciones a generar")
@click.option("--days", "-d", default=30, help="Rango de dias hacia atras")
@click.option("--pattern", "-p", default="mixed",
              type=click.Choice(["mixed", "salary", "freelance", "student"]),
              help="Patron de generacion")
@click.option("--output", "-o", default=None, help="Archivo de salida")
def generate(count: int, days: int, pattern: str, output: str):
    """Generar transacciones fake con patrones colombianos."""
    console.print(f"[bold blue]Generando {count} transacciones...[/]")

    generator = FakeTransactionGenerator(locale="es_CO")
    transactions = generator.generate(count=count, days_back=days, pattern=pattern)

    output_file = output or str(OUTPUT_DIR / "transactions.json")
    Path(output_file).parent.mkdir(parents=True, exist_ok=True)

    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(transactions, f, indent=2, ensure_ascii=False, default=str)

    console.print(f"[bold green]✓ Generadas {len(transactions)} transacciones[/]")
    console.print(f"[dim]Archivo: {output_file}[/]")

    # Mostrar resumen
    _show_summary(transactions)


@cli.command("import-csv")
@click.argument("file", type=click.Path(exists=True))
@click.option("--format", "-f", default="auto",
              type=click.Choice(["auto", "bancolombia", "davivienda", "nequi", "generic"]),
              help="Formato del CSV")
@click.option("--output", "-o", default=None, help="Archivo de salida")
def import_csv(file: str, format: str, output: str):
    """Importar transacciones desde archivo CSV."""
    console.print(f"[bold blue]Importando desde {file}...[/]")

    importer = CSVImporter()
    transactions = importer.import_file(file, format=format)

    output_file = output or str(OUTPUT_DIR / "imported_csv.json")
    Path(output_file).parent.mkdir(parents=True, exist_ok=True)

    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(transactions, f, indent=2, ensure_ascii=False, default=str)

    console.print(f"[bold green]✓ Importadas {len(transactions)} transacciones[/]")
    console.print(f"[dim]Archivo: {output_file}[/]")


@cli.command("import-json")
@click.argument("file", type=click.Path(exists=True))
@click.option("--output", "-o", default=None, help="Archivo de salida")
def import_json(file: str, output: str):
    """Importar transacciones desde archivo JSON."""
    console.print(f"[bold blue]Importando desde {file}...[/]")

    importer = JSONImporter()
    transactions = importer.import_file(file)

    output_file = output or str(OUTPUT_DIR / "imported_json.json")
    Path(output_file).parent.mkdir(parents=True, exist_ok=True)

    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(transactions, f, indent=2, ensure_ascii=False, default=str)

    console.print(f"[bold green]✓ Importadas {len(transactions)} transacciones[/]")
    console.print(f"[dim]Archivo: {output_file}[/]")


@cli.command()
@click.argument("file", type=click.Path(exists=True))
@click.option("--limit", "-l", default=10, help="Numero de registros a mostrar")
def preview(file: str, limit: int):
    """Previsualizar archivo de transacciones."""
    with open(file, "r", encoding="utf-8") as f:
        data = json.load(f)

    table = Table(title=f"Preview: {Path(file).name}")
    table.add_column("Fecha", style="cyan")
    table.add_column("Tipo", style="magenta")
    table.add_column("Descripcion", style="white")
    table.add_column("Monto", style="green", justify="right")
    table.add_column("Categoria", style="yellow")

    for tx in data[:limit]:
        amount = tx.get("amount", 0)
        amount_str = f"${amount:,.0f}" if amount >= 0 else f"-${abs(amount):,.0f}"
        table.add_row(
            tx.get("date", "")[:10],
            tx.get("type", ""),
            tx.get("description", "")[:30],
            amount_str,
            tx.get("category", "")
        )

    console.print(table)
    console.print(f"\n[dim]Mostrando {min(limit, len(data))} de {len(data)} registros[/]")


@cli.command()
@click.argument("file", type=click.Path(exists=True))
@click.option("--format", "-f", default="flutter",
              type=click.Choice(["flutter", "csv"]),
              help="Formato de exportacion")
@click.option("--output", "-o", default=None, help="Archivo de salida")
def export(file: str, format: str, output: str):
    """Exportar transacciones a formato Flutter o CSV."""
    with open(file, "r", encoding="utf-8") as f:
        data = json.load(f)

    if format == "flutter":
        # Formato compatible con Drift/SQLite de la app
        flutter_data = []
        for tx in data:
            flutter_data.append({
                "id": tx.get("id"),
                "accountId": tx.get("account_id"),
                "amount": tx.get("amount"),
                "description": tx.get("description"),
                "category": tx.get("category"),
                "type": tx.get("type"),
                "date": tx.get("date"),
                "isSynced": False,
                "createdAt": tx.get("created_at"),
            })

        output_file = output or str(OUTPUT_DIR / "flutter_import.json")
        with open(output_file, "w", encoding="utf-8") as f:
            json.dump(flutter_data, f, indent=2, ensure_ascii=False, default=str)
    else:
        import pandas as pd
        df = pd.DataFrame(data)
        output_file = output or str(OUTPUT_DIR / "export.csv")
        df.to_csv(output_file, index=False)

    console.print(f"[bold green]✓ Exportado a {output_file}[/]")


@cli.command()
def info():
    """Mostrar informacion de archivos disponibles."""
    table = Table(title="Archivos en output/")
    table.add_column("Archivo", style="cyan")
    table.add_column("Tamano", style="green", justify="right")
    table.add_column("Registros", style="yellow", justify="right")

    for file in OUTPUT_DIR.glob("*.json"):
        size = file.stat().st_size
        size_str = f"{size / 1024:.1f} KB" if size > 1024 else f"{size} B"

        try:
            with open(file, "r") as f:
                data = json.load(f)
                count = len(data) if isinstance(data, list) else 1
        except:
            count = "?"

        table.add_row(file.name, size_str, str(count))

    console.print(table)


def _show_summary(transactions: list):
    """Mostrar resumen de transacciones generadas."""
    income = sum(tx["amount"] for tx in transactions if tx["type"] == "income")
    expense = sum(tx["amount"] for tx in transactions if tx["type"] == "expense")

    table = Table(title="Resumen")
    table.add_column("Metrica", style="cyan")
    table.add_column("Valor", style="green", justify="right")

    table.add_row("Total transacciones", str(len(transactions)))
    table.add_row("Ingresos", f"${income:,.0f} COP")
    table.add_row("Gastos", f"${abs(expense):,.0f} COP")
    table.add_row("Balance", f"${income + expense:,.0f} COP")

    console.print(table)


if __name__ == "__main__":
    cli()
