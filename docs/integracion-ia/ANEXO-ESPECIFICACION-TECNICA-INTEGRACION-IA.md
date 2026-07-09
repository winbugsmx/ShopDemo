# Anexo — Especificación técnica: Integración IA (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | B — Especificación técnica |

---

## 1. Componentes

| Componente | Ruta | Puerto |
|---|---|---|
| MCP Gateway | `AI/ShopDemo.Mcp.Api` | 8005 local / 8080 contenedor |
| Alertas | KQL (Azure) / Logs Insights (AWS) | Plataforma |
| Semantic Kernel | Documentación diseño | Worker opcional |

---

## 2. Herramientas MCP

| Tool | Delegación HTTP |
|---|---|
| `CreateProduct` | POST Catalog `/api/products` |
| `GetProductStock` | GET Inventory stock |
| `ListAnalyticsEvents` | GET Analytics `/api/analytics/events` |
| `GetShopDemoStatus` | Health de 4 APIs |

Endpoint MCP: `POST /mcp` · Health: `GET /health`

---

## 3. Alertas (técnico)

| Cloud | Motor | Ejemplo |
|---|---|---|
| Azure | Log Analytics + alert rules | KQL `Http5xx > 5` |
| AWS | CloudWatch Logs Insights | Filter `ERROR` count |

Dependencia: [observabilidad/](../observabilidad/) logs centralizados.

---

## 4. Semantic Kernel (diseño)

```
Event Hubs → SK Worker → OpenAI API → evento enriquecido → publicación
```

Paquetes: `Microsoft.SemanticKernel`, `Azure.Messaging.EventHubs`

Anexo Kafka: laboratorio opcional documentado en guías AWS/Azure.

---

## 5. Variables entorno MCP

| Variable | Descripción |
|---|---|
| `ShopDemo__CatalogApiBaseUrl` | URL Catalog |
| `ShopDemo__OrdersApiBaseUrl` | URL Orders |
| `ShopDemo__InventoryApiBaseUrl` | URL Inventory |
| `ShopDemo__AnalyticsApiBaseUrl` | URL Analytics |

---

## 6. RNF

| ID | Requerimiento |
|---|---|
| RNF-IA-01 | OpenAI API key en user secrets / Parameter Store |
| RNF-IA-02 | Sin OAuth MCP en lab básico |
| RNF-IA-03 | MCP incluido en CI/CD ACR/ECR |

---

## 7. CA-T

| ID | Criterio |
|---|---|
| CA-T-IA-01 | `dotnet run --project AI/ShopDemo.Mcp.Api` → `/health` 200 |
| CA-T-IA-02 | Agente Cursor lista 4 tools |
| CA-T-IA-03 | `GetShopDemoStatus` reporta APIs OK |
| CA-T-IA-04 | 1 alerta KQL o Logs Insights configurada |
| CA-T-IA-05 | Documento SK con pseudocódigo y paquetes NuGet |

---

## 8. Referencias

- [ANEXO-CODIGO-MCP.md](./ANEXO-CODIGO-MCP.md)
- [IMPLEMENTACION-MCP-GATEWAY.md](./IMPLEMENTACION-MCP-GATEWAY.md)
- [azure/IMPLEMENTACION-INTEGRACION-IA-AZURE.md](./azure/IMPLEMENTACION-INTEGRACION-IA-AZURE.md)
- [aws/IMPLEMENTACION-INTEGRACION-IA-AWS.md](./aws/IMPLEMENTACION-INTEGRACION-IA-AWS.md)
