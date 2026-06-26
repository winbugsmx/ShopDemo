# Requerimientos — Integración de IA (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Versión:** 1.0

**Historias de usuario:** [HISTORIAS-USUARIO-INTEGRACION-IA.md](./HISTORIAS-USUARIO-INTEGRACION-IA.md)

---

## 1. Propósito

Cerrar el ciclo **operar → observar → actuar con IA** en ShopDemo: detectar comportamientos anómalos, permitir que agentes consulten el sistema vía MCP y documentar enriquecimiento de eventos con Semantic Kernel.

---

## 2. Objetivos

| ID | Objetivo |
|---|---|
| OBJ-IA-01 | Configurar **consultas y alertas** de anomalías básicas en logs/métricas (KQL / Logs Insights) |
| OBJ-IA-02 | Desplegar **ShopDemo.Mcp.Api** como MCP Server HTTP consumible por agentes |
| OBJ-IA-02b | Manifiestos K8s, Ingress `/mcp` y CI/CD ACR/ECR — ver [REQUERIMIENTOS-DESPLIEGUE-MCP.md](./REQUERIMIENTOS-DESPLIEGUE-MCP.md) |
| OBJ-IA-03 | Documentar **Semantic Kernel** con **Event Hubs** (principal) |
| OBJ-IA-04 | Documentar anexo **Kafka + SK** para laboratorio opcional |
| OBJ-IA-05 | Guías separadas **Azure (ACA+AKS)** y **AWS (ECS+EKS)** |
| OBJ-IA-06 | Usar **OpenAI API** como LLM común en el lab multicloud |

---

## 3. Alcance incluido

- Microservicio `AI/ShopDemo.Mcp.Api` con 4 tools MCP
- Dockerfile y docker-compose del MCP Gateway
- Alertas por umbral (no ML custom)
- Pasos de despliegue MCP en 4 plataformas
- Diseño del worker SK (pseudocódigo + paquetes NuGet)

## 4. Fuera de alcance

| Tema | Motivo |
|---|---|
| Predicción de fallos con IA / ML custom | Etapa futura (omitida por decisión del curso) |
| Worker SK en producción en repo | Solo documentación en esta entrega |
| Fine-tuning de modelos | Complejidad enterprise |
| Azure OpenAI / Bedrock nativos | Lab unificado con OpenAI API |

---

## 5. Criterios de aceptación

| # | Criterio |
|---|---|
| CA-IA-01 | Al menos 1 alerta KQL o Logs Insights activa y probada |
| CA-IA-02 | `dotnet run --project AI/ShopDemo.Mcp.Api` expone `/mcp` y `/health` |
| CA-IA-03 | Agente (Cursor u otro) lista e invoca un tool MCP contra el gateway |
| CA-IA-04 | Documento SK describe flujo Event Hubs → LLM → publicación |
| CA-IA-05 | Guías Azure y AWS completas para MCP |

---

## 6. Dependencias

- [Observabilidad](../observabilidad/README.md) — logs centralizados
- [Despliegue](../despliegue/README.md) — APIs en nube
- API key OpenAI (secreto, no commitear)

---

## Referencias

- [TEORIA-INTEGRACION-IA.md](./TEORIA-INTEGRACION-IA.md)
- [azure/IMPLEMENTACION-INTEGRACION-IA-AZURE.md](./azure/IMPLEMENTACION-INTEGRACION-IA-AZURE.md)
- [aws/IMPLEMENTACION-INTEGRACION-IA-AWS.md](./aws/IMPLEMENTACION-INTEGRACION-IA-AWS.md)
