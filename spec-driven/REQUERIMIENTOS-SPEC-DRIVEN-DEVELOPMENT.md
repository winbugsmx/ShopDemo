# Requerimientos — Desarrollo guiado por especificaciones (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Módulo** | Spec-driven development |
| **Versión** | 2.0 (enfoque negocio) |

**Documentos relacionados:**

| Capa | Documento |
|---|---|
| Historias de usuario | [HISTORIAS-USUARIO-SPEC-DRIVEN-DEVELOPMENT.md](./HISTORIAS-USUARIO-SPEC-DRIVEN-DEVELOPMENT.md) |
| Especificación técnica | [ANEXO-ESPECIFICACION-TECNICA-SPEC-DRIVEN.md](./ANEXO-ESPECIFICACION-TECNICA-SPEC-DRIVEN.md) |
| Historias técnicas | [ANEXO-HISTORIAS-TECNICAS-SPEC-DRIVEN.md](./ANEXO-HISTORIAS-TECNICAS-SPEC-DRIVEN.md) |
| Pedagogía (curso) | [ANEXO-PEDAGOGIA-SPEC-DRIVEN.md](./ANEXO-PEDAGOGIA-SPEC-DRIVEN.md) |

---

## Resumen en lenguaje llano

El equipo del proyecto ShopDemo necesita **una forma única y clara** de definir qué debe construirse en cada módulo, de modo que **personas y asistentes de IA** (Cursor, Claude Code) sigan las mismas reglas y no se desvíen del alcance del curso.

Esto implica tener especificaciones versionadas, plantillas reutilizables y criterios verificables de que la configuración está correcta.

---

## 1. Propósito

Establecer **qué debe lograr** el enfoque spec-driven en ShopDemo: alinear documentación de negocio, especificaciones para agentes y herramientas de desarrollo asistido.

---

## 2. Actores

| Actor | Rol |
|---|---|
| **Instructor** | Define y mantiene las especificaciones del curso |
| **Responsable de calidad** | Verifica que implementaciones cumplan las specs |
| **Equipo de desarrollo** | Implementa siguiendo specs y documentación de negocio |

---

## 3. Objetivos operativos

| ID | Objetivo |
|---|---|
| OBJ-SDD-01 | Toda la solución tiene especificaciones versionadas y enlazadas a la documentación de negocio |
| OBJ-SDD-02 | Las herramientas de IA del curso usan las mismas reglas y alcance en todos los módulos |
| OBJ-SDD-03 | Los despliegues en Azure y AWS tienen instrucciones separadas y sin ambigüedad |
| OBJ-SDD-04 | Los secretos locales no se publican en el repositorio |

---

## 4. Requerimientos de negocio

| ID | Requerimiento |
|---|---|
| RF-SDD-01 | Cada módulo del curso tiene una especificación consultable por el equipo |
| RF-SDD-02 | Un agente o desarrollador puede activar Cursor sin errores siguiendo la guía |
| RF-SDD-03 | Un agente o desarrollador puede activar Claude Code con la configuración del curso |
| RF-SDD-04 | El gateway MCP documenta perfiles para entorno local, Azure y AWS |
| RF-SDD-05 | La documentación del curso permanece en español; reglas técnicas de herramientas en inglés |

---

## 5. Criterios de aceptación de negocio (CA-N)

| ID | Criterio |
|---|---|
| CA-N-SDD-01 | Las 13 áreas del curso tienen spec enlazada a su documentación en `docs/` |
| CA-N-SDD-02 | Un miembro del equipo activa Cursor copiando plantillas sin pasos ambiguos |
| CA-N-SDD-03 | Un miembro del equipo activa Claude Code con `CLAUDE.md` y configuración operativa |
| CA-N-SDD-04 | La plantilla MCP describe tres entornos (local, Azure, AWS) |
| CA-N-SDD-05 | Archivos locales sensibles no se versionan en git |

---

## 6. Referencias

- [GUIA-ESTRUCTURA-DOCUMENTACION.md](../docs/GUIA-ESTRUCTURA-DOCUMENTACION.md)
- [specs/README.md](./specs/README.md)
- [IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md](./IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md)
