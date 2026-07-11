# SPEC — Catalog (Clean Architecture + CQRS)

## Objetivo

Evolucionar el bounded context Catalog sin violar capas Domain → Application → Infrastructure → API.

## Documentación (3 capas)

| Capa | Documento |
|---|---|
| **A — Negocio** | [REQUERIMIENTOS-CATALOG.md](../../../Documentación_Del_Proyecto/catalog/REQUERIMIENTOS-CATALOG.md) |
| **A — Negocio** | [HISTORIAS-USUARIO-CATALOG.md](../../../Documentación_Del_Proyecto/catalog/HISTORIAS-USUARIO-CATALOG.md) |
| **B — Técnica** | [ANEXO-ESPECIFICACION-TECNICA-CATALOG.md](../../../Documentación_Del_Proyecto/catalog/ANEXO-ESPECIFICACION-TECNICA-CATALOG.md) |
| **B — Técnica** | [ANEXO-HISTORIAS-TECNICAS-CATALOG.md](../../../Documentación_Del_Proyecto/catalog/ANEXO-HISTORIAS-TECNICAS-CATALOG.md) |
| **C — Pedagogía** | [ANEXO-PEDAGOGIA-CATALOG.md](../../../Documentación_Del_Proyecto/catalog/ANEXO-PEDAGOGIA-CATALOG.md) |
| Implementación | [IMPLEMENTACION-CATALOG.md](../../../Documentación_Del_Proyecto/catalog/IMPLEMENTACION-CATALOG.md) |

Guía: [GUIA-ESTRUCTURA-DOCUMENTACION.md](../../../Documentación_Del_Proyecto/GUIA-ESTRUCTURA-DOCUMENTACION.md)

## Alcance (agente)

- Comandos/queries MediatR, validación FluentValidation
- EF Core + PostgreSQL
- Publicación domain events → Event Hubs (si habilitado)
- Código: `Source/Catalog/`

## Criterios de aceptación

### Negocio (CA-N)

- [ ] Registrar producto válido confirma alta con identificador único (CA-N01)
- [ ] Nombre duplicado rechazado con mensaje claro (CA-N02)
- [ ] Datos inválidos indican campo y motivo (CA-N03)

### Técnico (CA-T)

- [ ] Nuevo caso de uso sigue patrón `Commands/` o `Queries/`
- [ ] Sin referencias de Domain a Infrastructure (CA-T08)
- [ ] `POST /api/products` retorna `201` y persiste (CA-T01)

## Instrucciones para el agente

1. Leer **REQUERIMIENTOS** (negocio) para entender reglas RN-CAT-*.
2. Consultar **ANEXO-ESPECIFICACION-TECNICA** antes de codificar.
3. Usar `CreateProductHandler` como plantilla para nuevos casos de uso.
4. Validar CA-N del módulo y CA-T del anexo técnico al finalizar.
