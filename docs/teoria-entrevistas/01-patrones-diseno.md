# 01 — Patrones de diseño en ShopDemo

**Objetivo:** Identificar patrones del código y explicarlos en entrevista con ejemplo real.

---

## Mapa rápido

| Patrón | Dónde | Para qué |
|---|---|---|
| **Repository** | `IProductRepository`, `IOrderRepository` | Abstraer persistencia |
| **Unit of Work** | `IUnitOfWork` + `DbContext` | Commit transaccional |
| **Mediator (CQRS)** | MediatR Catalog/Orders | Desacoplar API de lógica |
| **Command / Query** | `CreateProductCommand`, etc. | Escritura vs lectura |
| **Domain Events** | `ProductCreatedDomainEvent` | Hechos dentro del agregado |
| **Integration Event** | `IntegrationEventEnvelope` | Contrato entre servicios |
| **Adapter** | `InventoryHttpClient`, repos EF | Puertos implementados en infra |
| **Background Service** | `EventHubAnalyticsProcessor` | Consumo de eventos |
| **API Gateway (ligero)** | MCP Gateway | Tools sobre APIs internas |

---

## Repository + Unit of Work

**En ShopDemo:** `Catalog.Domain/Repositories/` → `Catalog.Infrastructure/Persistence/`.

**Entrevista:** *¿Por qué no usar DbContext en el handler?*

**Respuesta modelo:** El handler depende de abstracciones del dominio; EF es infraestructura. Facilita tests y respeta dependencias hacia adentro.

---

## CQRS con MediatR

**En ShopDemo:** `Application/Commands/CreateProduct/` (Command, Handler, Validator).

**Entrevista:** *¿CQRS implica dos bases de datos?*

**Respuesta modelo:** No necesariamente. ShopDemo usa CQRS **lógico** con **una BD por servicio**. Read models separados son un paso avanzado.

---

## Domain Events vs Integration Events

| | Domain Event | Integration Event |
|---|---|---|
| Alcance | Bounded context | Entre servicios |
| Ejemplo | `ProductCreatedDomainEvent` | `IntegrationEventEnvelope` |
| Transporte | Memoria en agregado | Azure Event Hubs |

**Trampa:** Confundir evento de dominio con mensaje de integración.

---

## Preguntas de entrevista

1. ¿Qué patrón usa Orders para llamar a Inventory?
2. ¿Dónde vive la lógica de negocio en Catalog?
3. ¿Por qué Analytics es más simple en capas de dominio?
4. ¿Ventaja de `IntegrationEventEnvelope`?

**Referencias:** [ARQUITECTURA §5](../ARQUITECTURA.md) · `ShopDemo.Shared/`
