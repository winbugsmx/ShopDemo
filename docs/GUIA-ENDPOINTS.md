# Guía de uso de APIs — ShopDemo

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

Esta guía está pensada para **usuarios, testers y desarrolladores** que necesitan entender **para qué sirve cada endpoint**, **cómo encajan en el proceso de compra** y **cómo levantar y configurar** los servicios en local, Aspire o nube.

**Índice del curso:** [README.md](../README.md) · **Arquitectura:** [ARQUITECTURA.md](./ARQUITECTURA.md)

---

## ¿Qué es ShopDemo?

ShopDemo es una plataforma de comercio electrónico dividida en **microservicios independientes**, cada uno con una responsabilidad clara:

| Servicio | ¿Qué hace? | Puerto |
|---|---|---|
| **Catalog** | Administra el catálogo de productos (nombre, precio, categoría) | 8001 |
| **Orders** | Gestiona los pedidos de los clientes | 8002 |
| **Inventory** | Controla cuántas unidades hay disponibles para vender | 8003 |
| **Analytics** | Observa eventos del bus (solo lectura; no modifica negocio) | 8004 |

Ninguno reemplaza a otro: trabajan en conjunto. Un producto se **define** en Catalog, se **abastece** en Inventory y se **vende** a través de Orders. Con **Event Hubs** activo, Inventory puede recibir stock automáticamente y Analytics **muestra** los eventos publicados.

---

## Colección para pruebas

Puedes importar en **Postman**, **Insomnia** o **Thunder Client** el archivo:

**[ShopDemo.postman_collection.json](./ShopDemo.postman_collection.json)**

La colección agrupa los endpoints por API e incluye una carpeta **Flujo integrado (E2E)** con la secuencia completa de compra.

### Variables de la colección

| Variable | Valor por defecto | Uso |
|---|---|---|
| `catalogBaseUrl` | `http://localhost:8001` | URL base de Catalog |
| `ordersBaseUrl` | `http://localhost:8002` | URL base de Orders |
| `inventoryBaseUrl` | `http://localhost:8003` | URL base de Inventory |
| `analyticsBaseUrl` | `http://localhost:8004` | URL base de Analytics |
| `customerId` | UUID de ejemplo | Identificador del cliente en pedidos |
| `productId` | UUID de ejemplo | Actualizar tras crear un producto |
| `orderId` | UUID de ejemplo | Actualizar tras crear un pedido |

> **Nube (Azure ACA / AWS ALB):** sustituye cada `localhost` por el FQDN o DNS del balanceador correspondiente. Ver [despliegue/README.md](./despliegue/README.md).

> **Tip:** Después de crear un producto o pedido, copia el `id` de la respuesta y actualiza las variables `productId` u `orderId` en Postman.

---

## Cómo levantar los servicios

### Opción A — Docker Compose (recomendado etapas 1–5)

Cada API tiene su `docker-compose.yml`. Desde la raíz del repo:

```bash
# Catalog
cd Catalog/ShopDemo.Catalog.Api
copy .env.example .env   # si usarás Event Hubs
docker compose up --build

# Orders (otra terminal)
cd Orders/ShopDemo.Orders.Api
docker compose up --build

# Inventory (otra terminal)
cd Inventory/ShopDemo.Inventory.Api
docker compose up --build

# Analytics (etapa 6+)
cd Aspire/ShopDemo.Analytics.Api
docker compose up --build
```

Para el flujo integrado, **Catalog, Orders e Inventory deben estar en ejecución** (Analytics es opcional salvo pruebas de eventos).

### Opción B — .NET Aspire (recomendado etapa 6)

Un solo comando levanta 4 APIs + PostgreSQL + Azurite + dashboard:

```bash
dotnet user-secrets set "ShopDemo:EventHubs:ConnectionString" "<TU_CONNECTION_STRING>" \
  --project Aspire/ShopDemo.AppHost

dotnet run --project Aspire/ShopDemo.AppHost
```

### Opción C — Nube

- **Azure:** [IMPLEMENTACION-DESPLIEGUE-AZURE.md](./despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md)
- **AWS:** [IMPLEMENTACION-DESPLIEGUE-AWS.md](./despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md)

