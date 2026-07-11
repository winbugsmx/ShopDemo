"""Actualiza rutas Documentación_Del_Proyecto -> Documentación_Del_Proyecto."""
from __future__ import annotations

from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
OLD = "Documentación_Del_Proyecto"
NEW = "Documentación_Del_Proyecto"
EXTENSIONS = {".md", ".yml", ".yaml", ".ps1", ".py", ".mdc", ".json", ".slnx", ".html", ".sh", ".env.example"}
SKIP_DIRS = {"node_modules", "bin", "obj", ".vs", ".git"}


def fix_text(text: str) -> str:
    pairs = [
        (f"../../../../{OLD}/", f"../../../../{NEW}/"),
        (f"../../../{OLD}/", f"../../../{NEW}/"),
        (f"../../{OLD}/", f"../../{NEW}/"),
        (f"../{OLD}/", f"../{NEW}/"),
        (f"{OLD}/", f"{NEW}/"),
        (f"..\\..\\..\\..\\{OLD}\\", f"..\\..\\..\\..\\{NEW}\\"),
        (f"..\\..\\..\\{OLD}\\", f"..\\..\\..\\{NEW}\\"),
        (f"..\\..\\{OLD}\\", f"..\\..\\{NEW}\\"),
        (f"..\\{OLD}\\", f"..\\{NEW}\\"),
        (f"\\{OLD}\\", f"\\{NEW}\\"),
        ("I:\\Curso\\ShopDemo\\" + OLD + "\\", "I:\\Curso\\ShopDemo\\" + NEW + "\\"),
        ("I:\\Curso\\ShopDemo\\" + OLD + "/", "I:\\Curso\\ShopDemo/" + NEW + "/"),
        ("ShopDemo\\" + OLD + "\\", "ShopDemo\\" + NEW + "\\"),
        ("ShopDemo/" + OLD + "/", "ShopDemo/" + NEW + "/"),
        (f"| `{OLD}/` |", f"| `{NEW}/` |"),
        (f"├── {OLD}/", f"├── {NEW}/"),
        ('REPO_ROOT / "' + OLD + '"', 'REPO_ROOT / "' + NEW + '"'),
        ("Join-Path $RepoRoot '" + OLD + "'", "Join-Path $RepoRoot '" + NEW + "'"),
        ("(Join-Path $RepoRoot '" + OLD + "')", "(Join-Path $RepoRoot '" + NEW + "')"),
        (OLD, NEW),
    ]
    for old, new in pairs:
        text = text.replace(old, new)
    while f"{NEW}/{NEW}/" in text:
        text = text.replace(f"{NEW}/{NEW}/", f"{NEW}/")
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
            print(f"Updated: {path.relative_to(REPO_ROOT)}")
    print(f"Files changed: {changed}")


if __name__ == "__main__":
    main()
