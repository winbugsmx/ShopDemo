# SPEC — Resiliencia

## Objetivo

Health checks, réplicas, HPA y pruebas de recuperación ante fallos.

## Documentación (3 capas)

| Capa | Documento |
|---|---|
| **A — Negocio** | [REQUERIMIENTOS-RESILIENCIA.md](../../../docs/resiliencia/REQUERIMIENTOS-RESILIENCIA.md) |
| **A — Negocio** | [HISTORIAS-USUARIO-RESILIENCIA.md](../../../docs/resiliencia/HISTORIAS-USUARIO-RESILIENCIA.md) |
| **B — Técnica** | [ANEXO-ESPECIFICACION-TECNICA-RESILIENCIA.md](../../../docs/resiliencia/ANEXO-ESPECIFICACION-TECNICA-RESILIENCIA.md) |
| **B — Técnica** | [ANEXO-HISTORIAS-TECNICAS-RESILIENCIA.md](../../../docs/resiliencia/ANEXO-HISTORIAS-TECNICAS-RESILIENCIA.md) |
| **C — Pedagogía** | [ANEXO-PEDAGOGIA-RESILIENCIA.md](../../../docs/resiliencia/ANEXO-PEDAGOGIA-RESILIENCIA.md) |
| Impl. Azure | [azure/IMPLEMENTACION-RESILIENCIA-AZURE.md](../../../docs/resiliencia/azure/IMPLEMENTACION-RESILIENCIA-AZURE.md) |
| Impl. AWS | [aws/IMPLEMENTACION-RESILIENCIA-AWS.md](../../../docs/resiliencia/aws/IMPLEMENTACION-RESILIENCIA-AWS.md) |
| Teoría | [TEORIA-RESILIENCIA.md](../../../docs/resiliencia/TEORIA-RESILIENCIA.md) |

Guía: [GUIA-ESTRUCTURA-DOCUMENTACION.md](../../../docs/GUIA-ESTRUCTURA-DOCUMENTACION.md)

## Alcance (agente)

- Health probes en ACA, ECS, K8s
- Recuperación tras delete pod / stop task
- HPA y redundancia básica documentada

## Criterios de aceptación

### Negocio (CA-N)

- [ ] El servicio se recupera tras fallo de una instancia sin intervención manual prolongada
- [ ] Operador verifica salud del sistema vía health checks

### Técnico (CA-T)

- [ ] Probes configurados en ACA/ECS/K8s
- [ ] Recuperación tras delete pod / stop task demostrada y documentada
- [ ] HPA o réplicas mínimas según anexo técnico

## Instrucciones para el agente

1. Leer **REQUERIMIENTOS-RESILIENCIA** (negocio).
2. Consultar **ANEXO-ESPECIFICACION-TECNICA-RESILIENCIA** para configuración por plataforma.
3. Validar recuperación con evidencia (captura o log), no solo configuración.
4. Validar CA-N y CA-T al finalizar.
