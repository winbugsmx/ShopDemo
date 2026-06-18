# ShopDemo — Plataforma de e-commerce distribuida (.NET 10)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

ShopDemo es un laboratorio práctico donde construyes y operas una plataforma de comercio electrónico como **microservicios independientes**, comparas estilos arquitectónicos, integras bounded contexts por HTTP y eventos, orquestas el sistema con **.NET Aspire** y despliegas contenedores en **Azure** y **AWS**.

---

## Objetivo de la práctica

Al finalizar las etapas del curso, el alumno debe poder:

1. **Modelar** tres bounded contexts de negocio (Catalog, Orders, Inventory) con DDD y persistencia dedicada.
2. **Comparar** Clean Architecture + CQRS (Catalog, Orders) frente a arquitectura hexagonal (Inventory).
3. **Integrar** servicios por HTTP síncrono (Orders → Inventory) y por mensajería asíncrona (Azure Event Hubs).
4. **Observar** el bus de eventos con Analytics y orquestar todo localmente con Aspire.
5. **Empaquetar** cada API en Docker y **desplegarla** en Azure (Container Apps, AKS) y AWS (ECS, EKS).
6. **Desplegar** en Kubernetes (Minikube local, AKS, EKS) con manifiestos `k8s/`.
7. **Exponer** el MCP Gateway para agentes IA (Cursor, Claude Code) sobre Catalog, Inventory y Analytics.
8. **Probar** flujos de punta a punta con Swagger, Postman y la guía de endpoints.
9. **Operar** con health checks, observabilidad básica y desarrollo guiado por specs (`spec-driven/`).

---

## Arquitectura a alto nivel

```mermaid
flowchart TB
    subgraph negocio ["Microservicios de negocio"]
        C[Catalog :8001\nClean + CQRS]
        O[Orders :8002\nClean + CQRS]
        I[Inventory :8003\nHexagonal]
    end

    subgraph transversal ["Transversal"]
        A[Analytics :8004\nObservador]
        M[MCP Gateway :8005\nAgentes IA]
        AH[Aspire AppHost\nSolo dev local]
        EH[Azure Event Hubs]
    end

    C & O & I -->|HTTP| O
    O -->|reserve/release| I
    C & O & I -->|publican| EH
    EH -->|inventory-service| I
    EH -->|analytics-service| A
    M -->|tools HTTP| C & I & A
    AH -.-> C & O & I & A
```

| Capa | Qué contiene |
|---|---|
| **API** | Controllers HTTP, Swagger, composición DI |
| **Application** | CQRS / casos de uso, DTOs, validación |
| **Domain** | Agregados, value objects, domain events |
| **Infrastructure** | EF Core, HTTP clients, adaptadores Event Hubs |
| **Shared** | Kernel DDD + `IntegrationEventEnvelope` |
| **Aspire** | AppHost, ServiceDefaults, Analytics |
| **AI** | MCP Gateway HTTP (`/mcp`) para herramientas de agentes |

**Documentación técnica completa:** [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md)

---

## Etapas del curso (roadmap)

Cada etapa tiene un par de documentos: **requerimientos** (qué y por qué) e **implementación** (cómo, con código). Se recomienda leer ambos en orden.

**Guía de desarrollo con código para copiar/integrar (recomendada para alumnos):** [GUIA-DESARROLLO-INTEGRACIONES.md](docs/GUIA-DESARROLLO-INTEGRACIONES.md) — paso a paso por etapa, anexos con `.cs` completos y checklist de validación.

