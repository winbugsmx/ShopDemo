# Implementación — Integración de IA en AWS (ECS + EKS)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Prerequisitos:** APIs en ECS/EKS · CloudWatch Logs · [observabilidad](../../observabilidad/aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md)  
**Teoría:** [TEORIA-INTEGRACION-IA.md](../TEORIA-INTEGRACION-IA.md)

---

## Índice

1. [Módulo 1 — Anomalías en métricas y logs](#módulo-1--anomalías-en-métricas-y-logs)
2. [Módulo 2 — MCP Server](#módulo-2--mcp-server)
3. [Módulo 3 — Semantic Kernel + Event Hubs (+ Kafka/MSK)](#módulo-3--semantic-kernel--event-hubs--kafkamsk)
4. [Parte A — MCP en ECS Fargate](#parte-a--mcp-en-ecs-fargate)
5. [Parte B — MCP en EKS](#parte-b--mcp-en-eks)

---

## Módulo 1 — Anomalías en métricas y logs

**Objetivo:** Alertas y consultas con **CloudWatch Logs Insights** y umbrales de métrica.

### Paso 1.1 — Consulta de errores en Orders

**CloudWatch** → **Logs Insights** → log group `/ecs/shopdemo-orders`:

```sql
fields @timestamp, @message
| filter @message like /(?i)(error|exception|failed)/
| stats count() as errors by bin(5m)
| sort errors desc
```

**Explicación:** Identifica ventanas con picos de errores (ej. fallos Inventory).

### Paso 1.2 — Alarma por errores en logs (métrica filtro)

| # | Consola |
|---|---|
| 1 | **CloudWatch** → **Log groups** → `/ecs/shopdemo-orders` |
| 2 | **Create metric filter** — patrón `[timestamp, request_id, level=ERROR, ...]` o texto `Exception` |
| 3 | **Create alarm** sobre esa métrica: sum > 5 en 5 min |

### Paso 1.3 — Alarma CPU ECS

| # | Acción |
|---|---|
| 1 | Métrica `AWS/ECS` → `CPUUtilization` → service `shopdemo-catalog` |
| 2 | Threshold > 80 %, 2 períodos de 5 min |

### Paso 1.4 — Correlación

Buscar `traceId` del JSON Problem Details:

```sql
fields @timestamp, @message
| filter @message like /PEGAR_TRACE_ID/
| sort @timestamp desc
```

---

## Módulo 2 — MCP Server

### Paso 2.1 — Local

```bash
dotnet run --project Source/AI/ShopDemo.Mcp.Api
curl http://localhost:8005/health
```

Configurar agente: `http://localhost:8005/mcp`

### Paso 2.2 — Push ECR

```bash
aws ecr create-repository --repository-name shopdemo-mcp --region $AWS_REGION
docker build -f Source/AI/ShopDemo.Mcp.Api/Dockerfile -t $ECR/shopdemo-mcp:v1 .
docker push $ECR/shopdemo-mcp:v1
```

### Paso 2.3 — Variables de entorno

| Variable | ECS (Cloud Map / ALB DNS) |
|---|---|
| `ShopDemo__CatalogApiBaseUrl` | `http://shopdemo-catalog.shopdemo.local:8080` o ALB |
| `ShopDemo__InventoryApiBaseUrl` | DNS interno Inventory |
| `ShopDemo__AnalyticsApiBaseUrl` | DNS Analytics |

**Nota:** MCP debe alcanzar las APIs por red del cluster/VPC.

---

## Módulo 3 — Semantic Kernel + Event Hubs (+ Kafka/MSK)

### Paso 3.1 — Event Hubs desde AWS (principal)

ShopDemo publica a **Azure Event Hubs** aunque el cómputo esté en AWS.

| # | Paso |
|---|---|
| 1 | Task ECS/EKS con salida HTTPS a Azure |
| 2 | Secret `EVENT_HUBS_CONNECTION_STRING` en SSM |
| 3 | Worker `BackgroundService` + `EventProcessorClient` |
| 4 | `Kernel` + `OPENAI_API_KEY` desde Secrets Manager |

**Prompt ejemplo (enriquecimiento):**

```
Resume en una línea el siguiente evento de integración ShopDemo para un dashboard de operaciones: {{event_json}}
```

### Paso 3.2 — Anexo Amazon MSK (Kafka)

| # | Paso |
|---|---|
| 1 | Crear cluster **MSK** desarrollo (1 broker lab) |
| 2 | Topics `shopdemo.raw` / `shopdemo.enriched` |
| 3 | Consumer `Confluent.Kafka` + Semantic Kernel (mismo worker, otro transporte) |
| 4 | Comparar con Event Hubs en tabla de arquitectura |

**Cuándo usar MSK:** entornos 100 % AWS sin dependencia Azure; el curso mantiene Event Hubs como bus de negocio acordado.

---

## Parte A — MCP en ECS Fargate

Guía detallada (Consola + CLI): [IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md](../IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md) — Parte A.

---

## Parte B — MCP en EKS

Guía detallada: [IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md](../IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md) — Parte B.

Manifiestos: `k8s/aws/mcp/deployment.yaml` + `k8s/mcp/service.yaml` (ver [k8s/README.md](../../../k8s/README.md)).

---

## Checklist AWS

| # | Módulo | ECS | EKS |
|---|---|---|---|
| 1 | Logs Insights + alarma | ✓ | ✓ |
| 2 | MCP desplegado | ✓ | ✓ |
| 3 | Tool invocado desde agente | ✓ | ✓ |
| 4 | SK + Event Hubs documentado | ✓ | ✓ |
| 5 | Anexo MSK leído | opcional | opcional |

---

## Referencias

- [Source/AI/ShopDemo.Mcp.Api](../../../Source/AI/ShopDemo.Mcp.Api/)
- [IMPLEMENTACION-OBSERVABILIDAD-AWS.md](../../observabilidad/aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md)
- [IMPLEMENTACION-DESPLIEGUE-AWS.md](../../despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md)
