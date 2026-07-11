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
6. **Desplegar** en Kubernetes (Minikube, AKS, EKS) con manifiestos compartidos `k8s/` y deployments en `k8s/local/`, `k8s/azure/` o `k8s/aws/`.
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

**Documentación técnica completa:** [Documentación_Del_Proyecto/ARQUITECTURA.md](Documentación_Del_Proyecto/ARQUITECTURA.md)

---

## Estructura de la documentación (3 capas)

Cada módulo del curso separa **negocio**, **especificación técnica** y **pedagogía**:

| Capa | Archivos | Para quién |
|---|---|---|
| **A — Negocio** | `REQUERIMIENTOS-*.md`, `HISTORIAS-USUARIO-*.md` | PM, analista, negocio, junior que entiende el dominio |
| **B — Técnica** | `ANEXO-ESPECIFICACION-TECNICA-*.md`, `ANEXO-HISTORIAS-TECNICAS-*.md` | Desarrollador implementador |
| **C — Pedagogía** | `ANEXO-PEDAGOGIA-*.md` | Instructor y alumno del curso |

**Guía completa:** [Documentación_Del_Proyecto/GUIA-ESTRUCTURA-DOCUMENTACION.md](Documentación_Del_Proyecto/GUIA-ESTRUCTURA-DOCUMENTACION.md)

**Orden sugerido (alumno):** Requerimientos (negocio) → Historias → Anexo técnico → Implementación → Anexo pedagogía.

---

## Etapas del curso (roadmap)

Cada etapa tiene documentación en **3 capas**: **requerimientos de negocio** (qué debe lograr el sistema), **anexos técnicos** (cómo implementarlo) e **implementación** (paso a paso). Ver [GUIA-ESTRUCTURA-DOCUMENTACION.md](Documentación_Del_Proyecto/GUIA-ESTRUCTURA-DOCUMENTACION.md).

**Guía de desarrollo con código para copiar/integrar (recomendada para alumnos):** [GUIA-DESARROLLO-INTEGRACIONES.md](Documentación_Del_Proyecto/GUIA-DESARROLLO-INTEGRACIONES.md) — paso a paso por etapa, anexos con `.cs` completos y checklist de validación.

