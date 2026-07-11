# Anexo — Especificación técnica: Observabilidad (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | B — Especificación técnica |

---

## 1. Pilares en ShopDemo

| Pilar | Implementación lab | Herramienta |
|---|---|---|
| **Logs** | `ILogger` → stdout → plataforma | Log Analytics / CloudWatch |
| **Métricas** | Infra + HTTP de plataforma | Azure Monitor / CloudWatch Metrics |
| **Trazas** | `traceId` en middleware; OTel solo Analytics | KQL / Logs Insights |
| **Local** | Aspire Dashboard | Solo desarrollo |

---

## 2. traceId en código

| Componente | Ubicación |
|---|---|
| `ExceptionHandlingMiddleware` | Catalog, Orders, Inventory, Analytics |
| Header / body error | Incluye `traceId` para correlación |

Consulta ejemplo KQL:

```kusto
ContainerAppConsoleLogs_CL
| where Log_s contains "<traceId>"
| order by TimeGenerated desc
```

---

## 3. Configuración por plataforma

| Plataforma | Logs | Métricas | Guía |
|---|---|---|---|
| ACA | Log Analytics Workspace | Container Apps metrics | [azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md](./azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md) |
| AKS | Container Insights / LA | Node/pod metrics | Idem |
| ECS | CloudWatch Log Groups | Container Insights | [aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md](./aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md) |
| EKS | CloudWatch | Container Insights | Idem |

---

## 4. Alertas (ejemplos)

| Cloud | Tipo | Umbral lab |
|---|---|---|
| Azure | Métrica HTTP 5xx | > 5 en 5 min |
| Azure | CPU Container App | > 80% |
| AWS | Logs Insights filter ERROR | > 10 en 5 min |
| AWS | ECS CPUUtilization | > 80% |

---

## 5. Estado en código

| Capacidad | Source/Catalog, Source/Orders, Source/Inventory | Analytics |
|---|---|---|
| Logs estructurados | Sí | Sí |
| traceId en errores | Sí | Sí |
| OpenTelemetry | No (fase actual) | Sí (ServiceDefaults) |
| Health `/health`, `/alive` | Sí | Sí |

---

## 6. RNF

| ID | Requerimiento |
|---|---|
| RNF-OBS-01 | Sin cambios obligatorios en Program.cs de APIs existentes |
| RNF-OBS-02 | Retención logs según tier lab (7–30 días) |
| RNF-OBS-03 | No loguear secretos |

---

## 7. CA-T

| ID | Criterio |
|---|---|
| CA-T-OBS-01 | Logs 4 APIs en Log Analytics o CloudWatch |
| CA-T-OBS-02 | Consulta KQL o Logs Insights ejecutada con resultado |
| CA-T-OBS-03 | Búsqueda por traceId exitosa |
| CA-T-OBS-04 | 1 alerta configurada en Azure y/o AWS |
| CA-T-OBS-05 | Guías ACA/AKS/ECS/EKS completas |

---

## 8. Referencias

- [TEORIA-OBSERVABILIDAD.md](./TEORIA-OBSERVABILIDAD.md)
