# SPEC — Integración IA (anomalías, Semantic Kernel)

## Objetivo

Documentar y configurar detección de anomalías en logs, Semantic Kernel y alertas cloud.

## Documentación (3 capas)

| Capa | Documento |
|---|---|
| **A — Negocio** | [REQUERIMIENTOS-INTEGRACION-IA.md](../../../Documentación del Proyecto/integracion-ia/REQUERIMIENTOS-INTEGRACION-IA.md) |
| **A — Negocio** | [HISTORIAS-USUARIO-INTEGRACION-IA.md](../../../Documentación del Proyecto/integracion-ia/HISTORIAS-USUARIO-INTEGRACION-IA.md) |
| **B — Técnica** | [ANEXO-ESPECIFICACION-TECNICA-INTEGRACION-IA.md](../../../Documentación del Proyecto/integracion-ia/ANEXO-ESPECIFICACION-TECNICA-INTEGRACION-IA.md) |
| **B — Técnica** | [ANEXO-HISTORIAS-TECNICAS-INTEGRACION-IA.md](../../../Documentación del Proyecto/integracion-ia/ANEXO-HISTORIAS-TECNICAS-INTEGRACION-IA.md) |
| **C — Pedagogía** | [ANEXO-PEDAGOGIA-INTEGRACION-IA.md](../../../Documentación del Proyecto/integracion-ia/ANEXO-PEDAGOGIA-INTEGRACION-IA.md) |
| Teoría | [TEORIA-INTEGRACION-IA.md](../../../Documentación del Proyecto/integracion-ia/TEORIA-INTEGRACION-IA.md) |
| Impl. Azure | [azure/IMPLEMENTACION-INTEGRACION-IA-AZURE.md](../../../Documentación del Proyecto/integracion-ia/azure/IMPLEMENTACION-INTEGRACION-IA-AZURE.md) |
| Impl. AWS | [aws/IMPLEMENTACION-INTEGRACION-IA-AWS.md](../../../Documentación del Proyecto/integracion-ia/aws/IMPLEMENTACION-INTEGRACION-IA-AWS.md) |
| MCP Gateway | [IMPLEMENTACION-MCP-GATEWAY.md](../../../Documentación del Proyecto/integracion-ia/IMPLEMENTACION-MCP-GATEWAY.md) |

Guía: [GUIA-ESTRUCTURA-DOCUMENTACION.md](../../../Documentación del Proyecto/GUIA-ESTRUCTURA-DOCUMENTACION.md)

## Alcance (agente)

- Alertas KQL (Azure) / Logs Insights (AWS)
- Worker Semantic Kernel + Event Hubs
- Sin commitear `OPENAI_API_KEY`

## Criterios de aceptación

### Negocio (CA-N)

- [ ] Responsable TI recibe alerta ante patrón anómalo en logs
- [ ] Integración IA documentada para operación del lab

### Técnico (CA-T)

- [ ] KQL / Logs Insights configurados
- [ ] Worker SK documentado (Event Hubs principal)
- [ ] `OPENAI_API_KEY` solo en secretos locales o cloud

## Instrucciones para el agente

1. Leer **REQUERIMIENTOS-INTEGRACION-IA** (negocio).
2. Consultar **ANEXO-ESPECIFICACION-TECNICA-INTEGRACION-IA**.
3. Nunca commitear claves de OpenAI ni connection strings.
4. Validar CA-N y CA-T al finalizar.
