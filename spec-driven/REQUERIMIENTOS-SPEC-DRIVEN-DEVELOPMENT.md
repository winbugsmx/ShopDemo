# Requerimientos — Spec-driven development (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |

**Versión:** 1.0

---

## 1. Propósito

Estandarizar cómo alumnos e instructores usan **Cursor** y **Claude Code** sobre ShopDemo: reglas, specs, comandos de despliegue Azure/AWS y plantilla MCP sin perder el hilo de los 14+ módulos del curso.

---

## 2. Objetivos

| ID | Objetivo |
|---|---|
| OBJ-SDD-01 | Carpeta `spec-driven/` versionada con specs de **toda** la solución |
| OBJ-SDD-02 | Plantillas **Cursor** (`cursor/templates/`) |
| OBJ-SDD-03 | Plantillas **Claude Code** (`claude-code/templates/`) |
| OBJ-SDD-04 | Commands/skills separados **deploy-azure** y **deploy-aws** |
| OBJ-SDD-05 | Plantilla `.mcp.json` con perfiles local / Azure / AWS |
| OBJ-SDD-06 | Idioma mixto: docs curso ES, rules técnicas EN |

---

## 3. Criterios de aceptación

| # | Criterio |
|---|---|
| CA-SDD-01 | 13 specs en `spec-driven/specs/` con enlaces a `docs/` |
| CA-SDD-02 | Alumno activa Cursor copiando templates sin errores (guía paso a paso) |
| CA-SDD-03 | Alumno activa Claude Code con `CLAUDE.md` + `.claude/` |
| CA-SDD-04 | MCP template documenta 3 entornos |
| CA-SDD-05 | Archivos locales (`*.local.*`) en `.gitignore` |

---

## Referencias

- [TEORIA-SPEC-DRIVEN-DEVELOPMENT.md](./TEORIA-SPEC-DRIVEN-DEVELOPMENT.md)
- [IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md](./IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md)
