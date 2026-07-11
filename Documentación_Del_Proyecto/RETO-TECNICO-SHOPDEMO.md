# Reto técnico — ShopDemo

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 · gilberto.juarez@gmail.com |

**Documento base:** [README.md](../README.md) · **Estructura documental (3 capas):** [GUIA-ESTRUCTURA-DOCUMENTACION.md](./GUIA-ESTRUCTURA-DOCUMENTACION.md) · **Guía de APIs:** [GUIA-ENDPOINTS.md](./GUIA-ENDPOINTS.md)  
**Guía de desarrollo (integrar/copiar código):** [GUIA-DESARROLLO-INTEGRACIONES.md](./GUIA-DESARROLLO-INTEGRACIONES.md)  
**Anexos de código:** [Shared](./ANEXO-CODIGO-SHARED.md) · [Catalog](./catalog/ANEXO-CODIGO-CATALOG.md) · [Orders](./orders/ANEXO-CODIGO-ORDERS.md) · [Inventory](./inventory/ANEXO-CODIGO-INVENTORY.md) · [Event Hubs](./ANEXO-CODIGO-EVENT-HUBS.md) · [Analytics](./analytics/ANEXO-CODIGO-ANALYTICS-ASPIRE.md) · [MCP](./integracion-ia/ANEXO-CODIGO-MCP.md)  
**Scripts release:** [Azure](../Source/scripts/azure/README.md) · [AWS](../Source/scripts/aws/README.md)

---

## ¿De qué trata este reto?

**ShopDemo** es un reto técnico práctico: construir y operar una tienda en línea como un **sistema distribuido de microservicios** en **.NET 10**. No es un proyecto teórico; cada etapa pide que el código funcione, que se pueda probar y que, al final, el sistema corra en tu máquina, en **Azure** o en **AWS**.

El reto combina diseño de software (DDD, distintos estilos arquitectónicos), integración entre servicios, mensajería en la nube, contenedores, Kubernetes y herramientas modernas de desarrollo con IA.

---

## Objetivo del reto

Al completar el ejercicio debes demostrar que puedes:

1. Modelar un dominio de e-commerce dividido en **tres contextos de negocio** (catálogo, pedidos, inventario), cada uno con su propia base de datos.
2. Implementar **dos enfoques arquitectónicos** en el mismo sistema: Clean Architecture + CQRS en Catalog y Orders, y arquitectura hexagonal en Inventory.
3. Integrar los servicios por **HTTP** (pedidos que reservan stock) y por **eventos** (Azure Event Hubs).
4. Observar el bus de eventos con un servicio **Analytics** y orquestar el entorno local con **.NET Aspire**.
5. Empaquetar cada API en **Docker** y publicarla en **Azure** (Container Apps o AKS) y **AWS** (ECS o EKS).
6. Desplegar el mismo sistema en **Kubernetes** (Minikube, AKS, EKS) usando los manifiestos de la carpeta `k8s/`.
7. Exponer un **MCP Gateway** para que agentes de IA (Cursor, Claude Code) operen sobre las APIs existentes.
8. Validar todo con **Swagger**, **Postman** y flujos de punta a punta.
9. Aplicar prácticas de **operación**: health checks, observabilidad básica, resiliencia y desarrollo guiado por especificaciones (`spec-driven/`).

---

## Los servicios del reto

| Servicio | Puerto | Rol en el reto |
|---|---|---|
| **Catalog** | 8001 | Alta de productos en el catálogo |
| **Orders** | 8002 | Creación, confirmación y cancelación de pedidos |
| **Inventory** | 8003 | Stock, reservas y liberaciones |
| **Analytics** | 8004 | Observa eventos del bus (solo lectura) |
| **MCP Gateway** | 8005 | Puente para agentes IA hacia Catalog, Inventory y Analytics |

Cada microservicio de negocio tiene **PostgreSQL propio**. La mensajería usa **Azure Event Hubs** (también cuando parte del sistema corre en AWS). El **AppHost Aspire** solo se usa en desarrollo local para levantar las cuatro APIs de negocio con un solo comando.

---

## El flujo de negocio que debes lograr

En palabras simples, el reto exige que este proceso funcione de punta a punta:

1. Se **crea un producto** en Catalog.
2. Se **registra stock** en Inventory (a mano por API o automáticamente si Event Hubs está activo).
3. Un cliente **crea un pedido** en Orders.
4. Al **confirmar** el pedido, Orders **reserva stock** en Inventory por HTTP.
5. Opcionalmente se **cancela** el pedido y el stock **se libera**.
6. Con Analytics activo, puedes **ver los eventos** que circularon por el bus.

Ese flujo se prueba con la colección Postman **Flujo integrado (E2E)** o siguiendo la [GUIA-ENDPOINTS](./GUIA-ENDPOINTS.md).

---

## Hitos del reto (etapas)

Cada hito tiene documentación de **requerimientos** (por qué) e **implementación** (cómo). El reto se considera avanzado cuando cumples la validación de cada etapa.

