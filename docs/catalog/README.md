# Microservicio Catalog — Documentación ShopDemo

| Campo | Detalle |
|:------|:--------|
| **Módulo** | Catalog — catálogo de productos |
| **Arquitectura** | Clean Architecture + DDD + CQRS |

---

## Documentos (3 capas)

| Capa | Documento | Audiencia |
|---|---|---|
| **A — Negocio** | [REQUERIMIENTOS-CATALOG.md](./REQUERIMIENTOS-CATALOG.md) | PM, analista, negocio |
| **A — Negocio** | [HISTORIAS-USUARIO-CATALOG.md](./HISTORIAS-USUARIO-CATALOG.md) | Igual |
| **B — Técnica** | [ANEXO-ESPECIFICACION-TECNICA-CATALOG.md](./ANEXO-ESPECIFICACION-TECNICA-CATALOG.md) | Desarrollador |
| **B — Técnica** | [ANEXO-HISTORIAS-TECNICAS-CATALOG.md](./ANEXO-HISTORIAS-TECNICAS-CATALOG.md) | Desarrollador |
| **C — Pedagogía** | [ANEXO-PEDAGOGIA-CATALOG.md](./ANEXO-PEDAGOGIA-CATALOG.md) | Instructor / alumno |

**Guía de estructura:** [GUIA-ESTRUCTURA-DOCUMENTACION.md](../GUIA-ESTRUCTURA-DOCUMENTACION.md)

---

## Orden de lectura

### Negocio o junior sin contexto técnico

1. REQUERIMIENTOS → sección *Resumen en lenguaje llano*
2. HISTORIAS-USUARIO

### Desarrollador que implementa

1. REQUERIMIENTOS (negocio)
2. HISTORIAS-USUARIO
3. ANEXO-ESPECIFICACION-TECNICA
4. ANEXO-HISTORIAS-TECNICAS
5. [IMPLEMENTACION-CATALOG.md](./IMPLEMENTACION-CATALOG.md)
6. ANEXO-PEDAGOGIA (si eres alumno)

---

## Otros recursos

| Documento | Uso |
|---|---|
| [IMPLEMENTACION-CATALOG.md](./IMPLEMENTACION-CATALOG.md) | Guía paso a paso con código |
| [ANEXO-CODIGO-CATALOG.md](./ANEXO-CODIGO-CATALOG.md) | Fragmentos de referencia |

## Tópicos de Estudio relacionados

| # | Tópico | Enlace |
|---|---|---|
| 01 | Patrones de diseño | [01-patrones-diseno.md](../teoria-entrevistas/01-patrones-diseno.md) |
| 02 | Arquitecturas (Clean, Hexagonal) | [02-arquitecturas-software.md](../teoria-entrevistas/02-arquitecturas-software.md) |
| 03 | DDD | [03-ddd-domain-driven-design.md](../teoria-entrevistas/03-ddd-domain-driven-design.md) |

Índice completo: [teoria-entrevistas/README.md](../teoria-entrevistas/README.md)

---

## Relación con otros microservicios

```
Catalog (8001)  →  define productos
       ↓
Inventory (8003)  →  asigna stock
       ↓
Orders (8002)     →  crea pedidos
```

| Servicio | API | PostgreSQL (host) |
|---|---|---|
| **Catalog** | **8001** | **5433** |
| Orders | 8002 | 5434 |
| Inventory | 8003 | 5435 |