---

## Variables de configuración por servicio

Antes de probar endpoints con Event Hubs o integración Orders→Inventory, revisa estas variables.

### Catalog — `Catalog/ShopDemo.Catalog.Api/`

| Variable | Archivo | Descripción |
|---|---|---|
| `ConnectionStrings__DefaultConnection` | `appsettings.json`, `docker-compose.yml` | PostgreSQL (`catalog-db` en Docker; `localhost:5433` en dev) |
| `EventHubs__Enabled` | `.env`, compose | `true` publica a Azure Event Hubs |
| `EventHubs__ConnectionString` | `.env` | Connection string del namespace (secreto) |
| `EventHubs__EventHubName` | `.env`, compose | `shopdemo-events` |

Plantilla: `.env.example` → copiar a `.env`

### Orders — `Orders/ShopDemo.Orders.Api/`

| Variable | Archivo | Descripción |
|---|---|---|
| `ConnectionStrings__DefaultConnection` | `appsettings.json`, compose | Puerto `5434` en host |
| `InventoryApi__BaseUrl` | `appsettings.json`, compose | `http://localhost:8003` · Docker: `http://host.docker.internal:8003` · Aspire/nube: URL de Inventory |
| `EventHubs__*` | `.env` | Igual que Catalog |

### Inventory — `Inventory/ShopDemo.Inventory.Api/`

| Variable | Archivo | Descripción |
|---|---|---|
| `ConnectionStrings__DefaultConnection` | `appsettings.json`, compose | Puerto `5435` en host |
| `EventHubs__Enabled` | `.env` | Activa publisher y consumidor `CatalogEventsProcessor` |
| `EventHubs__ConsumerGroup` | compose | `inventory-service` |
| `EventHubs__CheckpointStorageConnectionString` | `.env`, compose | Azurite en Docker (`azurite:10000`) |
| `EventHubs__CheckpointContainerName` | compose | `inventory-checkpoints` |

### Analytics — `Aspire/ShopDemo.Analytics.Api/`

| Variable | Archivo | Descripción |
|---|---|---|
| `EventHubs__Enabled` | compose, Aspire | `true` |
| `EventHubs__ConsumerGroup` | compose | `analytics-service` |
| `EventHubs__CheckpointStorageConnectionString` | compose | Azurite local |
| `EventHubs__CheckpointContainerName` | compose | `analytics-checkpoints` |

En Aspire, el AppHost inyecta estas variables; no necesitas `.env` si usas solo AppHost.

### AppHost — `Aspire/ShopDemo.AppHost/`

| Variable | Dónde | Descripción |
|---|---|---|
| `ShopDemo:EventHubs:ConnectionString` | user secrets o `appsettings.Development.json` | Centraliza Event Hubs para los 4 APIs |

Guía completa: [INTEGRACION-AZURE-EVENT-HUBS.md](./INTEGRACION-AZURE-EVENT-HUBS.md) · [INTEGRACION-ASPIRE.md](./INTEGRACION-ASPIRE.md)

---

## Flujo general del proceso

### Flujo manual (Event Hubs desactivado)

```mermaid
flowchart TD
    A["1. Crear producto\n(Catalog)"] --> B["2. Registrar stock\n(Inventory)"]
    B --> C["3. Crear pedido\n(Orders)"]
    C --> D["4. Confirmar pedido\n(Orders)"]
    D --> E["Reserva automática\n(Inventory)"]
    E --> F["5. Consultar stock\n(Inventory)"]
    F --> G{"¿Cancelar?"}
    G -->|Sí| H["6. Cancelar pedido\n(Orders)"]
    H --> I["Libera stock\n(Inventory)"]
    G -->|No| J["Pedido confirmado"]
```

### Flujo con Event Hubs + Analytics (etapas 5–6)

```mermaid
flowchart TD
    A["1. Crear producto\n(Catalog)"] --> EH[Azure Event Hubs]
    EH --> I2["Inventory auto-stock\n(consumer inventory-service)"]
    EH --> AN["Analytics observa\n(consumer analytics-service)"]
    A --> C["2. Crear pedido\n(Orders)"]
    C --> D["3. Confirmar pedido"]
    D --> E["Reserva HTTP\n(Inventory)"]
    AN --> V["GET /api/analytics/events"]
```

