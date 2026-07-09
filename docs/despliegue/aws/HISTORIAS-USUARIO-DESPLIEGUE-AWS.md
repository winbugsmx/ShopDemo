# Historias de Usuario — Despliegue AWS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente de negocio** | [REQUERIMIENTOS-DESPLIEGUE-AWS.md](./REQUERIMIENTOS-DESPLIEGUE-AWS.md) |
| **Especificación técnica** | [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AWS.md](./ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AWS.md) |
| **Historias técnicas** | [ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AWS.md](./ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AWS.md) |

> Solo historias de **negocio/operación**. Tareas técnicas en el anexo.

---

## HU-AW-01 — Acceder a APIs en nube

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-AW-01, RF-AW-06 |

**Como** operador de la tienda, **quiero** acceder a catálogo, pedidos, analítica y MCP por URLs públicas en AWS, **para** operar la tienda sin entorno local.

### Criterios de aceptación (CA-N)

- [ ] **CA-N-AW-01:** Health/Swagger del catálogo responde vía DNS del balanceador.

---

## HU-AW-02 — Verificar eventos del negocio

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-AW-02 |

**Como** responsable de operaciones, **quiero** ver eventos tras crear un producto, **para** confirmar que la mensajería cross-cloud funciona.

### Criterios de aceptación (CA-N)

- [ ] **CA-N-AW-02:** Evento de producto creado visible en analítica.

---

## HU-AW-03 — Procesar pedidos con inventario

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-AW-03, RF-AW-04 |

**Como** operador de la tienda, **quiero** confirmar pedidos en AWS, **para** validar que pedidos encuentra inventario automáticamente.

### Reglas

| ID | Regla |
|---|---|
| RN-AW-01 | Inventario resuelto por descubrimiento de servicios interno |
| RN-AW-02 | Eventos propagados al bus |

### Criterios de aceptación (CA-N)

- [ ] **CA-N-AW-03:** Confirmación de pedido exitosa con reserva de stock.

---

## HU-AW-04 — Actualizar release

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-AW-05 |

**Como** responsable de TI, **quiero** publicar nuevas versiones de las aplicaciones, **para** mantener el entorno actualizado sin romper el flujo E2E.

### Criterios de aceptación (CA-N)

- [ ] **CA-N-AW-04:** Flujo E2E operativo tras actualización.
- [ ] **CA-N-AW-05:** Documentación Consola + CLI disponible.

---

## Trazabilidad

| Requerimiento | Historia |
|---|---|
| RF-AW-01, RF-AW-06 | HU-AW-01 |
| RF-AW-02 | HU-AW-02 |
| RF-AW-03, RF-AW-04 | HU-AW-03 |
| RF-AW-05 | HU-AW-04 |

Implementación: [ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AWS.md](./ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AWS.md).