| Hito | Qué demuestras | Cómo lo validas |
|---|---|---|
| **0** | Entiendes el dominio y las APIs | Postman / GUIA-ENDPOINTS |
| **1** | Catalog con Clean + CQRS | `POST /api/products` |
| **2** | Orders con Clean + CQRS | Crear y confirmar pedido |
| **3** | Inventory hexagonal | Stock y reservas |
| **4** | Integración E2E manual | Compra completa |
| **5** | Mensajería Azure Event Hubs | Auto-stock y eventos |
| **6** | Aspire + Analytics | `GET /api/analytics/events` |
| **7** | Release en Azure (ACA) | APIs en Container Apps |
| **8** | Release en AWS (ECS) | APIs en Fargate |
| **9** | Kubernetes local (Minikube) | Pods y HPA en `shopdemo` |
| **10** | Azure AKS | ShopDemo en cluster AKS |
| **11** | Amazon EKS | ShopDemo en cluster EKS |
| **12** | Observabilidad | Logs, traceId, alertas (Azure y AWS) |
| **13** | Resiliencia | Health, recuperación ante fallos |
| **14** | Integración IA | Tools MCP y alertas en la nube |
| **14b** | MCP en contenedores/K8s | `curl .../health` y `/mcp` desplegado |
| **15** | Spec-driven development | Agente sigue `spec-driven/specs/` |

---

## Dónde ejecutas el reto

El mismo código debe poder correr en tres escenarios:

### En tu PC (local)

- **Docker Compose:** un servicio por terminal; ideal para empezar (etapas 1–5).
- **Aspire AppHost:** las 4 APIs de negocio con un comando (etapa 6).
- **`dotnet run`:** depuración de un solo microservicio.
- **Minikube + `k8s/`:** practicar Kubernetes antes de la nube (etapa 9).

Orden recomendado al arrancar: **Catalog → Inventory → Orders → Analytics → MCP** (este último solo en etapa 14+).

### En Azure (release)

- **Container Apps (ACA):** camino más directo; imágenes en ACR.
- **AKS:** recursos compartidos `k8s/` + deployments `k8s/azure/` (ACR); Ingress y secretos en el cluster.

Se despliegan **cinco contenedores**: Catalog, Orders, Inventory, Analytics y MCP Gateway.

### En AWS (release)

- **ECS Fargate:** sin Kubernetes; ALB por API pública.
- **EKS:** misma estructura compartida; deployments en `k8s/aws/` (ECR).

Los contenedores en AWS siguen usando **Azure Event Hubs** para mensajería (conexión cross-cloud).

---

## Criterios de éxito del reto

Considera el reto cumplido en una etapa cuando:

- `dotnet build Source/ShopDemo.slnx` compila sin errores.
- Los endpoints `/health` responden en los servicios levantados.
- El flujo E2E de Postman pasa en el entorno que estés usando (local o nube).
- Los secretos (Event Hubs, PostgreSQL, checkpoints) están configurados y **no** commiteados al repositorio.
- En nube, las variables Postman (`catalogBaseUrl`, `ordersBaseUrl`, etc.) apuntan a las URLs reales de ACA, ALB o Ingress.

Checklist rápido antes del E2E:

- Catalog, Orders e Inventory activos y saludables.
- Orders alcanza Inventory (URL correcta según Docker, Aspire o nube).
- Event Hubs configurado si pruebas mensajería o Analytics.
- Postman importado desde `Documentación_Del_Proyecto/ShopDemo.postman_collection.json`.

---

## Qué aprendes con este reto

| Área | Qué practicas |
|---|---|
| **Diseño** | DDD, bounded contexts, value objects, domain events |
| **Arquitectura** | Clean + CQRS vs hexagonal en el mismo producto |
| **Integración** | HTTP síncrono y eventos asíncronos |
| **Plataforma** | Docker, Aspire, Kubernetes, multicloud |
| **Operación** | Health checks, observabilidad, resiliencia, CI/CD básico |
| **IA en desarrollo** | MCP Gateway, spec-driven con Cursor y Claude Code |

---

## Estructura del repositorio (referencia)

```
ShopDemo/
├── Source/Catalog/          # Catálogo (Clean + CQRS)
├── Source/Orders/           # Pedidos (Clean + CQRS)
├── Source/Inventory/        # Inventario (hexagonal)
├── Source/AI/               # MCP Gateway
├── Source/Aspire/           # AppHost, ServiceDefaults, Analytics
├── Source/ShopDemo.Shared/  # Kernel compartido
├── k8s/              # Manifiestos Kubernetes
├── spec-driven/      # Specs y plantillas para agentes IA
└── Documentación_Del_Proyecto/             # Documentación del curso
```

---

## Documentación de apoyo

| Tema | Enlace |
|---|---|
| Inicio y despliegue | [README.md](../README.md) |
| Arquitectura técnica | [ARQUITECTURA.md](./ARQUITECTURA.md) |
| Endpoints y Postman | [GUIA-ENDPOINTS.md](./GUIA-ENDPOINTS.md) |
| Despliegue Azure/AWS | [despliegue/README.md](./despliegue/README.md) |
| Integración IA / MCP | [integracion-ia/README.md](./integracion-ia/README.md) |
| Spec-driven | [spec-driven/README.md](../spec-driven/README.md) |

---

## Cierre

ShopDemo no es un solo ejercicio de código: es un **reto técnico integrador** que va desde modelar un dominio hasta publicarlo en dos nubes, pasando por eventos, contenedores, Kubernetes, observabilidad e integración con herramientas de IA. Cada etapa suma una capacidad real que puedes demostrar con APIs funcionando, pruebas E2E y, cuando corresponda, servicios desplegados en Azure o AWS.