| Etapa | Tema | Requerimientos | Implementación | Cómo validar |
|---|---|---|---|---|
| **0** | Visión y endpoints | — | [GUIA-ENDPOINTS](Documentación_Del_Proyecto/GUIA-ENDPOINTS.md) | Postman E2E |
| **1** | Catalog (Clean + CQRS) | [REQUERIMIENTOS-CATALOG](Documentación_Del_Proyecto/catalog/REQUERIMIENTOS-CATALOG.md) | [IMPLEMENTACION-CATALOG](Documentación_Del_Proyecto/catalog/IMPLEMENTACION-CATALOG.md) | `POST /api/products` |
| **2** | Orders (Clean + CQRS) | [REQUERIMIENTOS-ORDERS](Documentación_Del_Proyecto/orders/REQUERIMIENTOS-ORDERS.md) | [IMPLEMENTACION-ORDERS](Documentación_Del_Proyecto/orders/IMPLEMENTACION-ORDERS.md) | Crear y confirmar pedido |
| **3** | Inventory (Hexagonal) | [REQUERIMIENTOS-INVENTORY](Documentación_Del_Proyecto/inventory/REQUERIMIENTOS-INVENTORY.md) | [IMPLEMENTACION-INVENTORY](Documentación_Del_Proyecto/inventory/IMPLEMENTACION-INVENTORY.md) | Stock y reservas |
| **4** | Integración E2E | [GUIA-ENDPOINTS](Documentación_Del_Proyecto/GUIA-ENDPOINTS.md) | [ARQUITECTURA §4](Documentación_Del_Proyecto/ARQUITECTURA.md#4-integración-entre-bounded-contexts) | Flujo compra completo |
| **5** | Azure Event Hubs | [INTEGRACION-AZURE-EVENT-HUBS](Documentación_Del_Proyecto/INTEGRACION-AZURE-EVENT-HUBS.md) | Mismo doc (paso a paso) | Auto-stock + eventos en log |
| **6** | Aspire + Analytics | [REQUERIMIENTOS-ANALYTICS-ASPIRE](Documentación_Del_Proyecto/analytics/REQUERIMIENTOS-ANALYTICS-ASPIRE.md) | [IMPLEMENTACION-ANALYTICS-ASPIRE](Documentación_Del_Proyecto/analytics/IMPLEMENTACION-ANALYTICS-ASPIRE.md) | `GET /api/analytics/events` |
| **7** | Docker → Azure | [REQUERIMIENTOS-DESPLIEGUE-AZURE](Documentación_Del_Proyecto/despliegue/azure/REQUERIMIENTOS-DESPLIEGUE-AZURE.md) | [IMPLEMENTACION-DESPLIEGUE-AZURE](Documentación_Del_Proyecto/despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md) · [Script/CLI/Portal](Documentación_Del_Proyecto/despliegue/azure/GUIA-RELEASE-SCRIPT-AZURE.md) | Swagger en 5 Container Apps |
| **8** | Docker → AWS | [REQUERIMIENTOS-DESPLIEGUE-AWS](Documentación_Del_Proyecto/despliegue/aws/REQUERIMIENTOS-DESPLIEGUE-AWS.md) | [IMPLEMENTACION-DESPLIEGUE-AWS](Documentación_Del_Proyecto/despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md) · [Script/CLI/Portal](Documentación_Del_Proyecto/despliegue/aws/GUIA-RELEASE-SCRIPT-AWS.md) | Swagger en ALB ECS |
| **9** | Kubernetes local (Minikube) | [REQUERIMIENTOS-KUBERNETES](Documentación_Del_Proyecto/despliegue/kubernetes/REQUERIMIENTOS-KUBERNETES.md) | [IMPLEMENTACION-KUBERNETES-LOCAL](Documentación_Del_Proyecto/despliegue/kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md) · [Teoría K8s](Documentación_Del_Proyecto/despliegue/kubernetes/TEORIA-KUBERNETES-OPERACIONES.md) | `kubectl get hpa -n shopdemo` |
| **10** | Azure AKS | [REQUERIMIENTOS-DESPLIEGUE-AKS](Documentación_Del_Proyecto/despliegue/aks/REQUERIMIENTOS-DESPLIEGUE-AKS.md) | [IMPLEMENTACION-DESPLIEGUE-AKS](Documentación_Del_Proyecto/despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md) · [Script `-Mode AKS`](Source/scripts/azure/README.md) | Swagger vía Ingress o LB `:8080` |
| **11** | Amazon EKS | [REQUERIMIENTOS-DESPLIEGUE-EKS](Documentación_Del_Proyecto/despliegue/eks/REQUERIMIENTOS-DESPLIEGUE-EKS.md) | [IMPLEMENTACION-DESPLIEGUE-EKS](Documentación_Del_Proyecto/despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md) · [Script `-Mode EKS`](Source/scripts/aws/README.md) | Swagger vía LB `:8080` (perfil free-tier) |
| **12** | Observabilidad | [REQUERIMIENTOS-OBSERVABILIDAD](Documentación_Del_Proyecto/observabilidad/REQUERIMIENTOS-OBSERVABILIDAD.md) | [Azure](Documentación_Del_Proyecto/observabilidad/azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md) · [AWS](Documentación_Del_Proyecto/observabilidad/aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md) | Logs + alerta + traceId |
| **13** | Resiliencia | [REQUERIMIENTOS-RESILIENCIA](Documentación_Del_Proyecto/resiliencia/REQUERIMIENTOS-RESILIENCIA.md) | [Azure](Documentación_Del_Proyecto/resiliencia/azure/IMPLEMENTACION-RESILIENCIA-AZURE.md) · [AWS](Documentación_Del_Proyecto/resiliencia/aws/IMPLEMENTACION-RESILIENCIA-AWS.md) | Recuperación tras fallo de pod/tarea |
| **14** | Integración IA | [REQUERIMIENTOS-INTEGRACION-IA](Documentación_Del_Proyecto/integracion-ia/REQUERIMIENTOS-INTEGRACION-IA.md) | [IMPLEMENTACION-MCP-GATEWAY](Documentación_Del_Proyecto/integracion-ia/IMPLEMENTACION-MCP-GATEWAY.md) · [Azure](Documentación_Del_Proyecto/integracion-ia/azure/IMPLEMENTACION-INTEGRACION-IA-AZURE.md) · [AWS](Documentación_Del_Proyecto/integracion-ia/aws/IMPLEMENTACION-INTEGRACION-IA-AWS.md) | MCP tool + alerta KQL/Insights |
| **14b** | Despliegue MCP Gateway | [REQUERIMIENTOS-DESPLIEGUE-MCP](Documentación_Del_Proyecto/integracion-ia/REQUERIMIENTOS-DESPLIEGUE-MCP.md) | [Azure ACA/AKS](Documentación_Del_Proyecto/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) · [AWS ECS/EKS](Documentación_Del_Proyecto/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md) | `curl .../mcp` + agente |
| **15** | Spec-driven (Cursor + Claude Code) | [REQUERIMIENTOS-SPEC-DRIVEN](spec-driven/REQUERIMIENTOS-SPEC-DRIVEN-DEVELOPMENT.md) | [IMPLEMENTACION-SPEC-DRIVEN](spec-driven/IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md) | Agente sigue `spec-driven/specs/<módulo>/SPEC.md` |

**Tópicos de Estudio (teoría general):** [Índice — 13 tópicos](Documentación_De_Estudio_Del_Curso/README.md) (patrones, arquitectura, DDD, microservicios, Azure, AWS, contenedores/Docker, K8s, CI/CD, observabilidad, resiliencia, IA/MCP, síntesis)

**Teoría práctica ShopDemo (lab):** [Docker/K8s/AOT](Documentación_Del_Proyecto/TEORIA-DOCKER-KUBERNETES-AOT.md) · [Observabilidad](Documentación_Del_Proyecto/observabilidad/TEORIA-OBSERVABILIDAD.md) · [Resiliencia](Documentación_Del_Proyecto/resiliencia/TEORIA-RESILIENCIA.md) · [Integración IA](Documentación_Del_Proyecto/integracion-ia/TEORIA-INTEGRACION-IA.md) · [Spec-driven](spec-driven/TEORIA-SPEC-DRIVEN-DEVELOPMENT.md) · [AKS](Documentación_Del_Proyecto/despliegue/aks/TEORIA-AKS.md) · [EKS](Documentación_Del_Proyecto/despliegue/eks/TEORIA-EKS.md) · [Azure ACA](Documentación_Del_Proyecto/despliegue/azure/TEORIA-CONTENEDORES-AZURE.md) · [AWS ECS](Documentación_Del_Proyecto/despliegue/aws/TEORIA-CONTENEDORES-AWS.md)

---

## Guía rápida: ¿qué modo de ejecución uso?

| Si quieres… | Modo | Sección |
|---|---|---|
| Desarrollar o probar **en tu PC** sin nube | **Local** | [Inicio local](#inicio-local-desarrollo-y-pruebas) |
| Publicar a **Azure** (release) | **Azure** | [Release Azure](#release-azure) |
| Publicar a **AWS** (release) | **AWS** | [Release AWS](#release-aws) |

### Tres enfoques equivalentes por nube (elige uno)

Cada plataforma tiene **Script**, **CLI** y **Portal** con el mismo alcance. El script es el camino más rápido; CLI y Portal sirven para aprender la consola paso a paso.

| Nube | Preparación | Script (recomendado) | CLI manual | Portal visual |
|---|---|---|---|---|
| **Azure** | [PREPARACION-AMBIENTE-AZURE](Documentación_Del_Proyecto/despliegue/azure/PREPARACION-AMBIENTE-AZURE.md) | [GUIA-RELEASE-SCRIPT-AZURE](Documentación_Del_Proyecto/despliegue/azure/GUIA-RELEASE-SCRIPT-AZURE.md) | [GUIA-RELEASE-CLI-AZURE](Documentación_Del_Proyecto/despliegue/azure/GUIA-RELEASE-CLI-AZURE.md) | [GUIA-RELEASE-PORTAL-AZURE](Documentación_Del_Proyecto/despliegue/azure/GUIA-RELEASE-PORTAL-AZURE.md) |
| **AWS** | [PREPARACION-AMBIENTE-AWS](Documentación_Del_Proyecto/despliegue/aws/PREPARACION-AMBIENTE-AWS.md) | [GUIA-RELEASE-SCRIPT-AWS](Documentación_Del_Proyecto/despliegue/aws/GUIA-RELEASE-SCRIPT-AWS.md) | [GUIA-RELEASE-CLI-AWS](Documentación_Del_Proyecto/despliegue/aws/GUIA-RELEASE-CLI-AWS.md) | [GUIA-RELEASE-PORTAL-AWS](Documentación_Del_Proyecto/despliegue/aws/GUIA-RELEASE-PORTAL-AWS.md) |
| **Kubernetes** | Manifiestos `k8s/` | Script `-Mode AKS` / `-Mode EKS` | Secciones AKS/EKS en guías CLI | Secciones AKS/EKS en guías Portal |

**Reportes de release validados (lab):** [AKS](Source/scripts/azure/deploy-aks-report.json) · [EKS free-tier](Source/scripts/aws/deploy-eks-free-tier-report.json) · [EKS completo](Source/scripts/aws/deploy-eks-report.json)

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
| **Catalog** | 8001 | `/health` | `Source/Catalog/.../docker compose up` | AppHost | `dotnet run --project Source/Catalog/...` | `k8s/local/catalog/` | Container App | Ingress `/catalog` (`k8s/azure/`) | ALB dedicado | Ingress `/catalog` (`k8s/aws/`) |
| **Orders** | 8002 | `/health` | `Source/Orders/.../docker compose up` | AppHost | `dotnet run --project Source/Orders/...` | `k8s/local/orders/` | Container App | Ingress `/orders` | ALB dedicado | Ingress `/orders` |
| **Inventory** | 8003 | `/health` | `Source/Inventory/.../docker compose up` | AppHost | `dotnet run --project Source/Inventory/...` | `k8s/local/inventory/` | Container App (interno) | Ingress `/inventory` | Cloud Map / ALB | Ingress `/inventory` |
| **Analytics** | 8004 | `/health` | `Source/Aspire/.../docker compose up` | AppHost | `dotnet run --project Source/Aspire/...` | `k8s/local/analytics/` | Container App | Ingress `/analytics` | ALB dedicado | Ingress `/analytics` |
| **MCP Gateway** | 8005 | `/health` | `Source/AI/.../docker compose up` | Manual* | `dotnet run --project Source/AI/...` | `k8s/local/mcp/` | Container App | Ingress `/mcp` | ALB dedicado | Ingress `/mcp` |
| **PostgreSQL** | 5433–5435 | — | Por compose de cada API | AppHost (×3 DB) | Requiere PG local | `k8s/postgres/` | ACI / sidecar | StatefulSet | ECS + EFS | StatefulSet |
| **Azurite** | 10000 | — | En compose Source/Inventory/Analytics | AppHost | — | `k8s/azurite/` | Blob Azure | Blob Azure | S3/Blob | Blob Azure |

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
dotnet build Source/ShopDemo.slnx    # compila la solución
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

> **Postman:** importa [ShopDemo.postman_collection.json](Documentación_Del_Proyecto/ShopDemo.postman_collection.json) — las variables ya apuntan a `localhost`. Ver [Configurar Postman](#configurar-postman-según-entorno).

---

### Opción A — Docker Compose (recomendada para empezar)

**Cuándo usarla:** etapas 1–5; quieres levantar un servicio aislado con su PostgreSQL.

**Orden:** Catalog e Inventory primero; luego Orders (Orders llama a Inventory).

| Paso | Acción | Terminal |
|---|---|---|
| 1 | Catalog + PostgreSQL | `cd Source/Catalog/ShopDemo.Catalog.Api` → `copy .env.example .env` → `docker compose up --build` |
| 2 | Inventory + PostgreSQL + Azurite | `cd Source/Inventory/ShopDemo.Inventory.Api` → `docker compose up --build` |
| 3 | Orders + PostgreSQL | `cd Source/Orders/ShopDemo.Orders.Api` → `docker compose up --build` |
| 4 | Analytics (opcional, etapa 6+) | `cd Source/Aspire/ShopDemo.Analytics.Api` → `docker compose up --build` |
| 5 | MCP Gateway (opcional, etapa 14+) | `cd Source/AI/ShopDemo.Mcp.Api` → `copy .env.example .env` → `docker compose up --build` |

**Verificar:**

```bash
curl http://localhost:8001/health
curl http://localhost:8003/health
curl http://localhost:8002/health
curl http://localhost:8004/health   # si Analytics está activo
curl http://localhost:8005/health   # si MCP está activo
```

**Event Hubs (opcional):** edita `.env` en cada API con `EVENT_HUBS_ENABLED=true` y la connection string. Guía: [INTEGRACION-AZURE-EVENT-HUBS.md](Documentación_Del_Proyecto/INTEGRACION-AZURE-EVENT-HUBS.md).

**Detener:** `Ctrl+C` en cada terminal o `docker compose down`.

---

### Opción B — .NET Aspire (stack completo en un comando)

**Cuándo usarla:** etapa 6; quieres las 4 APIs + PostgreSQL + Azurite + dashboard sin varias terminales.

| Paso | Comando |
|---|---|
| 1 | Configurar Event Hubs (una vez): `dotnet user-secrets set "ShopDemo:EventHubs:ConnectionString" "<CONNECTION_STRING>" --project Source/Aspire/ShopDemo.AppHost` |
| 2 | Arrancar todo: `dotnet run --project Source/Aspire/ShopDemo.AppHost` |
| 3 | Abrir **Aspire Dashboard** (URL que muestra la consola) |

Los puertos siguen siendo **8001–8004**. El AppHost inyecta `EventHubs__*` y la URL de Inventory para Orders.

Guía: [IMPLEMENTACION-ANALYTICS-ASPIRE.md](Documentación_Del_Proyecto/analytics/IMPLEMENTACION-ANALYTICS-ASPIRE.md)

---

### Opción C — `dotnet run` (depuración en Visual Studio / Cursor)

**Cuándo usarla:** depurar un solo microservicio con breakpoints.

Requiere PostgreSQL accesible en `localhost:5433`–`5435` (vía Compose de cada BD o instancia local).

```bash
dotnet run --project Source/Catalog/ShopDemo.Catalog.Api
dotnet run --project Source/Orders/ShopDemo.Orders.Api
dotnet run --project Source/Inventory/ShopDemo.Inventory.Api
dotnet run --project Source/Aspire/ShopDemo.Analytics.Api
dotnet run --project Source/AI/ShopDemo.Mcp.Api    # etapa 14+; requiere 8001, 8003, 8004
```

---

### Opción E — MCP Gateway (integración IA)

**Cuándo usarla:** etapa 14–14b; conectar Cursor o Claude Code al servidor MCP.

| Paso | Comando |
|---|---|
| 1 | Asegurar Catalog (8001), Inventory (8003) y Analytics (8004) activos |
| 2 | `cd Source/AI/ShopDemo.Mcp.Api` → `copy .env.example .env` (URLs de APIs) |
| 3 | `dotnet run --project Source/AI/ShopDemo.Mcp.Api` o `docker compose up --build` |
| 4 | Probar: `curl http://localhost:8005/health` y endpoint MCP `http://localhost:8005/mcp` |

Guía: [Documentación_Del_Proyecto/integracion-ia/README.md](Documentación_Del_Proyecto/integracion-ia/README.md) · Despliegue nube: [Azure](Documentación_Del_Proyecto/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) · [AWS](Documentación_Del_Proyecto/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md)

---

### Opción D — Kubernetes local (Minikube)

**Cuándo usarla:** etapa 9; practicar manifiestos antes de AKS/EKS.

| Paso | Resumen |
|---|---|
| 1 | `minikube start` + `minikube addons enable ingress` |
| 2 | Build imágenes en daemon Minikube (`minikube docker-env`) |
| 3 | `apply-k8s-manifests.sh k8s local` o pasos en [k8s/README.md](k8s/README.md) |

Guía completa: [IMPLEMENTACION-KUBERNETES-LOCAL.md](Documentación_Del_Proyecto/despliegue/kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md)

**Postman con Ingress:** `catalogBaseUrl` = `http://shopdemo.local/catalog` (tras configurar hosts o `minikube tunnel`).

Incluye **5 APIs** (Catalog, Orders, Inventory, Analytics, MCP) + PostgreSQL + Azurite. Orden de apply: [k8s/README.md](k8s/README.md).

---

## Release Azure

Dos caminos de **release** en Azure. Ambos usan imágenes en **Azure Container Registry (ACR)** y despliegan **5 contenedores** (4 APIs de negocio + MCP Gateway).

| Camino | Servicio Azure | Ideal para | Guía |
|---|---|---|---|
| **ACA** | Container Apps | Release serverless, más simple | [GUIA-RELEASE-SCRIPT-AZURE](Documentación_Del_Proyecto/despliegue/azure/GUIA-RELEASE-SCRIPT-AZURE.md) |
| **AKS** | Kubernetes Service | Compartidos `k8s/` + deployments `k8s/azure/` | [GUIA-RELEASE-KUBERNETES](Documentación_Del_Proyecto/despliegue/kubernetes/GUIA-RELEASE-KUBERNETES.md) |

**Preparación previa:** [PREPARACION-AMBIENTE-AZURE](Documentación_Del_Proyecto/despliegue/azure/PREPARACION-AMBIENTE-AZURE.md) (suscripción, cuotas, permisos Contributor).

**Release AKS validado en lab:** cluster `aks-shopdemo`, 2 nodos `Standard_B2s`, 5 APIs + MCP + Ingress. Reporte con URLs: [Source/scripts/azure/deploy-aks-report.json](Source/scripts/azure/deploy-aks-report.json).

### Scripts PowerShell — configuración y ejecución (recomendado)

Automatizan la infraestructura Azure (Portal/CLI manual sigue disponible en las guías §0).

| Recurso | Ruta |
|---|---|
| Carpeta scripts | [Source/scripts/azure/](Source/scripts/azure/) |
| Guía del script | [Source/scripts/azure/README.md](Source/scripts/azure/README.md) |
| Plantilla variables | [Source/scripts/azure/.env.azure.example](Source/scripts/azure/.env.azure.example) |

**Flujo en 5 pasos:**

```powershell
# 1. Variables (Subscription ID, nombres únicos ACR/Event Hubs/Storage)
cd I:\Curso\ShopDemo\Source\scripts\azure
copy .env.azure.example .env.azure
notepad .env.azure

# 2. Login Azure
az login
az account set --subscription "<TU-SUBSCRIPTION-ID>"

# 3. Provisionar (elegir modo)
.\Deploy-AzureShopDemo.ps1 -Mode ACA    # Container Apps + MCP
.\Deploy-AzureShopDemo.ps1 -Mode AKS  # Cluster + k8s/secrets.yaml
.\Deploy-AzureShopDemo.ps1 -Mode All  # ACA + AKS

# 4. Publicar imágenes en ACR (obligatorio — el script no hace build)
#    GitHub Actions: .github/workflows/ (ver .github/SECRETS-CHECKLIST.md)
#    O build manual: ver GUIA-RELEASE-SCRIPT-AZURE

# 5. Validar y limpiar
#    ACA: curl https://<fqdn-catalog>/health
#    AKS: apply-k8s-manifests.sh k8s azure (ver k8s/README.md)
.\Remove-AzureShopDemo.ps1
```

| Modo script | Imágenes requeridas en ACR | Validación |
|---|---|---|
| `ACA` | 5 × `latest` (o `IMAGE_TAG` en `.env.azure`) | FQDN Container Apps en salida del script |
| `AKS` | Igual + `kubectl apply` | `kubectl get pods -n shopdemo` |
| `All` | Igual para ambos entornos | Postman con [GUIA-ENDPOINTS](Documentación_Del_Proyecto/GUIA-ENDPOINTS.md) |

Documentación: [ALCANCE-LAB-RELEASE](Documentación_Del_Proyecto/despliegue/ALCANCE-LAB-RELEASE.md) · [Script](Documentación_Del_Proyecto/despliegue/azure/GUIA-RELEASE-SCRIPT-AZURE.md) · [CLI](Documentación_Del_Proyecto/despliegue/azure/GUIA-RELEASE-CLI-AZURE.md) · [Portal](Documentación_Del_Proyecto/despliegue/azure/GUIA-RELEASE-PORTAL-AZURE.md) · [AKS](Documentación_Del_Proyecto/despliegue/kubernetes/GUIA-RELEASE-KUBERNETES.md) · [Script PS](Source/scripts/azure/README.md)

> **Checkpoints Event Hubs:** en ACA usa **Azure Storage Account** (no Azurite). En AKS/Minikube usa Azurite in-cluster (`k8s/azurite/`).

### Post-script AKS (pasos manuales frecuentes)

El script crea RG, Event Hubs, ACR, cluster y `k8s/secrets.yaml`. Tras el script, completa:

| Paso | Acción |
|---|---|
| 1 | Push de 5 imágenes a ACR (las imágenes ACR ya están en `k8s/azure/*/deployment.yaml`; `kubectl set image` solo si cambias tag) |
| 2 | `kubectl apply` compartidos + **`k8s/azure/`** (ver [k8s/README.md](k8s/README.md)) |
| 3 | Helm Ingress NGINX si el script falla en este paso (ver [Script §5.2](Documentación_Del_Proyecto/despliegue/azure/GUIA-RELEASE-SCRIPT-AZURE.md)) |
| 4 | Anotación health probe Azure: `service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path=/healthz` |
| 5 | Consumer groups en Event Hubs: `analytics-service`, `inventory-service` |
| 6 | Entrada en archivo **hosts**: `<IP-ingress> shopdemo.local` |
| 7 | Swagger: `ASPNETCORE_ENVIRONMENT=Development` en deployments; alternativa LB directo **`:8080/swagger`** |

| Problema | Solución |
|---|---|
| Analytics CrashLoopBackOff | Crear consumer group `analytics-service` en Event Hubs |
| Ingress timeout externo | Health probe `/healthz` + `externalTrafficPolicy: Local` |
| Swagger 404 | Variable `ASPNETCORE_ENVIRONMENT=Development` |

### Arranque en Azure (resumen manual)

| # | Acción | ACA (Container Apps) | AKS |
|---|---|---|---|
| 1 | **Build y push** imágenes a ACR | `shopdemo-catalog`, `orders`, `inventory`, `analytics`, `mcp` | Igual |
| 2 | **Infraestructura** | RG + ACR + Environment ACA | RG + ACR + cluster AKS + Ingress NGINX |
| 3 | **Desplegar APIs** | Crear **5** Container Apps (incl. MCP) | Compartidos + **`k8s/azure/`** (ver [k8s/README.md](k8s/README.md)) |
| 4 | **Secretos** | `EventHubs__*`, PostgreSQL, **Storage Account** checkpoints | `k8s/secrets.yaml` + Azurite in-cluster |
| 5 | **Verificar** | `curl https://<fqdn>/health` por app | `kubectl get pods -n shopdemo` + Ingress |
| 6 | **Postman** | Actualizar variables con FQDN de cada ACA | URLs con prefijo Ingress (`/catalog`, …, `/mcp`) |

### Flujo común release Azure

```mermaid
flowchart LR
    A[docker build] --> B[docker push ACR]
    B --> C{Destino}
    C -->|ACA| D[Container Apps]
    C -->|AKS| E[apply-k8s-manifests.sh k8s azure]
    D & E --> F[Probar con Postman]
```

| Paso | ACA (Container Apps) | AKS |
|---|---|---|
| 1 | Crear RG + ACR | Crear RG + ACR + cluster AKS |
| 2 | `docker push` 5 imágenes a ACR | `az aks get-credentials` + push ACR |
| 3 | Crear 5 Container Apps | Instalar Ingress NGINX |
| 4 | Secrets `EventHubs__*` en cada app | Compartidos + `k8s/azure/` + ingress (orden en [k8s/README.md](k8s/README.md)) |
| 5 | Copiar FQDN de cada app | Copiar IP/DNS del Ingress (`shopdemo.local` o IP pública) |
| 6 | MCP: [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE](Documentación_Del_Proyecto/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) | Ruta Ingress `/mcp` en `k8s/ingress/` |

### URLs release Azure (Postman)

Tras desplegar, actualiza las variables de colección:

| Variable Postman | Origen (ACA) | Origen (AKS Ingress) |
|---|---|---|
| `catalogBaseUrl` | `https://ca-shopdemo-catalog.<fqdn>` | `http://<ingress-ip>/catalog` |
| `ordersBaseUrl` | `https://ca-shopdemo-orders.<fqdn>` | `http://<ingress-ip>/orders` |
| `inventoryBaseUrl` | URL **interna** o pública si expusiste | `http://<ingress-ip>/inventory` |
| `analyticsBaseUrl` | `https://ca-shopdemo-analytics.<fqdn>` | `http://<ingress-ip>/analytics` |
| MCP (agente) | `https://ca-shopdemo-mcp.<fqdn>/mcp` | `http://<ingress-ip>/mcp` |

**Secrets obligatorios en nube:** `EventHubs__ConnectionString`, connection strings PostgreSQL, **Storage Account** (`storage-checkpoint`) para Source/Inventory/Analytics en ACA, URLs internas para Orders y MCP.

**Observabilidad y resiliencia:** [Documentación_Del_Proyecto/observabilidad/azure/](Documentación_Del_Proyecto/observabilidad/azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md) · [Documentación_Del_Proyecto/resiliencia/azure/](Documentación_Del_Proyecto/resiliencia/azure/IMPLEMENTACION-RESILIENCIA-AZURE.md)

CI/CD: [.github/workflows/](.github/workflows/) — **4 workflows** (ACA, ECS, AKS, EKS) · Checklist secrets: [.github/SECRETS-CHECKLIST.md](.github/SECRETS-CHECKLIST.md)

---

## Release AWS

Dos caminos de **release** en AWS. Ambos usan **Amazon ECR** y despliegan **5 contenedores** (4 APIs + MCP).

| Camino | Servicio AWS | Ideal para | Guía |
|---|---|---|---|
| **ECS** | Fargate | Release sin Kubernetes | [GUIA-RELEASE-SCRIPT-AWS](Documentación_Del_Proyecto/despliegue/aws/GUIA-RELEASE-SCRIPT-AWS.md) |
| **EKS** | Elastic Kubernetes Service | Compartidos `k8s/` + deployments `k8s/aws/` | [GUIA-RELEASE-KUBERNETES](Documentación_Del_Proyecto/despliegue/kubernetes/GUIA-RELEASE-KUBERNETES.md) |

**Preparación previa:** [PREPARACION-AMBIENTE-AWS](Documentación_Del_Proyecto/despliegue/aws/PREPARACION-AMBIENTE-AWS.md) (IAM `ShopDemoLabECS` / `ShopDemoLabEKS`, región recomendada `us-east-2`).

**Release EKS validado en lab (free-tier):** 4 nodos `t3.micro`, Source/Catalog, Source/Orders, Source/Inventory con LoadBalancer, Swagger en **`:8080`**. Reporte: [Source/scripts/aws/deploy-eks-free-tier-report.json](Source/scripts/aws/deploy-eks-free-tier-report.json).

### Scripts PowerShell — configuración y ejecución (recomendado)

| Recurso | Ruta |
|---|---|
| Carpeta scripts | [Source/scripts/aws/](Source/scripts/aws/) |
| Guía del script | [Source/scripts/aws/README.md](Source/scripts/aws/README.md) |
| Plantilla variables | [Source/scripts/aws/.env.aws.example](Source/scripts/aws/.env.aws.example) |

**Flujo en 5 pasos:**

```powershell
# 1. Variables (región AWS + connection string Event Hubs desde Azure Portal)
cd I:\Curso\ShopDemo\Source\scripts\aws
copy .env.aws.example .env.aws
notepad .env.aws

# 2. Credenciales AWS
aws configure
aws sts get-caller-identity

# 3. Provisionar
.\Deploy-AwsShopDemo.ps1 -Mode ECS   # Fargate + ALB + Cloud Map + MCP
.\Deploy-AwsShopDemo.ps1 -Mode EKS   # eksctl + k8s/secrets.yaml
.\Deploy-AwsShopDemo.ps1 -Mode All

# 4. Publicar imágenes en ECR (obligatorio)
#    GitHub Actions: .github/workflows/ (ver .github/SECRETS-CHECKLIST.md)
#    O manual: GUIA-RELEASE-SCRIPT-AWS

# 5. Validar y limpiar
#    ECS: http://<alb-catalog-dns>/swagger
#    EKS: apply-k8s-manifests.sh k8s aws (ver k8s/README.md)
.\Remove-AwsShopDemo.ps1   # confirmar: delete-shopdemo
```

| Valor obligatorio en `.env.aws` | Origen |
|---|---|
| `EVENT_HUBS_CONNECTION_STRING` | **Azure Portal** (Event Hubs — mensajería cross-cloud) |
| `AWS_REGION` | Consola AWS / `aws configure` |

Documentación: [ALCANCE-LAB-RELEASE](Documentación_Del_Proyecto/despliegue/ALCANCE-LAB-RELEASE.md) · [Script](Documentación_Del_Proyecto/despliegue/aws/GUIA-RELEASE-SCRIPT-AWS.md) · [CLI](Documentación_Del_Proyecto/despliegue/aws/GUIA-RELEASE-CLI-AWS.md) · [Portal](Documentación_Del_Proyecto/despliegue/aws/GUIA-RELEASE-PORTAL-AWS.md) · [Task definitions ECS](Documentación_Del_Proyecto/despliegue/aws/ANEXO-TASK-DEFINITIONS-ECS.md) · [Script PS](Source/scripts/aws/README.md)

> **Checkpoints Event Hubs en ECS:** Azurite en Fargate. **Mensajería:** Azure Event Hubs (SSM). Task definitions: [ANEXO-TASK-DEFINITIONS-ECS](Documentación_Del_Proyecto/despliegue/aws/ANEXO-TASK-DEFINITIONS-ECS.md).

### Perfil EKS free-tier (ajustes post-script)

Con 4× `t3.micro` (máx. ~16 pods) el cluster no cabe con los 5 servicios + Ingress + Analytics. Perfil validado:

| Servicio | Estado en free-tier |
|---|---|
| Catalog, Orders, Inventory | LoadBalancer + Swagger `:8080` |
| MCP, Analytics, Ingress NGINX | Omitidos o 0 réplicas (ver [Script §6](Documentación_Del_Proyecto/despliegue/aws/GUIA-RELEASE-SCRIPT-AWS.md)) |
| CoreDNS | Reducir a 1 réplica si hay presión de pods |

| Problema | Solución |
|---|---|
| Swagger timeout en ELB | Usar puerto **`:8080`** (no `:80`) |
| Pods Pending | Quitar MCP/Ingress/Analytics o subir nodos |
| Sin eventos Analytics | Requiere conectividad HTTPS a Azure Event Hubs |

### Arranque en AWS (resumen manual)

| # | Acción | ECS Fargate | EKS |
|---|---|---|---|
| 1 | **Build y push** a ECR | 5 repos/imágenes | Igual |
| 2 | **Infraestructura** | Cluster ECS + ALB por API pública | Cluster EKS + Ingress NGINX + EBS CSI |
| 3 | **Desplegar** | Task definitions + services + Cloud Map | Compartidos + **`k8s/aws/`** (ver [k8s/README.md](k8s/README.md)) |
| 4 | **Secretos** | SSM Parameter Store / Secrets Manager | `k8s/secrets.yaml` |
| 5 | **Verificar** | `curl http://<alb-dns>/health` | `kubectl get pods -n shopdemo` |
| 6 | **MCP** | [IMPLEMENTACION-DESPLIEGUE-MCP-AWS](Documentación_Del_Proyecto/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md) | Ingress `/mcp` |

### Flujo común release AWS

| Paso | ECS Fargate | EKS |
|---|---|---|
| 1 | Crear repos ECR (5 imágenes) | `eksctl create cluster` o Consola EKS |
| 2 | `docker push` a ECR | `aws eks update-kubeconfig` |
| 3 | Task definitions + services (5) | EBS CSI + Ingress NGINX |
| 4 | ALB por API pública + Cloud Map Orders→Inventory | Compartidos + `k8s/aws/` + ingress |
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

**Observabilidad y resiliencia:** [Documentación_Del_Proyecto/observabilidad/aws/](Documentación_Del_Proyecto/observabilidad/aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md) · [Documentación_Del_Proyecto/resiliencia/aws/](Documentación_Del_Proyecto/resiliencia/aws/IMPLEMENTACION-RESILIENCIA-AWS.md)

CI/CD: [.github/workflows/](.github/workflows/) — **4 workflows** (ACA, ECS, AKS, EKS) · Checklist: [.github/SECRETS-CHECKLIST.md](.github/SECRETS-CHECKLIST.md)

---

## Configurar Postman según entorno

1. Importar [Documentación_Del_Proyecto/ShopDemo.postman_collection.json](Documentación_Del_Proyecto/ShopDemo.postman_collection.json)
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

### Catalog — `Source/Catalog/ShopDemo.Catalog.Api/`

| Variable | Dónde configurarla | Ejemplo / notas |
|---|---|---|
| `ConnectionStrings__DefaultConnection` | `appsettings.json`, `docker-compose.yml` | Host `catalog-db` en Docker; `localhost:5433` en dev |
| `EventHubs__Enabled` | `.env`, compose, ACA/ECS | `true` / `false` |
| `EventHubs__ConnectionString` | `.env` (no commitear) | Connection string del namespace Azure |
| `EventHubs__EventHubName` | `.env`, compose | `shopdemo-events` |

Archivo plantilla: `Source/Catalog/ShopDemo.Catalog.Api/.env.example`

### Orders — `Source/Orders/ShopDemo.Orders.Api/`

| Variable | Dónde configurarla | Ejemplo / notas |
|---|---|---|
| `ConnectionStrings__DefaultConnection` | `appsettings.json`, compose | Puerto host `5434` |
| `InventoryApi__BaseUrl` | `appsettings.json`, compose, ACA, ECS | `http://localhost:8003` · Docker: `http://host.docker.internal:8003` · Aspire: automático · Nube: URL interna Inventory |
| `EventHubs__Enabled` | `.env`, compose | Igual que Catalog |
| `EventHubs__ConnectionString` | `.env` | Igual que Catalog |
| `EventHubs__EventHubName` | `.env` | `shopdemo-events` |

Archivo plantilla: `Source/Orders/ShopDemo.Orders.Api/.env.example`

### Inventory — `Source/Inventory/ShopDemo.Inventory.Api/`

| Variable | Dónde configurarla | Ejemplo / notas |
|---|---|---|
| `ConnectionStrings__DefaultConnection` | `appsettings.json`, compose | Puerto host `5435` |
| `EventHubs__Enabled` | `.env`, compose | `true` activa publisher + `CatalogEventsProcessor` |
| `EventHubs__ConnectionString` | `.env` | Connection string Azure |
| `EventHubs__ConsumerGroup` | compose, ACA, ECS | `inventory-service` |
| `EventHubs__CheckpointStorageConnectionString` | `.env`, compose | Azurite local; Blob en nube |
| `EventHubs__CheckpointContainerName` | compose | `inventory-checkpoints` |

Archivo plantilla: `Source/Inventory/ShopDemo.Inventory.Api/.env.example`

### Analytics — `Source/Aspire/ShopDemo.Analytics.Api/`

| Variable | Dónde configurarla | Ejemplo / notas |
|---|---|---|
| `EventHubs__Enabled` | compose, ACA, ECS | `true` |
| `EventHubs__ConnectionString` | `.env`, AppHost | Desde AppHost en Aspire |
| `EventHubs__ConsumerGroup` | compose | `analytics-service` |
| `EventHubs__CheckpointStorageConnectionString` | compose | Azurite (`azurite:10000` en compose) |
| `EventHubs__CheckpointContainerName` | compose | `analytics-checkpoints` |

Archivo plantilla: `Source/Aspire/ShopDemo.Analytics.Api/.env.example`

### AppHost Aspire — `Source/Aspire/ShopDemo.AppHost/`

| Variable | Dónde configurarla | Ejemplo / notas |
|---|---|---|
| `ShopDemo:EventHubs:ConnectionString` | `appsettings.Development.json` o **user secrets** | Centraliza EH para los 4 APIs |
| `ShopDemo:EventHubs:EventHubName` | `appsettings.json` | `shopdemo-events` |
| `ShopDemo:EventHubs:Enabled` | `appsettings.json` | `true` |

El AppHost inyecta a cada API como `EventHubs__*` y configura `InventoryApi__BaseUrl` para Orders.

### MCP Gateway — `Source/AI/ShopDemo.Mcp.Api/`

| Variable | Dónde configurarla | Ejemplo / notas |
|---|---|---|
| `CatalogApi__BaseUrl` | `.env`, compose, ACA, ECS | `http://localhost:8001` · K8s: `http://shopdemo-catalog:8080` |
| `InventoryApi__BaseUrl` | `.env`, compose | `http://localhost:8003` |
| `AnalyticsApi__BaseUrl` | `.env`, compose | `http://localhost:8004` |

Archivo plantilla: `Source/AI/ShopDemo.Mcp.Api/.env.example`

### Plataformas en nube (release)

| Plataforma | Dónde poner secretos | Documentación |
|---|---|---|
| **Azure Container Apps** | Secrets de cada Container App | [despliegue/azure](Documentación_Del_Proyecto/despliegue/azure/) |
| **Azure AKS** | Secrets K8s / Key Vault | [despliegue/aks](Documentación_Del_Proyecto/despliegue/aks/) |
| **AWS ECS** | SSM Parameter Store / Secrets Manager | [despliegue/aws](Documentación_Del_Proyecto/despliegue/aws/) |
| **Amazon EKS** | Secrets K8s / Parameter Store | [despliegue/eks](Documentación_Del_Proyecto/despliegue/eks/) |
| **GitHub Actions** | Repository secrets | [.github/SECRETS-CHECKLIST.md](.github/SECRETS-CHECKLIST.md) |

> **Regla:** nunca commitear connection strings reales. Usa `.env` local (gitignored), user secrets o secretos de la plataforma.

---

## Prueba rápida del flujo integrado

1. Elige modo de ejecución: [Inicio local](#inicio-local-desarrollo-y-pruebas) o [Release](#release-azure).
2. Completa el [checklist E2E](#checklist-antes-del-flujo-e2e).
3. Importa y configura [Postman](#configurar-postman-según-entorno).
4. Ejecuta carpeta **Flujo integrado (E2E)** o sigue [GUIA-ENDPOINTS.md](Documentación_Del_Proyecto/GUIA-ENDPOINTS.md).

Con Event Hubs activo, el stock se auto-registra y Analytics lista eventos en `GET /api/analytics/events`.

---

## Estructura del repositorio

```
ShopDemo/
├── Source/             # Código .NET, Dockerfiles, scripts y ShopDemo.slnx
│   ├── ShopDemo.slnx     # Solución .NET
│   ├── Catalog/          # Clean Architecture — catálogo
│   ├── Orders/           # Clean Architecture — pedidos
│   ├── Inventory/        # Hexagonal — stock
│   ├── AI/               # MCP Gateway (ShopDemo.Mcp.Api :8005)
│   ├── Aspire/           # AppHost, ServiceDefaults, Analytics
│   ├── ShopDemo.Shared/  # Kernel DDD + mensajería
│   └── scripts/          # PowerShell Azure/AWS, tooling docs
├── k8s/              # Manifiestos K8s: compartidos + local/ azure/ aws/
├── spec-driven/      # Specs, plantillas Cursor y Claude Code
├── Documentación_Del_Proyecto/    # Documentación técnica del lab ShopDemo
├── Documentación_De_Estudio_Del_Curso/  # Tópicos de Estudio (teoría general, 13 capítulos)
└── .github/workflows/  # CI/CD: deploy-azure, deploy-aws, deploy-aks, deploy-eks
```

---

## Documentación índice

| Tema | Enlace |
|---|---|
| **Contexto global para agentes (Cursor)** | [AGENTS.md](AGENTS.md) · reglas en [.cursor/rules/](.cursor/rules/) |
| **Tópicos de Estudio** | [Documentación_De_Estudio_Del_Curso/README.md](Documentación_De_Estudio_Del_Curso/README.md) — [01](Documentación_De_Estudio_Del_Curso/01-patrones-diseno.md) … [13](Documentación_De_Estudio_Del_Curso/13-sintesis-integracion.md) |
| **Código y scripts** | [Source/README.md](Source/README.md) |
| **Guía de desarrollo (código paso a paso)** | [Documentación_Del_Proyecto/GUIA-DESARROLLO-INTEGRACIONES.md](Documentación_Del_Proyecto/GUIA-DESARROLLO-INTEGRACIONES.md) |
| Anexos de código | [Shared](Documentación_Del_Proyecto/ANEXO-CODIGO-SHARED.md) · [Catalog](Documentación_Del_Proyecto/catalog/ANEXO-CODIGO-CATALOG.md) · [Orders](Documentación_Del_Proyecto/orders/ANEXO-CODIGO-ORDERS.md) · [Inventory](Documentación_Del_Proyecto/inventory/ANEXO-CODIGO-INVENTORY.md) · [Event Hubs](Documentación_Del_Proyecto/ANEXO-CODIGO-EVENT-HUBS.md) · [Analytics/Aspire](Documentación_Del_Proyecto/analytics/ANEXO-CODIGO-ANALYTICS-ASPIRE.md) · [MCP](Documentación_Del_Proyecto/integracion-ia/ANEXO-CODIGO-MCP.md) |
| Scripts Azure (PowerShell) | [Source/scripts/azure/README.md](Source/scripts/azure/README.md) |
| Scripts AWS (PowerShell) | [Source/scripts/aws/README.md](Source/scripts/aws/README.md) |
| **CI/CD GitHub Actions** | [.github/README.md](.github/README.md) · [Portal web](.github/SETUP-GITHUB-PORTAL.md) · [SETUP-GITHUB](.github/SETUP-GITHUB.md) · [GH-CLI](.github/GH-CLI-COMMANDS.md) · [SECRETS-CHECKLIST](.github/SECRETS-CHECKLIST.md) |
| Preparación Azure / AWS | [PREPARACION-AZURE](Documentación_Del_Proyecto/despliegue/azure/PREPARACION-AMBIENTE-AZURE.md) · [PREPARACION-AWS](Documentación_Del_Proyecto/despliegue/aws/PREPARACION-AMBIENTE-AWS.md) |
| Reportes release lab | [AKS](Source/scripts/azure/deploy-aks-report.json) · [EKS free-tier](Source/scripts/aws/deploy-eks-free-tier-report.json) |
| Arquitectura | [Documentación_Del_Proyecto/ARQUITECTURA.md](Documentación_Del_Proyecto/ARQUITECTURA.md) |
| Endpoints y Postman | [Documentación_Del_Proyecto/GUIA-ENDPOINTS.md](Documentación_Del_Proyecto/GUIA-ENDPOINTS.md) |
| Event Hubs | [Documentación_Del_Proyecto/INTEGRACION-AZURE-EVENT-HUBS.md](Documentación_Del_Proyecto/INTEGRACION-AZURE-EVENT-HUBS.md) |
| Aspire | [Documentación_Del_Proyecto/INTEGRACION-ASPIRE.md](Documentación_Del_Proyecto/INTEGRACION-ASPIRE.md) |
| Despliegue | [Documentación_Del_Proyecto/despliegue/README.md](Documentación_Del_Proyecto/despliegue/README.md) |
| Observabilidad | [Documentación_Del_Proyecto/observabilidad/README.md](Documentación_Del_Proyecto/observabilidad/README.md) |
| Resiliencia | [Documentación_Del_Proyecto/resiliencia/README.md](Documentación_Del_Proyecto/resiliencia/README.md) |
| Integración IA | [Documentación_Del_Proyecto/integracion-ia/README.md](Documentación_Del_Proyecto/integracion-ia/README.md) |
| Spec-driven (Cursor + Claude) | [spec-driven/README.md](spec-driven/README.md) |
| Cheat sheets CLI | [Documentación_Del_Proyecto/cheat-sheets/](Documentación_Del_Proyecto/cheat-sheets/) |
| Teoría lab (ShopDemo) | [TEORIA-DOCKER-KUBERNETES-AOT](Documentación_Del_Proyecto/TEORIA-DOCKER-KUBERNETES-AOT.md) — complementa tópicos [07](Documentación_De_Estudio_Del_Curso/07-contenedores-docker.md) y [08](Documentación_De_Estudio_Del_Curso/08-kubernetes-orquestacion.md) |
| Manifiestos Kubernetes | [k8s/](k8s/) |

---

## Requisitos técnicos

- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Opcional: [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), [AWS CLI](https://aws.amazon.com/cli/)
- Opcional: cuenta Azure con Event Hubs para etapas 5–8

```bash
dotnet build Source/ShopDemo.slnx
```