| Etapa | Tema | Requerimientos | Implementación | Cómo validar |
|---|---|---|---|---|
| **0** | Visión y endpoints | — | [GUIA-ENDPOINTS](docs/GUIA-ENDPOINTS.md) | Postman E2E |
| **1** | Catalog (Clean + CQRS) | [REQUERIMIENTOS-CATALOG](docs/catalog/REQUERIMIENTOS-CATALOG.md) | [IMPLEMENTACION-CATALOG](docs/catalog/IMPLEMENTACION-CATALOG.md) | `POST /api/products` |
| **2** | Orders (Clean + CQRS) | [REQUERIMIENTOS-ORDERS](docs/orders/REQUERIMIENTOS-ORDERS.md) | [IMPLEMENTACION-ORDERS](docs/orders/IMPLEMENTACION-ORDERS.md) | Crear y confirmar pedido |
| **3** | Inventory (Hexagonal) | [REQUERIMIENTOS-INVENTORY](docs/inventory/REQUERIMIENTOS-INVENTORY.md) | [IMPLEMENTACION-INVENTORY](docs/inventory/IMPLEMENTACION-INVENTORY.md) | Stock y reservas |
| **4** | Integración E2E | [GUIA-ENDPOINTS](docs/GUIA-ENDPOINTS.md) | [ARQUITECTURA §4](docs/ARQUITECTURA.md#4-integración-entre-bounded-contexts) | Flujo compra completo |
| **5** | Azure Event Hubs | [INTEGRACION-AZURE-EVENT-HUBS](docs/INTEGRACION-AZURE-EVENT-HUBS.md) | Mismo doc (paso a paso) | Auto-stock + eventos en log |
| **6** | Aspire + Analytics | [REQUERIMIENTOS-ANALYTICS-ASPIRE](docs/analytics/REQUERIMIENTOS-ANALYTICS-ASPIRE.md) | [IMPLEMENTACION-ANALYTICS-ASPIRE](docs/analytics/IMPLEMENTACION-ANALYTICS-ASPIRE.md) | `GET /api/analytics/events` |
| **7** | Docker → Azure | [REQUERIMIENTOS-DESPLIEGUE-AZURE](docs/despliegue/azure/REQUERIMIENTOS-DESPLIEGUE-AZURE.md) | [IMPLEMENTACION-DESPLIEGUE-AZURE](docs/despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md) | APIs en Container Apps |
| **8** | Docker → AWS | [REQUERIMIENTOS-DESPLIEGUE-AWS](docs/despliegue/aws/REQUERIMIENTOS-DESPLIEGUE-AWS.md) | [IMPLEMENTACION-DESPLIEGUE-AWS](docs/despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md) | APIs en ECS Fargate |
| **9** | Kubernetes local (Minikube) | [REQUERIMIENTOS-KUBERNETES](docs/despliegue/kubernetes/REQUERIMIENTOS-KUBERNETES.md) | [IMPLEMENTACION-KUBERNETES-LOCAL](docs/despliegue/kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md) · [Teoría K8s](docs/despliegue/kubernetes/TEORIA-KUBERNETES-OPERACIONES.md) | `kubectl get hpa -n shopdemo` |
| **10** | Azure AKS | [REQUERIMIENTOS-DESPLIEGUE-AKS](docs/despliegue/aks/REQUERIMIENTOS-DESPLIEGUE-AKS.md) | [IMPLEMENTACION-DESPLIEGUE-AKS](docs/despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md) | ShopDemo en AKS |
| **11** | Amazon EKS | [REQUERIMIENTOS-DESPLIEGUE-EKS](docs/despliegue/eks/REQUERIMIENTOS-DESPLIEGUE-EKS.md) | [IMPLEMENTACION-DESPLIEGUE-EKS](docs/despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md) | ShopDemo en EKS |
| **12** | Observabilidad | [REQUERIMIENTOS-OBSERVABILIDAD](docs/observabilidad/REQUERIMIENTOS-OBSERVABILIDAD.md) | [Azure](docs/observabilidad/azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md) · [AWS](docs/observabilidad/aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md) | Logs + alerta + traceId |
| **13** | Resiliencia | [REQUERIMIENTOS-RESILIENCIA](docs/resiliencia/REQUERIMIENTOS-RESILIENCIA.md) | [Azure](docs/resiliencia/azure/IMPLEMENTACION-RESILIENCIA-AZURE.md) · [AWS](docs/resiliencia/aws/IMPLEMENTACION-RESILIENCIA-AWS.md) | Recuperación tras fallo de pod/tarea |
| **14** | Integración IA | [REQUERIMIENTOS-INTEGRACION-IA](docs/integracion-ia/REQUERIMIENTOS-INTEGRACION-IA.md) | [IMPLEMENTACION-MCP-GATEWAY](docs/integracion-ia/IMPLEMENTACION-MCP-GATEWAY.md) · [Azure](docs/integracion-ia/azure/IMPLEMENTACION-INTEGRACION-IA-AZURE.md) · [AWS](docs/integracion-ia/aws/IMPLEMENTACION-INTEGRACION-IA-AWS.md) | MCP tool + alerta KQL/Insights |
| **14b** | Despliegue MCP Gateway | [REQUERIMIENTOS-DESPLIEGUE-MCP](docs/integracion-ia/REQUERIMIENTOS-DESPLIEGUE-MCP.md) | [Azure ACA/AKS](docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) · [AWS ECS/EKS](docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md) | `curl .../mcp` + agente |
| **15** | Spec-driven (Cursor + Claude Code) | [REQUERIMIENTOS-SPEC-DRIVEN](spec-driven/REQUERIMIENTOS-SPEC-DRIVEN-DEVELOPMENT.md) | [IMPLEMENTACION-SPEC-DRIVEN](spec-driven/IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md) | Agente sigue `spec-driven/specs/<módulo>/SPEC.md` |

**Teoría:** [Docker/K8s/AOT](docs/TEORIA-DOCKER-KUBERNETES-AOT.md) · [Observabilidad](docs/observabilidad/TEORIA-OBSERVABILIDAD.md) · [Resiliencia](docs/resiliencia/TEORIA-RESILIENCIA.md) · [Integración IA](docs/integracion-ia/TEORIA-INTEGRACION-IA.md) · [Spec-driven](spec-driven/TEORIA-SPEC-DRIVEN-DEVELOPMENT.md) · [AKS](docs/despliegue/aks/TEORIA-AKS.md) · [EKS](docs/despliegue/eks/TEORIA-EKS.md) · [Azure ACA](docs/despliegue/azure/TEORIA-CONTENEDORES-AZURE.md) · [AWS ECS](docs/despliegue/aws/TEORIA-CONTENEDORES-AWS.md)

---

## Guía rápida: ¿qué modo de ejecución uso?

| Si quieres… | Modo | Sección |
|---|---|---|
| Desarrollar o probar **en tu PC** sin nube | **Local** | [Inicio local](#inicio-local-desarrollo-y-pruebas) |
| Publicar a **Azure** (release) | **Azure** | [Release Azure](#release-azure) |
| Publicar a **AWS** (release) | **AWS** | [Release AWS](#release-aws) |

```mermaid
flowchart TD
    START[¿Dónde ejecuto ShopDemo?]
    START --> LOCAL[Local — mi máquina]
    START --> AZ[Azure — release]
    START --> AWS[AWS — release]

    LOCAL --> C1[Docker Compose\n3–4 terminales]
    LOCAL --> C2[Aspire AppHost\n1 comando]
    LOCAL --> C3[Minikube + k8s/\nKubernetes local]

    AZ --> A1[Container Apps + ACR]
    AZ --> A2[AKS + ACR]

    AWS --> W1[ECS Fargate + ECR]
    AWS --> W2[EKS + ECR]
```

---

## Tabla maestra de arranque

Referencia rápida para **levantar todos los servicios** según dónde ejecutes ShopDemo.

| Servicio | Puerto | Health | Local Compose | Aspire | `dotnet run` | Minikube (`k8s/`) | Azure ACA | Azure AKS | AWS ECS | AWS EKS |
|---|---|---|---|---|---|---|---|---|---|---|
| **Catalog** | 8001 | `/health` | `Catalog/.../docker compose up` | AppHost | `dotnet run --project Catalog/...` | `k8s/catalog/` | Container App | Ingress `/catalog` | ALB dedicado | Ingress `/catalog` |
| **Orders** | 8002 | `/health` | `Orders/.../docker compose up` | AppHost | `dotnet run --project Orders/...` | `k8s/orders/` | Container App | Ingress `/orders` | ALB dedicado | Ingress `/orders` |
| **Inventory** | 8003 | `/health` | `Inventory/.../docker compose up` | AppHost | `dotnet run --project Inventory/...` | `k8s/inventory/` | Container App (interno) | Ingress `/inventory` | Cloud Map / ALB | Ingress `/inventory` |
| **Analytics** | 8004 | `/health` | `Aspire/.../docker compose up` | AppHost | `dotnet run --project Aspire/...` | `k8s/analytics/` | Container App | Ingress `/analytics` | ALB dedicado | Ingress `/analytics` |
| **MCP Gateway** | 8005 | `/health` | `AI/.../docker compose up` | Manual* | `dotnet run --project AI/...` | `k8s/mcp/` | Container App | Ingress `/mcp` | ALB dedicado | Ingress `/mcp` |
| **PostgreSQL** | 5433–5435 | — | Por compose de cada API | AppHost (×3 DB) | Requiere PG local | `k8s/postgres/` | ACI / sidecar | StatefulSet | ECS + EFS | StatefulSet |
| **Azurite** | 10000 | — | En compose Inventory/Analytics | AppHost | — | `k8s/azurite/` | Blob Azure | Blob Azure | S3/Blob | Blob Azure |

\* Aspire no incluye MCP en AppHost; levántalo aparte cuando trabajes integración IA (etapa 14).

### Comandos de verificación (cualquier entorno)

```bash
# Local — APIs de negocio
curl -s http://localhost:8001/health && curl -s http://localhost:8002/health
curl -s http://localhost:8003/health && curl -s http://localhost:8004/health

# Local — MCP (requiere Catalog, Inventory, Analytics activos)
curl -s http://localhost:8005/health

# Kubernetes
kubectl get pods -n shopdemo
kubectl get ingress -n shopdemo
```

### Orden recomendado al arrancar (local)

1. **Catalog** → 2. **Inventory** → 3. **Orders** (Orders llama a Inventory) → 4. **Analytics** (opcional, etapa 6+) → 5. **MCP** (opcional, etapa 14+, requiere 8001/8003/8004)

---

## Inicio local (desarrollo y pruebas)

### Requisitos previos

```bash
dotnet build ShopDemo.slnx    # compila la solución
docker --version            # Docker Desktop en ejecución
```

| Herramienta | Obligatorio para | Enlace |
|---|---|---|
| .NET 10 SDK | Aspire / `dotnet run` | [Descargar](https://dotnet.microsoft.com/download) |
| Docker Desktop | Compose y builds | [Descargar](https://www.docker.com/products/docker-desktop/) |
| Minikube + kubectl | Solo modo Kubernetes local | [Minikube](https://minikube.sigs.k8s.io/docs/start/) |

### URLs locales (todos los modos)

| Servicio | URL base | Swagger | Health |
|---|---|---|---|
| Catalog | http://localhost:8001 | http://localhost:8001/swagger | http://localhost:8001/health |
| Orders | http://localhost:8002 | http://localhost:8002/swagger | http://localhost:8002/health |
| Inventory | http://localhost:8003 | http://localhost:8003/swagger | http://localhost:8003/health |
| Analytics | http://localhost:8004 | http://localhost:8004/swagger | http://localhost:8004/health |
| MCP Gateway | http://localhost:8005/mcp | — | http://localhost:8005/health |

> **Postman:** importa [ShopDemo.postman_collection.json](docs/ShopDemo.postman_collection.json) — las variables ya apuntan a `localhost`. Ver [Configurar Postman](#configurar-postman-según-entorno).

---

### Opción A — Docker Compose (recomendada para empezar)

**Cuándo usarla:** etapas 1–5; quieres levantar un servicio aislado con su PostgreSQL.

**Orden:** Catalog e Inventory primero; luego Orders (Orders llama a Inventory).

| Paso | Acción | Terminal |
|---|---|---|
| 1 | Catalog + PostgreSQL | `cd Catalog/ShopDemo.Catalog.Api` → `copy .env.example .env` → `docker compose up --build` |
| 2 | Inventory + PostgreSQL + Azurite | `cd Inventory/ShopDemo.Inventory.Api` → `docker compose up --build` |
| 3 | Orders + PostgreSQL | `cd Orders/ShopDemo.Orders.Api` → `docker compose up --build` |
| 4 | Analytics (opcional, etapa 6+) | `cd Aspire/ShopDemo.Analytics.Api` → `docker compose up --build` |
| 5 | MCP Gateway (opcional, etapa 14+) | `cd AI/ShopDemo.Mcp.Api` → `copy .env.example .env` → `docker compose up --build` |

**Verificar:**

```bash
curl http://localhost:8001/health
curl http://localhost:8003/health
curl http://localhost:8002/health
curl http://localhost:8004/health   # si Analytics está activo
curl http://localhost:8005/health   # si MCP está activo
```

**Event Hubs (opcional):** edita `.env` en cada API con `EVENT_HUBS_ENABLED=true` y la connection string. Guía: [INTEGRACION-AZURE-EVENT-HUBS.md](docs/INTEGRACION-AZURE-EVENT-HUBS.md).

**Detener:** `Ctrl+C` en cada terminal o `docker compose down`.

---

### Opción B — .NET Aspire (stack completo en un comando)

**Cuándo usarla:** etapa 6; quieres las 4 APIs + PostgreSQL + Azurite + dashboard sin varias terminales.

| Paso | Comando |
|---|---|
| 1 | Configurar Event Hubs (una vez): `dotnet user-secrets set "ShopDemo:EventHubs:ConnectionString" "<CONNECTION_STRING>" --project Aspire/ShopDemo.AppHost` |
| 2 | Arrancar todo: `dotnet run --project Aspire/ShopDemo.AppHost` |
| 3 | Abrir **Aspire Dashboard** (URL que muestra la consola) |

Los puertos siguen siendo **8001–8004**. El AppHost inyecta `EventHubs__*` y la URL de Inventory para Orders.

Guía: [IMPLEMENTACION-ANALYTICS-ASPIRE.md](docs/analytics/IMPLEMENTACION-ANALYTICS-ASPIRE.md)

---

### Opción C — `dotnet run` (depuración en Visual Studio / Cursor)

**Cuándo usarla:** depurar un solo microservicio con breakpoints.

Requiere PostgreSQL accesible en `localhost:5433`–`5435` (vía Compose de cada BD o instancia local).

```bash
dotnet run --project Catalog/ShopDemo.Catalog.Api
dotnet run --project Orders/ShopDemo.Orders.Api
dotnet run --project Inventory/ShopDemo.Inventory.Api
dotnet run --project Aspire/ShopDemo.Analytics.Api
dotnet run --project AI/ShopDemo.Mcp.Api    # etapa 14+; requiere 8001, 8003, 8004
```

---

### Opción E — MCP Gateway (integración IA)

**Cuándo usarla:** etapa 14–14b; conectar Cursor o Claude Code al servidor MCP.

| Paso | Comando |
|---|---|
| 1 | Asegurar Catalog (8001), Inventory (8003) y Analytics (8004) activos |
| 2 | `cd AI/ShopDemo.Mcp.Api` → `copy .env.example .env` (URLs de APIs) |
| 3 | `dotnet run --project AI/ShopDemo.Mcp.Api` o `docker compose up --build` |
| 4 | Probar: `curl http://localhost:8005/health` y endpoint MCP `http://localhost:8005/mcp` |

Guía: [docs/integracion-ia/README.md](docs/integracion-ia/README.md) · Despliegue nube: [Azure](docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) · [AWS](docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md)

---

### Opción D — Kubernetes local (Minikube)

**Cuándo usarla:** etapa 9; practicar manifiestos antes de AKS/EKS.

| Paso | Resumen |
|---|---|
| 1 | `minikube start` + `minikube addons enable ingress` |
| 2 | Build imágenes en daemon Minikube (`minikube docker-env`) |
| 3 | `kubectl apply -f k8s/` (ver orden en [k8s/README.md](k8s/README.md)) |

Guía completa: [IMPLEMENTACION-KUBERNETES-LOCAL.md](docs/despliegue/kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md)

**Postman con Ingress:** `catalogBaseUrl` = `http://shopdemo.local/catalog` (tras configurar hosts o `minikube tunnel`).

Incluye **5 APIs** (Catalog, Orders, Inventory, Analytics, MCP) + PostgreSQL + Azurite. Orden de apply: [k8s/README.md](k8s/README.md).

---

## Release Azure

Dos caminos de **release** en Azure. Ambos usan imágenes en **Azure Container Registry (ACR)** y despliegan **5 contenedores** (4 APIs de negocio + MCP Gateway).

| Camino | Servicio Azure | Ideal para | Guía |
|---|---|---|---|
| **ACA** | Container Apps | Release serverless, más simple | [IMPLEMENTACION-DESPLIEGUE-AZURE](docs/despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md) |
| **AKS** | Kubernetes Service | Release con manifiestos `k8s/` | [IMPLEMENTACION-DESPLIEGUE-AKS](docs/despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md) |

### Arranque en Azure (resumen)

| # | Acción | ACA (Container Apps) | AKS |
|---|---|---|---|
| 1 | **Build y push** imágenes a ACR | `shopdemo-catalog`, `orders`, `inventory`, `analytics`, `mcp` | Igual |
| 2 | **Infraestructura** | RG + ACR + Environment ACA | RG + ACR + cluster AKS + Ingress NGINX |
| 3 | **Desplegar APIs** | Crear 5 Container Apps (MCP opcional etapa 14b) | `kubectl apply -f k8s/` (orden en [k8s/README.md](k8s/README.md)) |
| 4 | **Secretos** | `EventHubs__*`, PostgreSQL, checkpoints Blob | `k8s/secrets.yaml` desde `secrets.example.yaml` |
| 5 | **Verificar** | `curl https://<fqdn>/health` por app | `kubectl get pods -n shopdemo` + Ingress |
| 6 | **Postman** | Actualizar variables con FQDN de cada ACA | URLs con prefijo Ingress (`/catalog`, …, `/mcp`) |

### Flujo común release Azure

```mermaid
flowchart LR
    A[docker build] --> B[docker push ACR]
    B --> C{Destino}
    C -->|ACA| D[Container Apps]
    C -->|AKS| E[kubectl apply k8s/]
    D & E --> F[Probar con Postman]
```

| Paso | ACA (Container Apps) | AKS |
|---|---|---|
| 1 | Crear RG + ACR | Crear RG + ACR + cluster AKS |
| 2 | `docker push` 5 imágenes a ACR | `az aks get-credentials` + push ACR |
| 3 | Crear 5 Container Apps | Instalar Ingress NGINX |
| 4 | Secrets `EventHubs__*` en cada app | `kubectl apply -f k8s/` (postgres → APIs → mcp → ingress) |
| 5 | Copiar FQDN de cada app | Copiar IP/DNS del Ingress (`shopdemo.local` o IP pública) |
| 6 | MCP: [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE](docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) | Ruta Ingress `/mcp` en `k8s/ingress/` |

### URLs release Azure (Postman)

Tras desplegar, actualiza las variables de colección:

| Variable Postman | Origen (ACA) | Origen (AKS Ingress) |
|---|---|---|
| `catalogBaseUrl` | `https://ca-shopdemo-catalog.<fqdn>` | `http://<ingress-ip>/catalog` |
| `ordersBaseUrl` | `https://ca-shopdemo-orders.<fqdn>` | `http://<ingress-ip>/orders` |
| `inventoryBaseUrl` | URL **interna** o pública si expusiste | `http://<ingress-ip>/inventory` |
| `analyticsBaseUrl` | `https://ca-shopdemo-analytics.<fqdn>` | `http://<ingress-ip>/analytics` |
| MCP (agente) | `https://ca-shopdemo-mcp.<fqdn>/mcp` | `http://<ingress-ip>/mcp` |

**Secrets obligatorios en nube:** `EventHubs__ConnectionString`, connection strings PostgreSQL, Azurite/checkpoint para Inventory y Analytics, URLs internas de APIs para Orders y MCP.

**Observabilidad y resiliencia:** [docs/observabilidad/azure/](docs/observabilidad/azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md) · [docs/resiliencia/azure/](docs/resiliencia/azure/IMPLEMENTACION-RESILIENCIA-AZURE.md)

CI/CD: [.github/workflows/deploy-azure.yml](.github/workflows/deploy-azure.yml) (incluye `shopdemo-mcp`)

---

## Release AWS

Dos caminos de **release** en AWS. Ambos usan **Amazon ECR** y despliegan **5 contenedores** (4 APIs + MCP).

| Camino | Servicio AWS | Ideal para | Guía |
|---|---|---|---|
| **ECS** | Fargate | Release sin Kubernetes | [IMPLEMENTACION-DESPLIEGUE-AWS](docs/despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md) |
| **EKS** | Elastic Kubernetes Service | Release con manifiestos `k8s/` | [IMPLEMENTACION-DESPLIEGUE-EKS](docs/despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md) |

### Arranque en AWS (resumen)

| # | Acción | ECS Fargate | EKS |
|---|---|---|---|
| 1 | **Build y push** a ECR | 5 repos/imágenes | Igual |
| 2 | **Infraestructura** | Cluster ECS + ALB por API pública | Cluster EKS + Ingress NGINX + EBS CSI |
| 3 | **Desplegar** | Task definitions + services + Cloud Map | `kubectl apply -f k8s/` |
| 4 | **Secretos** | SSM Parameter Store / Secrets Manager | `k8s/secrets.yaml` |
| 5 | **Verificar** | `curl http://<alb-dns>/health` | `kubectl get pods -n shopdemo` |
| 6 | **MCP** | [IMPLEMENTACION-DESPLIEGUE-MCP-AWS](docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md) | Ingress `/mcp` |

### Flujo común release AWS

| Paso | ECS Fargate | EKS |
|---|---|---|
| 1 | Crear repos ECR (5 imágenes) | `eksctl create cluster` o Consola EKS |
| 2 | `docker push` a ECR | `aws eks update-kubeconfig` |
| 3 | Task definitions + services (5) | EBS CSI + Ingress NGINX |
| 4 | ALB por API pública + Cloud Map Orders→Inventory | `kubectl apply -f k8s/` |
| 5 | MCP en ALB o service interno | Ingress `/mcp` |

### URLs release AWS (Postman)

| Variable Postman | Origen (ECS + ALB) | Origen (EKS Ingress) |
|---|---|---|
| `catalogBaseUrl` | `http://<alb-catalog-dns>` | `http://<ingress-host>/catalog` |
| `ordersBaseUrl` | `http://<alb-orders-dns>` | `http://<ingress-host>/orders` |
| `inventoryBaseUrl` | DNS interno Cloud Map o ALB | `http://<ingress-host>/inventory` |
| `analyticsBaseUrl` | `http://<alb-analytics-dns>` | `http://<ingress-host>/analytics` |
| MCP (agente) | `http://<alb-mcp-dns>/mcp` | `http://<ingress-host>/mcp` |

**Nota:** el código usa **Azure Event Hubs**; los contenedores en AWS necesitan salida HTTPS a internet hacia Azure.

**Observabilidad y resiliencia:** [docs/observabilidad/aws/](docs/observabilidad/aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md) · [docs/resiliencia/aws/](docs/resiliencia/aws/IMPLEMENTACION-RESILIENCIA-AWS.md)

CI/CD: [.github/workflows/deploy-aws.yml](.github/workflows/deploy-aws.yml) (incluye `shopdemo-mcp`)

---

## Configurar Postman según entorno

1. Importar [docs/ShopDemo.postman_collection.json](docs/ShopDemo.postman_collection.json)
2. En la colección → **Variables**, elegir el perfil:

| Perfil | `deploymentProfile` | Qué cambiar |
|---|---|---|
| **Local** (default) | `local` | Ya configurado: `localhost:8001`–`8005` |
| **Azure ACA** | `azure-aca` | `catalogBaseUrl`, `ordersBaseUrl`, `inventoryBaseUrl`, `analyticsBaseUrl`, `mcpBaseUrl` |
| **Azure AKS** | `azure-aks` | URLs con prefijo de Ingress (`/catalog`, `/orders`, …, `/mcp`) |
| **AWS ECS** | `aws-ecs` | DNS de cada ALB + `mcpBaseUrl` |
| **AWS EKS** | `aws-eks` | Igual que AKS con Ingress |

3. Ejecutar carpeta **Health checks** (recomendado antes del E2E)
4. Ejecutar carpeta **Flujo integrado (E2E)** en orden
5. Tras crear producto/pedido, copiar `id` de la respuesta a variables `productId` / `orderId`

Con **Event Hubs activo**, el paso 2 del E2E (registrar stock) puede omitirse; usa **Analytics → Listar eventos** para validar.

---

## Checklist antes del flujo E2E

| # | Verificación | Local Compose | Aspire | Release nube |
|---|---|---|---|---|
| 1 | APIs responden `/health` | ✓ 8001–8004 | ✓ 8001–8004 | ✓ FQDN/Ingress |
| 2 | Orders alcanza Inventory | `host.docker.internal:8003` | automático | URL interna configurada |
| 3 | PostgreSQL accesible | compose por API | Aspire PG | ACI/ECS/StatefulSet |
| 4 | Event Hubs (si aplica) | `.env` | user secrets AppHost | Secrets ACA/EKS/SSM |
| 5 | Postman variables actualizadas | localhost | localhost | FQDN release |
| 6 | MCP (etapa 14+) | `8005/health` | manual | `/mcp` en Ingress/ALB |
| 7 | Analytics lista eventos | `GET /api/analytics/events` | AppHost | Ingress `/analytics` |

---

## Variables de configuración

### Resumen por servicio

| Servicio | Archivo principal | Variables clave |
|---|---|---|
| **Catalog** | `appsettings.json` + `.env` | `ConnectionStrings__DefaultConnection`, `EventHubs__*` |
| **Orders** | `appsettings.json` + `.env` | `ConnectionStrings__*`, `InventoryApi__BaseUrl`, `EventHubs__*` |
| **Inventory** | `appsettings.json` + `.env` | `ConnectionStrings__*`, `EventHubs__*` + consumer/checkpoint |
| **Analytics** | `appsettings.json` + `.env` | `EventHubs__*` + consumer/checkpoint |
| **AppHost** | `appsettings.Development.json` o user secrets | `ShopDemo:EventHubs:ConnectionString` |

### Catalog — `Catalog/ShopDemo.Catalog.Api/`

| Variable | Dónde configurarla | Ejemplo / notas |
|---|---|---|
| `ConnectionStrings__DefaultConnection` | `appsettings.json`, `docker-compose.yml` | Host `catalog-db` en Docker; `localhost:5433` en dev |
| `EventHubs__Enabled` | `.env`, compose, ACA/ECS | `true` / `false` |
| `EventHubs__ConnectionString` | `.env` (no commitear) | Connection string del namespace Azure |
| `EventHubs__EventHubName` | `.env`, compose | `shopdemo-events` |

Archivo plantilla: `Catalog/ShopDemo.Catalog.Api/.env.example`

### Orders — `Orders/ShopDemo.Orders.Api/`

| Variable | Dónde configurarla | Ejemplo / notas |
|---|---|---|
| `ConnectionStrings__DefaultConnection` | `appsettings.json`, compose | Puerto host `5434` |
| `InventoryApi__BaseUrl` | `appsettings.json`, compose, ACA, ECS | `http://localhost:8003` · Docker: `http://host.docker.internal:8003` · Aspire: automático · Nube: URL interna Inventory |
| `EventHubs__Enabled` | `.env`, compose | Igual que Catalog |
| `EventHubs__ConnectionString` | `.env` | Igual que Catalog |
| `EventHubs__EventHubName` | `.env` | `shopdemo-events` |

Archivo plantilla: `Orders/ShopDemo.Orders.Api/.env.example`

### Inventory — `Inventory/ShopDemo.Inventory.Api/`

| Variable | Dónde configurarla | Ejemplo / notas |
|---|---|---|
| `ConnectionStrings__DefaultConnection` | `appsettings.json`, compose | Puerto host `5435` |
| `EventHubs__Enabled` | `.env`, compose | `true` activa publisher + `CatalogEventsProcessor` |
| `EventHubs__ConnectionString` | `.env` | Connection string Azure |
| `EventHubs__ConsumerGroup` | compose, ACA, ECS | `inventory-service` |
| `EventHubs__CheckpointStorageConnectionString` | `.env`, compose | Azurite local; Blob en nube |
| `EventHubs__CheckpointContainerName` | compose | `inventory-checkpoints` |

Archivo plantilla: `Inventory/ShopDemo.Inventory.Api/.env.example`

### Analytics — `Aspire/ShopDemo.Analytics.Api/`

| Variable | Dónde configurarla | Ejemplo / notas |
|---|---|---|
| `EventHubs__Enabled` | compose, ACA, ECS | `true` |
| `EventHubs__ConnectionString` | `.env`, AppHost | Desde AppHost en Aspire |
| `EventHubs__ConsumerGroup` | compose | `analytics-service` |
| `EventHubs__CheckpointStorageConnectionString` | compose | Azurite (`azurite:10000` en compose) |
| `EventHubs__CheckpointContainerName` | compose | `analytics-checkpoints` |

Archivo plantilla: `Aspire/ShopDemo.Analytics.Api/.env.example`

### AppHost Aspire — `Aspire/ShopDemo.AppHost/`

| Variable | Dónde configurarla | Ejemplo / notas |
|---|---|---|
| `ShopDemo:EventHubs:ConnectionString` | `appsettings.Development.json` o **user secrets** | Centraliza EH para los 4 APIs |
| `ShopDemo:EventHubs:EventHubName` | `appsettings.json` | `shopdemo-events` |
| `ShopDemo:EventHubs:Enabled` | `appsettings.json` | `true` |

El AppHost inyecta a cada API como `EventHubs__*` y configura `InventoryApi__BaseUrl` para Orders.

### MCP Gateway — `AI/ShopDemo.Mcp.Api/`

| Variable | Dónde configurarla | Ejemplo / notas |
|---|---|---|
| `CatalogApi__BaseUrl` | `.env`, compose, ACA, ECS | `http://localhost:8001` · K8s: `http://shopdemo-catalog:8080` |
| `InventoryApi__BaseUrl` | `.env`, compose | `http://localhost:8003` |
| `AnalyticsApi__BaseUrl` | `.env`, compose | `http://localhost:8004` |

Archivo plantilla: `AI/ShopDemo.Mcp.Api/.env.example`

### Plataformas en nube (release)

| Plataforma | Dónde poner secretos | Documentación |
|---|---|---|
| **Azure Container Apps** | Secrets de cada Container App | [despliegue/azure](docs/despliegue/azure/) |
| **Azure AKS** | Secrets K8s / Key Vault | [despliegue/aks](docs/despliegue/aks/) |
| **AWS ECS** | SSM Parameter Store / Secrets Manager | [despliegue/aws](docs/despliegue/aws/) |
| **Amazon EKS** | Secrets K8s / Parameter Store | [despliegue/eks](docs/despliegue/eks/) |
| **GitHub Actions** | Repository secrets | [.github/workflows/](.github/workflows/) |

> **Regla:** nunca commitear connection strings reales. Usa `.env` local (gitignored), user secrets o secretos de la plataforma.

---

## Prueba rápida del flujo integrado

1. Elige modo de ejecución: [Inicio local](#inicio-local-desarrollo-y-pruebas) o [Release](#release-azure).
2. Completa el [checklist E2E](#checklist-antes-del-flujo-e2e).
3. Importa y configura [Postman](#configurar-postman-según-entorno).
4. Ejecuta carpeta **Flujo integrado (E2E)** o sigue [GUIA-ENDPOINTS.md](docs/GUIA-ENDPOINTS.md).

Con Event Hubs activo, el stock se auto-registra y Analytics lista eventos en `GET /api/analytics/events`.

---

## Estructura del repositorio

```
ShopDemo/
├── Catalog/          # Clean Architecture — catálogo
├── Orders/           # Clean Architecture — pedidos
├── Inventory/        # Hexagonal — stock
├── AI/               # MCP Gateway (ShopDemo.Mcp.Api :8005)
├── Aspire/           # AppHost, ServiceDefaults, Analytics
├── ShopDemo.Shared/  # Kernel DDD + mensajería
├── k8s/              # Manifiestos Kubernetes (5 APIs + PG + Ingress)
├── spec-driven/      # Specs, plantillas Cursor y Claude Code
├── docs/             # Toda la documentación del curso
└── .github/workflows/  # CI/CD Azure y AWS (incluye shopdemo-mcp)
```

---

## Documentación índice

| Tema | Enlace |
|---|---|
| **Guía de desarrollo (código paso a paso)** | [docs/GUIA-DESARROLLO-INTEGRACIONES.md](docs/GUIA-DESARROLLO-INTEGRACIONES.md) |
| Anexos de código | [Shared](docs/ANEXO-CODIGO-SHARED.md) · [Catalog](docs/catalog/ANEXO-CODIGO-CATALOG.md) · [Orders](docs/orders/ANEXO-CODIGO-ORDERS.md) · [Inventory](docs/inventory/ANEXO-CODIGO-INVENTORY.md) · [Event Hubs](docs/ANEXO-CODIGO-EVENT-HUBS.md) · [Analytics/Aspire](docs/analytics/ANEXO-CODIGO-ANALYTICS-ASPIRE.md) · [MCP](docs/integracion-ia/ANEXO-CODIGO-MCP.md) |
| Arquitectura | [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md) |
| Endpoints y Postman | [docs/GUIA-ENDPOINTS.md](docs/GUIA-ENDPOINTS.md) |
| Event Hubs | [docs/INTEGRACION-AZURE-EVENT-HUBS.md](docs/INTEGRACION-AZURE-EVENT-HUBS.md) |
| Aspire | [docs/INTEGRACION-ASPIRE.md](docs/INTEGRACION-ASPIRE.md) |
| Despliegue | [docs/despliegue/README.md](docs/despliegue/README.md) |
| Observabilidad | [docs/observabilidad/README.md](docs/observabilidad/README.md) |
| Resiliencia | [docs/resiliencia/README.md](docs/resiliencia/README.md) |
| Integración IA | [docs/integracion-ia/README.md](docs/integracion-ia/README.md) |
| Spec-driven (Cursor + Claude) | [spec-driven/README.md](spec-driven/README.md) |
| Cheat sheets CLI | [docs/cheat-sheets/](docs/cheat-sheets/) |
| Teoría Docker, K8s y AOT | [docs/TEORIA-DOCKER-KUBERNETES-AOT.md](docs/TEORIA-DOCKER-KUBERNETES-AOT.md) |
| Manifiestos Kubernetes | [k8s/](k8s/) |

---

## Requisitos técnicos

- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Opcional: [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), [AWS CLI](https://aws.amazon.com/cli/)
- Opcional: cuenta Azure con Event Hubs para etapas 5–8

```bash
dotnet build ShopDemo.slnx
```
