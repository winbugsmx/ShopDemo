# SPEC — Catalog (Clean Architecture + CQRS)

## Objetivo

Evolucionar el bounded context Catalog sin violar capas Domain → Application → Infrastructure → API.

## Referencias

- [REQUERIMIENTOS-CATALOG.md](../../../docs/catalog/REQUERIMIENTOS-CATALOG.md)
- [IMPLEMENTACION-CATALOG.md](../../../docs/catalog/IMPLEMENTACION-CATALOG.md)
- Código: `Catalog/`

## Alcance

- Comandos/queries MediatR, validación FluentValidation
- EF Core + PostgreSQL
- Publicación domain events → Event Hubs (si habilitado)

## Criterios de aceptación

- [ ] Nuevo caso de uso sigue patrón `Commands/` o `Queries/`
- [ ] Sin referencias de Domain a Infrastructure
- [ ] `POST /api/products` sigue funcionando

## Instrucciones para el agente

Leer un handler existente (`CreateProductHandler`) como plantilla antes de añadir features.