### En palabras sencillas

1. Un administrador **crea un producto** en el catálogo.
2. El almacén **registra stock** — manualmente (`POST /api/inventory/stock`) o **automáticamente** si Event Hubs está activo.
3. Un cliente **hace un pedido** con uno o más productos.
4. Al **confirmar** el pedido, el sistema **aparta (reserva)** las unidades del inventario vía HTTP.
5. Puedes **consultar** cuántas unidades quedan y, si Analytics está activo, **ver los eventos** del bus.
6. Si el pedido se **cancela**, las unidades reservadas **vuelven** al inventario.

---

## Catalog API — Catálogo de productos

**Base URL:** `http://localhost:8001`  
**Swagger:** `http://localhost:8001/swagger`

### ¿Quién lo usa?

- Administradores o sistemas de back-office que dan de alta productos en la tienda.
- Es el **primer paso** del flujo: aquí nace el identificador del producto (`ProductId`).

---

### `POST /api/products` — Crear producto

**¿Para qué sirve?**  
Registra un producto nuevo en la tienda con su nombre, descripción, precio, categoría y stock inicial informativo.

**¿Cuándo usarlo?**  
Cuando quieres agregar un artículo al catálogo antes de venderlo.

**Ejemplo de solicitud:**

```json
{
  "name": "Teclado Mecánico",
  "description": "RGB, switches azules",
  "price": 89.99,
  "currency": "USD",
  "stock": 50,
  "category": "Electronics"
}
```

**Categorías válidas:** `Electronics`, `Clothing`, `Food`, `Books`, `Sports`.

**Respuesta esperada:** `201 Created` con el producto creado, incluyendo su `id`.  
**Guarda ese `id`** — lo necesitarás en Inventory y Orders.

**Errores comunes:**

| Código | Significado |
|---|---|
| 400 | Datos inválidos (nombre muy corto, precio negativo, etc.) |
| 409 | Ya existe un producto con ese nombre |

---

## Inventory API — Inventario y stock

**Base URL:** `http://localhost:8003`  
**Swagger:** `http://localhost:8003/swagger`

### ¿Quién lo usa?

- Personal de almacén o integraciones que registran y consultan stock.
- **Orders** también lo usa de forma automática al confirmar o cancelar pedidos (no necesitas llamarlo manualmente en el flujo normal).

---

### `POST /api/inventory/stock` — Registrar stock

**¿Para qué sirve?**  
Indica cuántas unidades de un producto están disponibles para la venta.

**¿Cuándo usarlo?**  
- **Sin Event Hubs:** siempre después de crear un producto en Catalog.
- **Con Event Hubs:** opcional si Inventory ya auto-registró stock al recibir `ProductCreatedDomainEvent`.

**Ejemplo de solicitud:**

```json
{
  "productId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "productName": "Teclado Mecánico",
  "units": 50
}
```

**Respuesta esperada:** `201 Created` con el registro de stock.

> Si el producto ya tenía stock registrado, las unidades se **suman** (reabastecimiento).

---

### `GET /api/inventory/{productId}` — Consultar stock

**¿Para qué sirve?**  
Muestra cuántas unidades quedan disponibles de un producto.

**¿Cuándo usarlo?**  
- Para verificar el inventario después de confirmar un pedido.
- Para comprobar que el stock se restauró tras una cancelación.

**Respuesta esperada:** `200 OK` con `availableUnits`.

**Ejemplo de respuesta:**

```json
{
  "productId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "productName": "Teclado Mecánico",
  "availableUnits": 48,
  "createdAt": "2026-06-11T10:00:00+00:00",
  "lastUpdatedAt": "2026-06-11T10:30:00+00:00"
}
```

---

### `POST /api/inventory/reservations` — Reservar stock

**¿Para qué sirve?**  
Descuenta unidades del inventario para un pedido concreto.

**¿Cuándo usarlo?**  
En operación normal **no lo llamas tú**: Orders lo invoca automáticamente al confirmar un pedido. Está en la colección para pruebas técnicas directas.

