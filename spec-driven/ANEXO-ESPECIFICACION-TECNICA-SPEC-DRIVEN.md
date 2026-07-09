# Anexo — Especificación técnica: Spec-driven (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | B — Especificación técnica |

---

## 1. Estructura de carpetas

```
spec-driven/
├── specs/              # 13 SPEC.md por área del curso
├── cursor/templates/   # rules, skills, AGENTS.md, MCP
└── claude-code/templates/  # .claude/, CLAUDE.md, MCP
```

---

## 2. Specs por módulo

| Carpeta | Enlace a docs/ |
|---|---|
| `00-vision` | Visión E2E |
| `01-catalog` … `12-mcp-gateway` | Módulos 1–14 del curso |

Índice: [specs/README.md](./specs/README.md)

---

## 3. Plantillas Cursor

| Artefacto | Ruta origen |
|---|---|
| Rules | `cursor/templates/.cursor/rules/` |
| Skills | `cursor/templates/skills/` |
| AGENTS.md | `cursor/templates/AGENTS.md` |
| MCP | `cursor/templates/.mcp.json` |

---

## 4. Plantillas Claude Code

| Artefacto | Ruta origen |
|---|---|
| CLAUDE.md | `claude-code/templates/CLAUDE.md` |
| Commands | `claude-code/templates/.claude/commands/` |
| Skills | `claude-code/templates/.claude/skills/` |

---

## 5. Commands deploy separados

| Command | Nube |
|---|---|
| `deploy-azure` | ACA / AKS |
| `deploy-aws` | ECS / EKS |

---

## 6. Criterios técnicos (CA-T)

| ID | Criterio |
|---|---|
| CA-T-SDD-01 | Cada SPEC.md referencia REQUERIMIENTOS + ANEXO-TECNICO del módulo |
| CA-T-SDD-02 | `AGENTS.md` raíz indica leer SPEC antes de implementar |
| CA-T-SDD-03 | Rules en inglés; docs curso en español |
| CA-T-SDD-04 | `.gitignore` incluye `*.local.*`, `mcp.json` local |

---

## 7. Flujo de trabajo agente

```
REQUERIMIENTOS (negocio) → SPEC.md → ANEXO-TECNICO → IMPLEMENTACION
```

Prompt recomendado: ver [specs/README.md](./specs/README.md).
