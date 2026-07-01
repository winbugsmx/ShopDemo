# Historias de Usuario — Spec-driven Development (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-SPEC-DRIVEN-DEVELOPMENT.md](../../spec-driven/REQUERIMIENTOS-SPEC-DRIVEN-DEVELOPMENT.md) |

---

## HU-SDD-01 — Specs versionadas por módulo

| **Objetivo** | OBJ-SDD-01 |

**Como** instructor, **quiero** specs en `spec-driven/specs/` enlazadas a `docs/`, **para** que agentes IA sigan el mismo alcance del curso.

**Modelo:** Archivos SPEC.md (**N/A** código dominio).

**Criterios (CA-SDD-01):** 13 specs con enlaces válidos.

---

## HU-SDD-02 — Activar Cursor con plantillas

| **Objetivo** | OBJ-SDD-02 |

**Como** alumno, **quiero** copiar templates Cursor, **para** usar reglas y commands del curso.

**Criterios (CA-SDD-02):** Activación sin errores según guía.

---

## HU-SDD-03 — Activar Claude Code

| **Objetivo** | OBJ-SDD-03 |

**Criterios (CA-SDD-03):** `CLAUDE.md` + `.claude/` operativos.

---

## HU-SDD-04 — Commands deploy Azure/AWS

| **Objetivo** | OBJ-SDD-04 |

**Como** alumno, **quiero** commands separados por nube, **para** no mezclar instrucciones ACA y ECS.

**Modelo:** Skills/commands en carpetas templates.

---

## HU-SDD-05 — Perfiles MCP multientorno

| **Objetivo** | OBJ-SDD-05 |

**Criterios (CA-SDD-04):** `.mcp.json` template documenta local, Azure, AWS.

---

## HU-SDD-06 — Secretos locales fuera de git

| **Objetivo** | (implícito) |

**Criterios (CA-SDD-05):** `*.local.*` en `.gitignore`.
