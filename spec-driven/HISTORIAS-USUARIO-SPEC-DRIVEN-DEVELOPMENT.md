# Historias de Usuario — Spec-driven Development (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Requerimientos** | [REQUERIMIENTOS-SPEC-DRIVEN-DEVELOPMENT.md](./REQUERIMIENTOS-SPEC-DRIVEN-DEVELOPMENT.md) |
| **Historias técnicas** | [ANEXO-HISTORIAS-TECNICAS-SPEC-DRIVEN.md](./ANEXO-HISTORIAS-TECNICAS-SPEC-DRIVEN.md) |

---

## HU-SDD-01 — Especificaciones alineadas al curso

| **Objetivo** | OBJ-SDD-01 · **RF** | RF-SDD-01 |

**Como** instructor, **quiero** que cada módulo tenga una especificación enlazada a su documentación de negocio, **para** que el equipo y los agentes IA trabajen con el mismo alcance.

### Criterios (CA-N)

- [ ] **CA-N-SDD-01:** 13 specs con enlaces válidos a `docs/`.

---

## HU-SDD-02 — Herramientas de IA configuradas

| **Objetivos** | OBJ-SDD-02, OBJ-SDD-03 |

**Como** responsable de calidad, **quiero** que Cursor y Claude Code se activen con plantillas del curso, **para** validar implementaciones de forma reproducible.

### Criterios (CA-N)

- [ ] **CA-N-SDD-02:** Activación de Cursor sin errores según guía.
- [ ] **CA-N-SDD-03:** Claude Code operativo con configuración del repositorio.

---

## HU-SDD-03 — MCP multientorno documentado

| **Objetivo** | OBJ-SDD-04 · **RF** | RF-SDD-04 |

**Como** responsable de integración, **quiero** perfiles MCP para local, Azure y AWS, **para** que agentes operen en el entorno correcto.

### Criterios (CA-N)

- [ ] **CA-N-SDD-04:** Plantilla documenta los tres entornos.

---

## HU-SDD-04 — Secretos fuera del repositorio

| **Objetivo** | OBJ-SDD-04 · **RF** | RF-SDD-05 (implícito) |

**Como** responsable de seguridad, **quiero** que credenciales locales no se suban a git, **para** proteger el laboratorio.

### Criterios (CA-N)

- [ ] **CA-N-SDD-05:** Patrones `*.local.*` excluidos en `.gitignore`.
