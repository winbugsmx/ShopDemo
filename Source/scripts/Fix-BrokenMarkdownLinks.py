"""Repara enlaces markdown rotos calculando rutas relativas correctas."""
from __future__ import annotations

import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
LINK_RE = re.compile(r"\[([^\]]*)\]\(([^)]+)\)")
SKIP_SCHEMES = ("http://", "https://", "mailto:", "#", "mermaid://")
SKIP_DIRS = {"node_modules", "bin", "obj", ".vs", ".git"}
SKIP_TARGETS = {"ruta.png", "png", "./assets/images/diagrams/....png"}


def should_skip_target(target: str) -> bool:
    t = target.strip()
    if not t or t.startswith(SKIP_SCHEMES) or t in SKIP_TARGETS:
        return True
    if t.startswith("<") and t.endswith(">"):
        return True
    return False


def resolve_link(source: Path, target: str) -> Path | None:
    t = target.strip().split("#", 1)[0].strip()
    if not t:
        return None
    if t.startswith("/"):
        candidate = REPO_ROOT / t.lstrip("/")
    else:
        candidate = (source.parent / t).resolve()
    try:
        candidate.relative_to(REPO_ROOT)
    except ValueError:
        return None
    return candidate


def find_target(source: Path, target: str) -> Path | None:
    raw = target.strip()
    fragment = ""
    if "#" in raw:
        raw, fragment = raw.split("#", 1)
        fragment = "#" + fragment

    raw_path = raw.strip()
    if not raw_path:
        return None

    # Directorio explícito
    if raw_path.endswith("/"):
        name = raw_path.rstrip("/").replace("\\", "/").split("/")[-1]
        for candidate in [REPO_ROOT / name, REPO_ROOT / raw_path.rstrip("/")]:
            if candidate.exists() and candidate.is_dir():
                rel = Path(os_relpath(source.parent, candidate)).as_posix()
                if rel == ".":
                    return candidate
                return candidate  # devolvemos path dir; rel se calcula después
        return None

    # Buscar por sufijo de ruta o nombre de archivo
    norm = raw_path.replace("\\", "/").lstrip("./")
    matches: list[Path] = []
    for p in REPO_ROOT.rglob("*"):
        if any(part in SKIP_DIRS for part in p.parts):
            continue
        if p.is_file():
            posix = p.relative_to(REPO_ROOT).as_posix()
            if posix.endswith(norm) or p.name == Path(norm).name:
                matches.append(p)

    if not matches:
        return None
    if len(matches) == 1:
        return matches[0]

    # Preferir misma carpeta top-level esperada
    prefer = []
    for m in matches:
        if "Documentación_Del_Proyecto" in str(m) and "Documentación_Del_Proyecto" in str(source):
            prefer.append(m)
        elif "Documentación_De_Estudio_Del_Curso" in str(m) and "Documentación_De_Estudio_Del_Curso" in str(source):
            prefer.append(m)
    matches = prefer or matches
    return sorted(matches, key=lambda x: len(str(x)))[0]


def os_relpath(from_dir: Path, to_path: Path) -> str:
    rel = Path(
        *[
            ".."
            for _ in range(len(from_dir.relative_to(REPO_ROOT).parts))
        ]
    )  # fallback no usado
    try:
        rel = Path(
            __import__("os").path.relpath(to_path, from_dir)
        )
    except Exception:
        pass
    return rel.as_posix()


def relpath_link(source: Path, target_path: Path, fragment: str = "") -> str:
    rel = Path(__import__("os").path.relpath(target_path, source.parent)).as_posix()
    return rel + fragment


def scan_and_fix(dry_run: bool = False) -> tuple[int, int]:
    fixed_links = 0
    fixed_files = 0

    for md in sorted(REPO_ROOT.rglob("*.md")):
        if any(part in SKIP_DIRS for part in md.parts):
            continue

        text = md.read_text(encoding="utf-8")
        new_text = text
        file_changes = 0

        for match in list(LINK_RE.finditer(text)):
            label, target = match.group(1), match.group(2)
            if should_skip_target(target):
                continue

            resolved = resolve_link(md, target)
            if resolved and resolved.exists():
                continue

            fragment = ""
            raw = target.strip()
            if "#" in raw:
                raw, fragment = raw.split("#", 1)
                fragment = "#" + fragment

            found = find_target(md, raw)
            if not found:
                continue

            new_target = relpath_link(md, found, fragment)
            if new_target == target:
                continue

            old = f"[{label}]({target})"
            new = f"[{label}]({new_target})"
            if old in new_text:
                new_text = new_text.replace(old, new, 1)
                file_changes += 1
                fixed_links += 1

        if file_changes and new_text != text:
            if not dry_run:
                md.write_text(new_text, encoding="utf-8", newline="\n")
            fixed_files += 1
            print(f"Fixed {file_changes} links in {md.relative_to(REPO_ROOT)}")

    return fixed_files, fixed_links