**Ejemplo de solicitud:**

```json
{
  "orderId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "lines": [
    { "productId": "3fa85f64-5717-4562-b3fc-2c963f66afa6", "quantity": 2 }
  ]
}
```

**Respuesta esperada:** `204 No Content` (éxito sin cuerpo).

---

### `POST /api/inventory/reservations/release` — Liberar stock

**¿Para qué sirve?**  
Devuelve al inventario las unidades que estaban reservadas para un pedido.

**¿Cuándo usarlo?**  
En operación normal **no lo llamas tú**: Orders lo invoca al cancelar un pedido que ya estaba confirmado.

**Respuesta esperada:** `204 No Content`.

---

## Orders API — Pedidos

**Base URL:** `http://localhost:8002`  
**Swagger:** `http://localhost:8002/swagger`

### ¿Quién lo usa?

- Aplicaciones de checkout o back-office de ventas.
- Clientes finales (indirectamente) al realizar una compra.

---

### `POST /api/orders` — Crear pedido

**¿Para qué sirve?**  
Registra un nuevo pedido con los productos que el cliente quiere comprar.

**¿Cuándo usarlo?**  
Cuando el cliente confirma su carrito. El pedido queda en estado **Pending** (pendiente).

**Ejemplo de solicitud:**

```json
{
  "customerId": "11111111-1111-1111-1111-111111111111",
  "shippingAddress": {
    "street": "Av. Reforma 123",
    "city": "Ciudad de México",
    "postalCode": "06600",
    "country": "MX"
  },
  "lines": [
    {
      "productId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "productName": "Teclado Mecánico",
      "unitPrice": 89.99,
      "currency": "USD",
      "quantity": 2
    }
  ]
}
```

**Respuesta esperada:** `201 Created` con el pedido y su `id`.  
**Guarda ese `id`** para confirmar, cancelar o consultar el pedido.

> El `productId` debe existir en Catalog. El stock debe estar registrado en Inventory antes de confirmar.

---

### `GET /api/orders/{id}` — Consultar pedido

**¿Para qué sirve?**  
Obtiene el detalle de un pedido: estado, líneas, total y dirección de envío.

**¿Cuándo usarlo?**  
Para ver el estado de un pedido después de crearlo, confirmarlo o cancelarlo.

**Estados posibles:** `Pending`, `Confirmed`, `Shipped`, `Delivered`, `Cancelled`.

---

### `GET /api/orders?customerId={uuid}` — Listar pedidos de un cliente

**¿Para qué sirve?**  
Devuelve todos los pedidos asociados a un cliente.

**¿Cuándo usarlo?**  
En un historial de compras o panel de “Mis pedidos”.

---

### `POST /api/orders/{id}/confirm` — Confirmar pedido

**¿Para qué sirve?**  
Aprueba el pedido y lo pasa de **Pending** a **Confirmed**.

**¿Cuándo usarlo?**  
Cuando el pago fue aceptado o el negocio valida la orden.

**¿Qué pasa detrás?**  
Orders llama automáticamente a Inventory para **reservar** las unidades de cada línea. Si no hay stock suficiente, la confirmación falla.

**Respuesta esperada:** `200 OK` con el pedido actualizado (`status: "Confirmed"`).

---

### `POST /api/orders/{id}/cancel` — Cancelar pedido

**¿Para qué sirve?**  
Cancela un pedido indicando el motivo.

**¿Cuándo usarlo?**  
Cuando el cliente o el negocio decide no continuar con la compra.

**Ejemplo de solicitud:**

```json
{
  "reason": "El cliente solicitó la cancelación"
}
```

**¿Qué pasa detrás?**  
Si el pedido estaba **Confirmed**, Orders libera automáticamente el stock reservado en Inventory.

**Respuesta esperada:** `200 OK` con `status: "Cancelled"`.

---

## Analytics API — Observador de eventos

**Base URL:** `http://localhost:8004`  
**Swagger:** `http://localhost:8004/swagger`

### ¿Quién lo usa?

- Desarrolladores y alumnos que validan la integración con **Azure Event Hubs** y **.NET Aspire**.
- No participa en el flujo de compra; solo **lee** el bus de eventos.

