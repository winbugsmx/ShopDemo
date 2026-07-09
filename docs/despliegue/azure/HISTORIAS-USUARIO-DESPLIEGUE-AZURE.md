# Historias de Usuario — Despliegue Azure (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente de negocio** | [REQUERIMIENTOS-DESPLIEGUE-AZURE.md](./REQUERIMIENTOS-DESPLIEGUE-AZURE.md) |
| **Especificación técnica** | [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AZURE.md](./ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AZURE.md) |
| **Historias técnicas** | [ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AZURE.md](./ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AZURE.md) |

> Este documento contiene **solo historias de negocio/operación**. Las tareas de implementación están en el anexo técnico.

---

## HU-AZ-01 — Operar catálogo en nube

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-AZ-01, RF-AZ-06 |

**Como** operador de la tienda, **quiero** registrar y consultar productos usando el catálogo desplegado en Azure, **para** mantener el inventario de artículos sin depender del entorno local.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-AZ-01 | Catálogo accesible por URL pública del entorno |
| RN-AZ-05 | Credenciales gestionadas por el responsable de TI, no expuestas al operador |

### Criterios de aceptación (CA-N)

- [ ] **CA-N-AZ-01:** La consulta de salud del catálogo responde correctamente.
- [ ] **CA-N-AZ-02:** Un producto registrado en nube queda disponible para el resto del flujo.

---

## HU-AZ-02 — Completar flujo de pedido en nube

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-AZ-02, RF-AZ-03 |

**Como** operador de la tienda, **quiero** crear y confirmar un pedido en el entorno Azure, **para** validar que la venta y la reserva de stock funcionan igual que en local.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-AZ-02 | Los eventos de creación y confirmación deben propagarse al bus |
| RN-AZ-03 | La confirmación no falla por comunicación interna entre pedidos e inventario |

### Criterios de aceptación (CA-N)

- [ ] **CA-N-AZ-03:** La confirmación de pedido completa la reserva de stock sin error.
- [ ] Tras crear producto, el inventario refleja stock asignado automáticamente.

---

## HU-AZ-03 — Observar eventos de negocio

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-AZ-04 |

**Como** responsable de operaciones, **quiero** consultar los eventos recientes del flujo de la tienda, **para** verificar que las acciones de negocio se registran correctamente en analítica.

### Criterios de aceptación (CA-N)

- [ ] **CA-N-AZ-02:** Tras registrar un producto, el evento aparece en la consulta de analítica.
- [ ] Tras confirmar un pedido, los eventos relacionados son visibles.

---

## HU-AZ-04 — Consultar tienda vía agente

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-AZ-05 |

**Como** equipo de soporte, **quiero** que un agente de IA pueda consultar el estado de ShopDemo en Azure, **para** responder preguntas operativas sin acceder manualmente a cada API.

### Criterios de aceptación (CA-N)

- [ ] **CA-N-AZ-06:** El agente obtiene estado coherente de las APIs vía gateway MCP.

---

## HU-AZ-05 — Actualizar release sin interrumpir operación

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-AZ-07 |

**Como** responsable de TI, **quiero** publicar una nueva versión de las aplicaciones en Azure, **para** incorporar correcciones o mejoras manteniendo el flujo E2E operativo.

### Criterios de aceptación (CA-N)

- [ ] **CA-N-AZ-04:** Tras la actualización, el flujo producto → pedido → confirmación sigue funcionando.
- [ ] **CA-N-AZ-05:** La documentación cubre el procedimiento en Portal y CLI.

---

## Trazabilidad

| Requerimiento | Historia |
|---|---|
| RF-AZ-01, RF-AZ-06 | HU-AZ-01 |
| RF-AZ-02, RF-AZ-03 | HU-AZ-02 |
| RF-AZ-04 | HU-AZ-03 |
| RF-AZ-05 | HU-AZ-04 |
| RF-AZ-07 | HU-AZ-05 |

Implementación técnica: [ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AZURE.md](./ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AZURE.md).
