# Spec-driven development — ShopDemo

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |

Estructura versionada para desarrollo guiado por especificaciones con **Cursor** y **Claude Code**.

## Documentación del curso

| Tipo | Enlace |
|---|---|
| Teoría | [TEORIA-SPEC-DRIVEN-DEVELOPMENT.md](./TEORIA-SPEC-DRIVEN-DEVELOPMENT.md) |
| Requerimientos | [REQUERIMIENTOS-SPEC-DRIVEN-DEVELOPMENT.md](./REQUERIMIENTOS-SPEC-DRIVEN-DEVELOPMENT.md) |
| Implementación (activar) | [IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md](./IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md) |

## Carpetas

```
spec-driven/
├── specs/              # Especificaciones compartidas (todas las áreas del curso)
├── cursor/             # Plantillas Cursor (rules, skills, AGENTS.md, MCP)
└── claude-code/        # Plantillas Claude Code (.claude/, CLAUDE.md, MCP)
```

## Inicio rápido

1. Leer [IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md](./IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md)
2. Copiar plantillas de `cursor/templates/` → `.cursor/` y `AGENTS.md` en raíz (Cursor)
3. Copiar plantillas de `claude-code/templates/` → raíz del repo (Claude Code)
4. Trabajar siempre contra un archivo en `spec-driven/specs/<área>/SPEC.md`

## Idioma

| Contenido | Idioma |
|---|---|
| Docs curso (TEORIA, REQUERIMIENTOS, specs) | Español |
| Rules, commands, AGENTS.md, CLAUDE.md (técnico) | Inglés |
