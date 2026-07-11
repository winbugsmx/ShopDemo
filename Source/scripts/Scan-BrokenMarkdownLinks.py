"""Detecta enlaces markdown rotos en el repositorio ShopDemo."""
from __future__ import annotations

import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
LINK_RE = re.compile(r"\[([^\]]*)\]\(([^)]+)\)")
SKIP_SCHEMES = ("http://", "https://", "mailto:", "#", "mermaid://")
SKIP_DIRS = {"node_modules", "bin", "obj", ".vs", ".git"}


def should_skip_target(target: str) -> bool:
    t = target.strip()
    if not t or t.startswith(SKIP_SCHEMES):
        return True
    if t.startswith("<") and t.endswith(">"):
        return True
    return False


def resolve_link(source: Path, target: str) -> Path | None:
    t = target.strip()
    if should_skip_target(t):
        return None

    t = t.split("#", 1)[0].strip()
    if not t:
        return None

    if t.startswith("/"):
        candidate = REPO_ROOT / t.lstrip("/").replace("/", "\\")
    else:
        candidate = (source.parent / t.replace("/", "\\")).resolve()

    try:
        candidate.relative_to(REPO_ROOT)
    except ValueError:
        return None
    return candidate


def exists_or_placeholder(path: Path) -> bool:
    if path.exists():
        return True
    # anclas a secciones de archivos existentes ya validados sin fragmento
    return False


def scan_file(path: Path) -> list[dict]:
    text = path.read_text(encoding="utf-8", errors="replace")
    issues = []
    for line_no, line in enumerate(text.splitlines(), 1):
        for match in LINK_RE.finditer(line):
            label, target = match.group(1), match.group(2)
            if should_skip_target(target):
                continue
            resolved = resolve_link(path, target)
            if resolved is None:
                continue
            if not exists_or_placeholder(resolved):
                issues.append(
                    {
                        "file": str(path.relative_to(REPO_ROOT)),
                        "line": line_no,
                        "label": label[:80],
                        "target": target,
                        "resolved": str(resolved.relative_to(REPO_ROOT)),
                    }
                )
    return issues


def main() -> None:
    all_issues: list[dict] = []
    for md in REPO_ROOT.rglob("*.md"):
        if any(part in SKIP_DIRS for part in md.parts):
            continue
        all_issues.extend(scan_file(md))

    # Agrupar por patrón de target
    patterns: dict[str, int] = {}
    for i in all_issues:
        t = i["target"]
        for old in (
            "docs/",
            "teoria-entrevistas",
            "DocumentaciÃ³n",
            "Documentación/teoria",
            "Documentación/Documentación",
            "../Documentación/",
            "../../Documentación/",
        ):
            if old in t:
                patterns[old] = patterns.get(old, 0) + 1
                break
        else:
            if t.startswith("Documentación/") and "del Proyecto" not in t and "de Estudio" not in t:
                patterns["Documentación/ (sin del Proyecto)"] = patterns.get("Documentación/ (sin del Proyecto)", 0) + 1

    print(f"TOTAL_BROKEN: {len(all_issues)}")
    print("PATTERNS:")
    for k, v in sorted(patterns.items(), key=lambda x: -x[1]):
        print(f"  {v:4d}  {k}")

    print("\nSAMPLE (first 60):")
    for i in all_issues[:60]:
        print(f"{i['file']}:{i['line']} -> {i['target']}")

    # Guardar reporte completo
    report = REPO_ROOT / "Source" / "scripts" / "broken-links-report.txt"
    lines = [f"{x['file']}:{x['line']}\t{x['target']}\t{x['resolved']}" for x in all_issues]
    report.write_text("\n".join(lines), encoding="utf-8")
    print(f"\nReport: {report}")


if __name__ == "__main__":
    main()