> Requiere `EventHubs__Enabled=true` y connection string válida. Con Aspire, el AppHost configura todo automáticamente.

---

### `GET /api/analytics/events` — Listar eventos observados

**¿Para qué sirve?**  
Devuelve los últimos eventos que Analytics consumió del Event Hub (buffer en memoria).

**¿Cuándo usarlo?**  
Después de crear un producto, confirmar un pedido o cualquier acción que publique eventos en Catalog, Orders o Inventory.

**Parámetros:**

| Query | Default | Rango |
|---|---|---|
| `take` | 50 | 1–100 |

**Ejemplo:** `GET http://localhost:8004/api/analytics/events?take=20`

**Respuesta esperada:** `200 OK`

```json
{
  "totalBuffered": 3,
  "returned": 3,
  "events": [
    {
      "eventType": "ProductCreatedDomainEvent",
      "eventId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "occurredOn": "2026-06-11T10:00:00Z",
      "source": "catalog",
      "payloadJson": "{ ... }",
      "receivedAt": "2026-06-11T10:00:01Z"
    }
  ]
}
```

---

### `GET /api/analytics/health` — Estado del servicio

**¿Para qué sirve?**  
Indica si Analytics está en ejecución y cuántos eventos hay en el buffer.

**Respuesta esperada:** `200 OK` con `bufferedEvents`.

---

## Escenarios de uso

### Escenario 1: Compra exitosa

| Paso | Acción | Endpoint |
|---|---|---|
| 1 | Dar de alta el producto | `POST /api/products` (Catalog) |
| 2 | Registrar 50 unidades en almacén | `POST /api/inventory/stock` (Inventory) |
| 3 | Cliente pide 2 unidades | `POST /api/orders` (Orders) |
| 4 | Se confirma el pago | `POST /api/orders/{id}/confirm` (Orders) |
| 5 | Verificar que quedan 48 unidades | `GET /api/inventory/{productId}` (Inventory) |

### Escenario 2: Compra cancelada después de confirmar

| Paso | Acción | Endpoint |
|---|---|---|
| 1–4 | Igual que escenario 1 | — |
| 5 | Cliente cancela | `POST /api/orders/{id}/cancel` (Orders) |
| 6 | Verificar que el stock volvió a 50 | `GET /api/inventory/{productId}` (Inventory) |

### Escenario 3: Consultar historial del cliente

| Paso | Acción | Endpoint |
|---|---|---|
| 1 | Listar todos sus pedidos | `GET /api/orders?customerId={uuid}` (Orders) |
| 2 | Ver detalle de uno | `GET /api/orders/{id}` (Orders) |

---

### Escenario 4: Event Hubs + Analytics (etapa 5–6)

| Paso | Acción | Endpoint |
|---|---|---|
| 1 | Activar Event Hubs (`.env` o Aspire) | Ver sección configuración |
| 2 | Crear producto | `POST /api/products` (Catalog) |
| 3 | Ver evento en Analytics | `GET /api/analytics/events` |
| 4 | Verificar stock auto-creado | `GET /api/inventory/{productId}` (Inventory) |
| 5 | Crear y confirmar pedido | Orders |
| 6 | Revisar eventos acumulados | `GET /api/analytics/events?take=20` |

### Escenario 5: Despliegue en nube

| Paso | Acción | Referencia |
|---|---|---|
| 1 | Desplegar imágenes en ACR o ECR | [despliegue/](./despliegue/) |
| 2 | Configurar secretos en ACA / ECS | Guías Azure o AWS |
| 3 | Actualizar variables Postman con FQDN | `catalogBaseUrl`, etc. |
| 4 | Ejecutar flujo E2E | Escenarios 1 o 4 |

---

## Resumen rápido por API

### Catalog (1 endpoint)

| Método | Ruta | Uso principal |
|---|---|---|
| POST | `/api/products` | Crear producto en el catálogo |

### Inventory (4 endpoints)

| Método | Ruta | Uso principal |
|---|---|---|
| POST | `/api/inventory/stock` | Registrar o reabastecer stock |
| GET | `/api/inventory/{productId}` | Consultar unidades disponibles |
| POST | `/api/inventory/reservations` | Reservar stock (normalmente vía Orders) |
| POST | `/api/inventory/reservations/release` | Liberar stock (normalmente vía Orders) |

