"""Actualiza referencias ShopDemo.slnx tras moverlo a Source/."""
from __future__ import annotations

import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
EXTENSIONS = {".md", ".yml", ".yaml", ".ps1", ".py", ".mdc", ".json", ".slnx", ".html", ".sh"}
SKIP_DIRS = {"node_modules", "bin", "obj", ".vs", ".git"}


def fix_text(text: str) -> str:
    pairs = [
        ("dotnet build ShopDemo.slnx", "dotnet build Source/ShopDemo.slnx"),
        ("dotnet restore ShopDemo.slnx", "dotnet restore Source/ShopDemo.slnx"),
        ("dotnet clean ShopDemo.slnx", "dotnet clean Source/ShopDemo.slnx"),
        ("dotnet test ShopDemo.slnx", "dotnet test Source/ShopDemo.slnx"),
        ("dotnet format ShopDemo.slnx", "dotnet format Source/ShopDemo.slnx"),
        ("dotnet sln ShopDemo.slnx", "dotnet sln Source/ShopDemo.slnx"),
        ("Join-Path $RepoRoot 'ShopDemo.slnx'", "Join-Path $RepoRoot 'Source/ShopDemo.slnx'"),
        ("`ShopDemo.slnx` permanece en la raíz", "`ShopDemo.slnx` vive en `Source/`"),
        ("La solución (`ShopDemo.slnx`) permanece en la raíz", "La solución (`Source/ShopDemo.slnx`) vive en `Source/`"),
        ("Solution file: `ShopDemo.slnx`", "Solution file: `Source/ShopDemo.slnx`"),
        ("En `ShopDemo.slnx`, carpeta `/Source/Catalog/`", "En `Source/ShopDemo.slnx`, carpeta `/Catalog/`"),
        ("En `ShopDemo.slnx`, agrega carpeta `/Source/Orders/`", "En `Source/ShopDemo.slnx`, agrega carpeta `/Orders/`"),
        ("En `ShopDemo.slnx`, añadir la carpeta `/Source/Inventory/`", "En `Source/ShopDemo.slnx`, añadir la carpeta `/Inventory/`"),
        ("Agregar carpeta `/Source/Aspire/` en `ShopDemo.slnx`", "Agregar carpeta `/Aspire/` en `Source/ShopDemo.slnx`"),
        ("Agregar el proyecto a `ShopDemo.slnx` en carpeta `/Source/AI/`", "Agregar el proyecto a `Source/ShopDemo.slnx` en carpeta `/AI/`"),
        ('<Folder Name="/Source/Aspire/">', '<Folder Name="/Aspire/">'),
        ('<Folder Name="/Source/Catalog/">', '<Folder Name="/Catalog/">'),
        ('<Folder Name="/Source/Orders/">', '<Folder Name="/Orders/">'),
        ('<Folder Name="/Source/Inventory/">', '<Folder Name="/Inventory/">'),
        ('<Folder Name="/Source/AI/">', '<Folder Name="/AI/">'),
        ("Carpeta `/Source/Aspire/` en `ShopDemo.slnx`", "Carpeta `/Aspire/` en `Source/ShopDemo.slnx`"),
        ("carpeta `/Source/Aspire/` en `ShopDemo.slnx`", "carpeta `/Aspire/` en `Source/ShopDemo.slnx`"),
        ("La solución (`ShopDemo.slnx`)", "La solución (`Source/ShopDemo.slnx`)"),
        ("en `ShopDemo.slnx`", "en `Source/ShopDemo.slnx`"),
        ("`ShopDemo.slnx`", "`Source/ShopDemo.slnx`"),
    ]
    for old, new in pairs:
        text = text.replace(old, new)
    # Evitar doble prefijo si el script se ejecuta dos veces
    while "Source/Source/ShopDemo.slnx" in text:
        text = text.replace("Source/Source/ShopDemo.slnx", "Source/ShopDemo.slnx")
    return text


def main() -> None:
    changed = 0
    for path in REPO_ROOT.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix not in EXTENSIONS:
            continue
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        if path.name == "Update-RepoPathsForSlnx.py":
            continue
        original = path.read_text(encoding="utf-8")
        updated = fix_text(original)
        if updated != original:
            path.write_text(updated, encoding="utf-8", newline="\n")
            changed += 1
            print(f"Updated: {path}")
    print(f"Files changed: {changed}")


if __name__ == "__main__":
    main()
