# SPEC — Observabilidad

## Objetivo

Configurar agregación de logs, consultas, métricas y alertas en Azure y AWS.

## Documentación (3 capas)

| Capa | Documento |
|---|---|
| **A — Negocio** | [REQUERIMIENTOS-OBSERVABILIDAD.md](../../../Documentación del Proyecto/observabilidad/REQUERIMIENTOS-OBSERVABILIDAD.md) |
| **A — Negocio** | [HISTORIAS-USUARIO-OBSERVABILIDAD.md](../../../Documentación del Proyecto/observabilidad/HISTORIAS-USUARIO-OBSERVABILIDAD.md) |
| **B — Técnica** | [ANEXO-ESPECIFICACION-TECNICA-OBSERVABILIDAD.md](../../../Documentación del Proyecto/observabilidad/ANEXO-ESPECIFICACION-TECNICA-OBSERVABILIDAD.md) |
| **B — Técnica** | [ANEXO-HISTORIAS-TECNICAS-OBSERVABILIDAD.md](../../../Documentación del Proyecto/observabilidad/ANEXO-HISTORIAS-TECNICAS-OBSERVABILIDAD.md) |
| **C — Pedagogía** | [ANEXO-PEDAGOGIA-OBSERVABILIDAD.md](../../../Documentación del Proyecto/observabilidad/ANEXO-PEDAGOGIA-OBSERVABILIDAD.md) |
| Impl. Azure | [azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md](../../../Documentación del Proyecto/observabilidad/azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md) |
| Impl. AWS | [aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md](../../../Documentación del Proyecto/observabilidad/aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md) |
| Teoría | [TEORIA-OBSERVABILIDAD.md](../../../Documentación del Proyecto/observabilidad/TEORIA-OBSERVABILIDAD.md) |

Guía: [GUIA-ESTRUCTURA-DOCUMENTACION.md](../../../Documentación del Proyecto/GUIA-ESTRUCTURA-DOCUMENTACION.md)

## Alcance (agente)

- Log Analytics (Azure) / CloudWatch (AWS)
- Consultas KQL / Logs Insights
- Alertas básicas (5xx, CPU, reinicios)
- Correlación con `traceId` existente en middleware

## Criterios de aceptación

### Negocio (CA-N)

- [ ] Operador diagnostica fallo del flujo Orders → Inventory sin entrar a cada contenedor (CA-OBS-01)
- [ ] Investigación E2E documentada con `traceId` (CA-OBS-03)

### Técnico (CA-T)

- [ ] Logs de las 4 APIs en Log Analytics o CloudWatch
- [ ] Al menos 1 alerta configurada y probada (CA-OBS-02)
- [ ] Guías ACA, AKS, ECS, EKS completadas (CA-OBS-04)

## Instrucciones para el agente

1. Leer **REQUERIMIENTOS-OBSERVABILIDAD** (negocio) para objetivos operativos.
2. Consultar **ANEXO-ESPECIFICACION-TECNICA-OBSERVABILIDAD** para herramientas cloud.
3. No modificar Program.cs de APIs salvo que el anexo técnico lo indique.
4. Validar CA-N y CA-T al finalizar.
