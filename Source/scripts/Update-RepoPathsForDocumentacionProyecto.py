"""Actualiza rutas Documentación del Proyecto/ -> Documentación del Proyecto/ preservando Estudio del Curso."""
from __future__ import annotations

from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
ESTUDIO = "Documentación de Estudio del Curso"
PLACEHOLDER = "Documentación de Estudio del Curso"
NEW_FOLDER = "Documentación del Proyecto"
EXTENSIONS = {".md", ".yml", ".yaml", ".ps1", ".py", ".mdc", ".json", ".slnx", ".html", ".env.example"}
SKIP_DIRS = {"node_modules", "bin", "obj", ".vs", ".git"}


def fix_text(text: str) -> str:
    text = text.replace(ESTUDIO, PLACEHOLDER)
    pairs = [
        ("../../../../Documentación del Proyecto/", f"../../../../{NEW_FOLDER}/"),
        ("../../../Documentación del Proyecto/", f"../../../{NEW_FOLDER}/"),
        ("../../Documentación del Proyecto/", f"../../{NEW_FOLDER}/"),
        ("../Documentación del Proyecto/", f"../{NEW_FOLDER}/"),
        ("Documentación del Proyecto/", f"{NEW_FOLDER}/"),
        ("..\\..\\..\\..\\Documentación del Proyecto\\", f"..\\..\\..\\..\\{NEW_FOLDER}\\"),
        ("..\\..\\..\\Documentación del Proyecto\\", f"..\\..\\..\\{NEW_FOLDER}\\"),
        ("..\\..\\Documentación del Proyecto\\", f"..\\..\\{NEW_FOLDER}\\"),
        ("..\\Documentación del Proyecto\\", f"..\\{NEW_FOLDER}\\"),
        ("\\Documentación del Proyecto\\", f"\\{NEW_FOLDER}\\"),
        (r"I:\Curso\ShopDemo\Documentación del Proyecto\\", rf"I:\Curso\ShopDemo\{NEW_FOLDER}\\"),
        (r"I:\Curso\ShopDemo\Documentación del Proyecto/", rf"I:\Curso\ShopDemo/{NEW_FOLDER}/"),
        ("ShopDemo\\Documentación del Proyecto\\", f"ShopDemo\\{NEW_FOLDER}\\"),
        ("ShopDemo/Documentación del Proyecto/", f"ShopDemo/{NEW_FOLDER}/"),
        ('REPO_ROOT / "Documentación del Proyecto"', f'REPO_ROOT / "{NEW_FOLDER}"'),
        ("REPO_ROOT / 'Documentación del Proyecto'", f"REPO_ROOT / '{NEW_FOLDER}'"),
        ("Documentación del Proyecto/", f"{NEW_FOLDER}/"),
        ("Documentación del Proyecto\\", f"{NEW_FOLDER}\\"),
    ]
    for old, new in pairs:
        text = text.replace(old, new)
    text = text.replace(PLACEHOLDER, ESTUDIO)
    while f"{NEW_FOLDER}/{NEW_FOLDER}/" in text:
        text = text.replace(f"{NEW_FOLDER}/{NEW_FOLDER}/", f"{NEW_FOLDER}/")
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
        original = path.read_text(encoding="utf-8")
        updated = fix_text(original)
        if updated != original:
            path.write_text(updated, encoding="utf-8", newline="\n")
            changed += 1
            print(f"Updated: {path}")
    print(f"Files changed: {changed}")


if __name__ == "__main__":
    main()