### Orders (5 endpoints)

| Método | Ruta | Uso principal |
|---|---|---|
| POST | `/api/orders` | Crear pedido |
| GET | `/api/orders/{id}` | Consultar pedido |
| GET | `/api/orders?customerId={uuid}` | Listar pedidos del cliente |
| POST | `/api/orders/{id}/confirm` | Confirmar pedido y reservar stock |
| POST | `/api/orders/{id}/cancel` | Cancelar pedido y liberar stock |

| POST | `/api/orders/{id}/cancel` | Cancelar pedido y liberar stock |

### Analytics (2 endpoints)

| Método | Ruta | Uso principal |
|---|---|---|
| GET | `/api/analytics/events` | Listar eventos observados del bus |
| GET | `/api/analytics/health` | Estado y contador del buffer |

---

## URLs y Swagger por entorno

| Servicio | Local (Compose) | Aspire | Nube |
|---|---|---|---|
| Catalog | http://localhost:8001/swagger | :8001 | FQDN ACA / ALB Catalog |
| Orders | http://localhost:8002/swagger | :8002 | FQDN ACA / ALB Orders |
| Inventory | http://localhost:8003/swagger | :8003 | URL interna + opcional pública |
| Analytics | http://localhost:8004/swagger | :8004 | FQDN ACA / ALB Analytics |
| Aspire Dashboard | — | URL en consola AppHost | No desplegado |

---

## Etapas del curso — documentación recomendada

| Etapa | Tema | Leer primero | Luego implementar |
|---|---|---|---|
| 1 | Catalog | [REQUERIMIENTOS-CATALOG](./catalog/REQUERIMIENTOS-CATALOG.md) | [IMPLEMENTACION-CATALOG](./catalog/IMPLEMENTACION-CATALOG.md) |
| 2 | Orders | [REQUERIMIENTOS-ORDERS](./orders/REQUERIMIENTOS-ORDERS.md) | [IMPLEMENTACION-ORDERS](./orders/IMPLEMENTACION-ORDERS.md) |
| 3 | Inventory | [REQUERIMIENTOS-INVENTORY](./inventory/REQUERIMIENTOS-INVENTORY.md) | [IMPLEMENTACION-INVENTORY](./inventory/IMPLEMENTACION-INVENTORY.md) |
| 4 | E2E | Esta guía | [ARQUITECTURA](./ARQUITECTURA.md) |
| 5 | Event Hubs | [INTEGRACION-AZURE-EVENT-HUBS](./INTEGRACION-AZURE-EVENT-HUBS.md) | Mismo documento |
| 6 | Aspire | [REQUERIMIENTOS-ANALYTICS-ASPIRE](./analytics/REQUERIMIENTOS-ANALYTICS-ASPIRE.md) | [IMPLEMENTACION-ANALYTICS-ASPIRE](./analytics/IMPLEMENTACION-ANALYTICS-ASPIRE.md) |
| 7–8 | Nube | [despliegue/README](./despliegue/README.md) | Azure o AWS IMPLEMENTACION |

---

## Documentación relacionada

| Documento | Contenido |
|---|---|
| [README.md](../README.md) | Objetivo del curso, roadmap, configuración global |
| [ARQUITECTURA.md](./ARQUITECTURA.md) | Visión técnica, etapas, matriz de configuración |
| [catalog/](./catalog/) | Requerimientos e implementación de Catalog |
| [orders/](./orders/) | Requerimientos e implementación de Orders |
| [inventory/](./inventory/) | Requerimientos e implementación de Inventory |
| [analytics/](./analytics/) | Aspire + Analytics |
| [despliegue/](./despliegue/) | Docker → Azure y AWS |
| [INTEGRACION-AZURE-EVENT-HUBS.md](./INTEGRACION-AZURE-EVENT-HUBS.md) | Event Hubs paso a paso |
| [INTEGRACION-ASPIRE.md](./INTEGRACION-ASPIRE.md) | Orquestación local Aspire |
