# Implementación — Observabilidad en Azure (ACA + AKS)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Prerequisitos:** ShopDemo desplegado en [ACA](../despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md) y/o [AKS](../despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md).  
**Teoría:** [TEORIA-OBSERVABILIDAD.md](../TEORIA-OBSERVABILIDAD.md)

---

## Índice

### Parte A — Container Apps (ACA)
1. [Paso A1 — Workspace Log Analytics](#parte-a--container-apps-aca)
2. [Paso A2 — Logs de Container Apps](#paso-a2--logs-de-container-apps)
3. [Paso A3 — Métricas ACA](#paso-a3--métricas-aca)
4. [Paso A4 — Correlación con traceId](#paso-a4--correlación-con-traceid)
5. [Paso A5 — Alertas básicas](#paso-a5--alertas-básicas)

### Parte B — AKS
6. [Paso B1 — Container Insights](#parte-b--aks)
7. [Paso B2 — Logs de pods ShopDemo](#paso-b2--logs-de-pods-shopdemo)
8. [Paso B3 — Métricas y dashboards](#paso-b3--métricas-y-dashboards)
9. [Paso B4 — Investigación E2E](#paso-b4--investigación-e2e)

---

## Parte A — Container Apps (ACA)

### Paso A1 — Workspace Log Analytics

**Objetivo:** Repositorio central para logs y métricas de ACA.

| # | Portal Azure | CLI |
|---|---|---|
| 1 | **Monitor** → **Log Analytics workspaces** → **Create** | `az monitor log-analytics workspace create -g $RG -n law-shopdemo` |
| 2 | Nombre: `law-shopdemo`, misma región que ACA | |
| 3 | Al crear el **Container Apps Environment**, vincular este workspace | `az containerapp env create ... --logs-workspace-id <ID>` |

**Explicación:** Sin workspace, los logs de `stdout` de cada Container App no son consultables de forma unificada.

---

### Paso A2 — Logs de Container Apps

**Objetivo:** Ver logs estructurados de Catalog, Orders, Inventory y Analytics.

#### Portal

1. **Container Apps** → seleccionar `ca-shopdemo-orders`
2. **Monitoring** → **Log stream** (tiempo real)
3. **Logs** → consultas KQL predefinidas

#### CLI — generar tráfico y ver logs

```bash
# Provocar log en Orders (confirmar pedido vía Postman)
az containerapp logs show \
  --name ca-shopdemo-orders \
  --resource-group $RG \
  --follow
```

#### KQL — buscar por OrderId

En Log Analytics → **Logs**:

```kql
ContainerAppConsoleLogs_CL
| where ContainerAppName_s == "ca-shopdemo-orders"
| where Log_s contains "Reserving stock"
| order by TimeGenerated desc
| take 50
```

**Explicación:** `InventoryHttpClient` escribe `Reserving stock in Inventory for order {OrderId}` — ideal para seguir el flujo síncrono.

---

### Paso A3 — Métricas ACA

**Objetivo:** Observar carga y salud sin entrar al contenedor.

| # | Acción |
|---|---|
| 1 | Container App → **Metrics** |
| 2 | Métricas útiles: **Requests**, **Replica Count**, **CPU Usage**, **Memory Working Set** |
| 3 | Repetir para las 4 APIs |

**Event Hubs (integración ShopDemo):**

1. Portal → Namespace Event Hubs → **Metrics**
2. Métrica **Incoming Messages** — debe subir al crear producto en Catalog

---

### Paso A4 — Correlación con traceId

**Objetivo:** Vincular error HTTP con logs usando el código actual (sin OTel en Catalog/Orders/Inventory).

| # | Paso |
|---|---|
| 1 | Provocar un error (ej. confirmar pedido sin stock) |
| 2 | Copiar `traceId` del JSON Problem Details de la respuesta |
| 3 | En Log Analytics: |

```kql
ContainerAppConsoleLogs_CL
| where Log_s contains "<PEGAR_TRACE_ID>"
| project TimeGenerated, ContainerAppName_s, Log_s
```

**Explicación:** `ExceptionHandlingMiddleware` incluye `traceId = context.TraceIdentifier` en respuestas de error. Es la correlación básica del curso.

**Analytics (OpenTelemetry):** si en local usas Aspire con `OTEL_EXPORTER_OTLP_ENDPOINT`, las trazas aparecen en Aspire Dashboard. En ACA, la exportación a Application Insights es **etapa futura** de código.

---

### Paso A5 — Alertas básicas

**Objetivo:** Capacidad de **reacción** ante fallos.

#### Portal — alerta HTTP 5xx en Orders

1. **Monitor** → **Alerts** → **Create** → **Alert rule**
2. Scope: Container App `ca-shopdemo-orders`
3. Condition: métrica **Requests** con filtro status code 5xx > 5 en 5 min
4. Action group: email al instructor/alumno

#### CLI (ejemplo métrica CPU)

```bash
az monitor metrics alert create \
  --name alert-catalog-cpu \
  --resource-group $RG \
  --scopes /subscriptions/<SUB>/resourceGroups/$RG/providers/Microsoft.App/containerApps/ca-shopdemo-catalog \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m
```

---

## Parte B — AKS

### Paso B1 — Container Insights

**Objetivo:** Métricas y logs de cluster para ShopDemo en `shopdemo` namespace.

| # | Portal | CLI |
|---|---|---|
| 1 | AKS cluster → **Monitoring** → **Insights** → Enable | `az aks enable-addons -a monitoring -g $RG -n $AKS_NAME` |
| 2 | Esperar 5–10 min | Verificar: **Monitor** → **Containers** |

**Explicación:** Container Insights envía telemetría de pods al mismo Log Analytics workspace del cluster.

---

### Paso B2 — Logs de pods ShopDemo

```bash
kubectl logs -n shopdemo -l app=shopdemo-catalog --tail=100
kubectl logs -n shopdemo -l app=shopdemo-orders -f
```

#### KQL — todos los pods del namespace

```kql
ContainerLogV2
| where PodNamespace == "shopdemo"
| where LogMessage contains "order" or LogMessage contains "stock"
| order by TimeGenerated desc
| take 100
```

---

### Paso B3 — Métricas y dashboards

| # | Acción |
|---|---|
| 1 | **Monitor** → **Containers** → namespace `shopdemo` |
| 2 | Revisar CPU/memoria por pod |
| 3 | **Workbooks** → template **Container Insights** → filtrar ShopDemo |

**Métricas útiles con HPA:**

```bash
kubectl get hpa -n shopdemo
kubectl top pods -n shopdemo
```

---

### Paso B4 — Investigación E2E

**Escenario:** Confirmar pedido falla con 500.

| # | Paso | Herramienta |
|---|---|---|
| 1 | Reproducir con Postman | `POST .../orders/{id}/confirm` |
| 2 | Guardar `traceId` de la respuesta | Body JSON |
| 3 | Logs Orders | `kubectl logs -n shopdemo -l app=shopdemo-orders --since=5m` |
| 4 | Logs Inventory | `kubectl logs -n shopdemo -l app=shopdemo-inventory --since=5m` |
| 5 | Estado pods | `kubectl get pods -n shopdemo` |
| 6 | Health | `curl http://<ingress>/inventory/health` |

**Causalidad típica:** Inventory no disponible → `EnsureSuccessStatusCode()` en `InventoryHttpClient` → 500 en Orders con `traceId` correlacionable.

---

## Checklist de validación

| # | Criterio | ACA | AKS |
|---|---|---|---|
| 1 | Logs centralizados visibles | Log Analytics | Container Insights |
| 2 | Métricas CPU/requests consultadas | ✓ | ✓ |
| 3 | Alerta configurada | ✓ | ✓ |
| 4 | traceId usado en búsqueda | ✓ | ✓ |
| 5 | Event Hubs metrics revisadas | ✓ | ✓ |

---

## Referencias

- [IMPLEMENTACION-DESPLIEGUE-AZURE.md](../../despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md)
- [IMPLEMENTACION-DESPLIEGUE-AKS.md](../../despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md)
- [GUIA-ENDPOINTS.md](../../GUIA-ENDPOINTS.md)
