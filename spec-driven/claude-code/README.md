# Claude Code — plantillas ShopDemo

Plantillas para **spec-driven development** con [Claude Code](https://docs.anthropic.com/en/docs/claude-code), alineadas con la estructura de la imagen de referencia del curso.

## Estructura de plantillas

```
templates/
├── CLAUDE.md
├── CLAUDE.local.md.template
├── mcp.template.json
└── .claude/
    ├── settings.json
    ├── settings.local.json.template
    ├── rules/
    ├── commands/
    ├── skills/
    ├── agents/
    └── hooks/
```

## Activación (resumen)

Desde la **raíz del repo**:

```powershell
# Instrucciones principales
Copy-Item spec-driven\claude-code\templates\CLAUDE.md .

# Overrides locales (no commitear)
Copy-Item spec-driven\claude-code\templates\CLAUDE.local.md.template CLAUDE.local.md

# MCP (rellenar URLs Azure/AWS)
Copy-Item spec-driven\claude-code\templates\mcp.template.json .mcp.json

# Carpeta .claude completa
Copy-Item -Recurse spec-driven\claude-code\templates\.claude .claude
Copy-Item spec-driven\claude-code\templates\.claude\settings.local.json.template .claude\settings.local.json
```

Guía detallada: [IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md](../IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md) — sección Claude Code.

## Comandos slash

| Comando | Uso |
|---|---|
| `/implement-spec` | Implementar desde un SPEC |
| `/deploy-azure` | Solo Azure |
| `/deploy-aws` | Solo AWS |
| `/review` | Revisión de cambios |
| `/run-e2e` | Checklist Postman |
| `/fix-issue` | Bug con flujo spec-first |

## Paridad con Cursor

| Cursor | Claude Code |
|---|---|
| `AGENTS.md` | `CLAUDE.md` |
| `.cursor/rules/*.mdc` | `.claude/rules/*.md` |
| `.cursor/skills/` | `.claude/skills/` |
| User rules / MCP en IDE | `.mcp.json` + `settings.json` |

Specs compartidos: `spec-driven/specs/`

**Tópicos de Estudio:** [teoria-entrevistas/README.md](../../docs/teoria-entrevistas/README.md)