def apply_manual_fixes() -> None:
    pairs: list[tuple[str, str, str]] = [
        # path, old, new
        (
            "Source/scripts/aws/README.md",
            "../../Documentación_Del_Proyecto/",
            "../../../Documentación_Del_Proyecto/",
        ),
        (
            "Source/scripts/aws/README.md",
            "../../Documentación_De_Estudio_Del_Curso/",
            "../../../Documentación_De_Estudio_Del_Curso/",
        ),
        (
            "Source/scripts/aws/README.md",
            "../../.github/",
            "../../../.github/",
        ),
        (
            "Source/scripts/aws/README.md",
            "../../README.md",
            "../../../README.md",
        ),
        (
            "Source/scripts/azure/README.md",
            "../../Documentación_Del_Proyecto/",
            "../../../Documentación_Del_Proyecto/",
        ),
        (
            "Source/scripts/azure/README.md",
            "../../Documentación_De_Estudio_Del_Curso/",
            "../../../Documentación_De_Estudio_Del_Curso/",
        ),
        (
            "Source/scripts/azure/README.md",
            "../../.github/",
            "../../../.github/",
        ),
        (
            "Source/AI/README.md",
            "../Documentación_Del_Proyecto/",
            "../../Documentación_Del_Proyecto/",
        ),
        (
            "Source/AI/README.md",
            "../Documentación_De_Estudio_Del_Curso/",
            "../../Documentación_De_Estudio_Del_Curso/",
        ),
        (
            "Documentación_Del_Proyecto/ANEXO-CODIGO-EVENT-HUBS.md",
            "](../GUIA-DESARROLLO-INTEGRACIONES.md)",
            "](GUIA-DESARROLLO-INTEGRACIONES.md)",
        ),
        (
            "Documentación_Del_Proyecto/INTEGRACION-AZURE-EVENT-HUBS.md",
            "](../GUIA-DESARROLLO-INTEGRACIONES.md)",
            "](GUIA-DESARROLLO-INTEGRACIONES.md)",
        ),
        (
            "Documentación_Del_Proyecto/observabilidad/azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md",
            "](../despliegue/",
            "](../../despliegue/",
        ),
        (
            "Documentación_Del_Proyecto/resiliencia/azure/IMPLEMENTACION-RESILIENCIA-AZURE.md",
            "](../observabilidad/",
            "](../../observabilidad/",
        ),
        (
            "Documentación_Del_Proyecto/despliegue/azure/TEORIA-CONTENEDORES-AZURE.md",
            "](../INTEGRACION-AZURE-EVENT-HUBS.md)",
            "](../../INTEGRACION-AZURE-EVENT-HUBS.md)",
        ),
        (
            "Documentación_Del_Proyecto/despliegue/kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md",
            "](../GUIA-DESARROLLO-INTEGRACIONES.md)",
            "](../../GUIA-DESARROLLO-INTEGRACIONES.md)",
        ),
        (
            "Documentación_Del_Proyecto/despliegue/kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md",
            "](../../k8s/",
            "](../../../k8s/",
        ),
        (
            "Documentación_Del_Proyecto/integracion-ia/IMPLEMENTACION-MCP-GATEWAY.md",
            "](../spec-driven/",
            "](../../../spec-driven/",
        ),
        (
            "Documentación_Del_Proyecto/ARQUITECTURA.md",
            "](../spec-driven/",
            "](../../spec-driven/",
        ),
        (
            "Documentación_Del_Proyecto/GUIA-ENDPOINTS.md",
            "](../spec-driven/",
            "](../../spec-driven/",
        ),
        (
            "Documentación_De_Estudio_Del_Curso/assets/RECURSOS-GRAFICOS.md",
            "](./assets/images/diagrams/",
            "](./images/diagrams/",
        ),
        (
            "Documentación_De_Estudio_Del_Curso/assets/RECURSOS-GRAFICOS.md",
            "](./assets/diagrams/",
            "](./diagrams/",
        ),
    ]

    for rel, old, new in pairs:
        path = REPO_ROOT / rel.replace("/", "\\")
        if not path.exists():
            continue
        content = path.read_text(encoding="utf-8")
        if old in content:
            path.write_text(content.replace(old, new), encoding="utf-8", newline="\n")
            print(f"Manual fix: {rel}")


def main() -> None:
    apply_manual_fixes()
    files, links = scan_and_fix(dry_run=False)
    print(f"Auto-fixed {links} links in {files} files")

    # Rescan
    import subprocess

    subprocess.run(
        [__import__("sys").executable, str(REPO_ROOT / "Source/scripts/Scan-BrokenMarkdownLinks.py")],
        check=False,
    )


if __name__ == "__main__":
    main()
