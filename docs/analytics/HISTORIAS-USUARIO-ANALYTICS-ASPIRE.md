# Historias de Usuario — Analytics (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-ANALYTICS-ASPIRE.md](./REQUERIMIENTOS-ANALYTICS-ASPIRE.md) |

> Historias de **negocio/operación**. Tareas técnicas en anexo.

---

## HU-AH-01 — Arrancar entorno integrado

| **RF** | RF-AN-05, RF-AN-06 · **OBJ** | OBJ-AN-04 |

**Como** responsable de TI, **quiero** levantar catálogo, pedidos, inventario y analítica con un solo arranque local, **para** probar el flujo E2E sin configurar cada servicio por separado.

### Criterios (CA-N)

- [ ] **CA-N-AN-04:** Las 4 APIs operativas tras arranque integrado.
- [ ] **CA-N-AN-05:** Confirmación de pedido exitosa en entorno integrado.

---

## HU-AN-01 — Observar eventos del negocio

| **RF** | RF-AN-01, RF-AN-03, RF-AN-04 · **OBJ** | OBJ-AN-01, OBJ-AN-02, OBJ-AN-03 |

**Como** responsable de operaciones, **quiero** que analítica muestre eventos cuando se crea un producto, **para** verificar integración y fan-out sin afectar inventario.

### Reglas

| ID | Regla |
|---|---|
| RN-AN-01 | Grupo de consumo distinto de inventario |
| RN-AN-03 | Solo observación; sin efectos de negocio |

### Criterios (CA-N)

- [ ] **CA-N-AN-01:** Evento visible tras crear producto.
- [ ] **CA-N-AN-03:** Inventario asigna stock sin regresión.

---

## HU-AN-02 — Consultar historial reciente

| **RF** | RF-AN-02 |

**Como** equipo de soporte, **quiero** listar los últimos eventos observados, **para** auditar acciones recientes de la tienda.

### Reglas

| ID | Regla |
|---|---|
| RN-AN-02 | Ventana limitada en memoria (últimos N eventos) |

### Criterios (CA-N)

- [ ] **CA-N-AN-02:** Eventos de pedidos visibles tras confirmación.

---

## Trazabilidad

| RF | HU |
|---|---|
| RF-AN-01–04 | HU-AN-01, HU-AN-02 |
| RF-AN-05–06 | HU-AH-01 |

Implementación: [ANEXO-HISTORIAS-TECNICAS-ANALYTICS-ASPIRE.md](./ANEXO-HISTORIAS-TECNICAS-ANALYTICS-ASPIRE.md).
