# Historias de Usuario — Catálogo de productos (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente de negocio** | [REQUERIMIENTOS-CATALOG.md](./REQUERIMIENTOS-CATALOG.md) |
| **Especificación técnica** | [ANEXO-ESPECIFICACION-TECNICA-CATALOG.md](./ANEXO-ESPECIFICACION-TECNICA-CATALOG.md) |
| **Historias técnicas** | [ANEXO-HISTORIAS-TECNICAS-CATALOG.md](./ANEXO-HISTORIAS-TECNICAS-CATALOG.md) |

> Este documento contiene **solo historias de negocio**. Las tareas de implementación están en el anexo técnico.

---

## HU-CAT-01 — Registrar producto en catálogo

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-01 |

**Como** administrador de catálogo, **quiero** registrar un nuevo producto con nombre, precio, stock y categoría, **para** que esté disponible en la tienda y otros procesos puedan referenciarlo por su identificador único.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-CAT-01 | Nombre entre 3 y 200 caracteres |
| RN-CAT-02 | Precio ≥ 0 con moneda válida |
| RN-CAT-03 | Stock inicial ≥ 0 |
| RN-CAT-04 | Categoría de la lista permitida |
| RN-CAT-05 | No duplicar nombre entre productos activos |
| RN-CAT-06 | Producto activo por defecto al crear |

### Criterios de aceptación (CA-N)

- [ ] **CA-N01:** Con datos válidos, el sistema confirma el alta y devuelve el identificador del producto.
- [ ] **CA-N02:** Con nombre duplicado, el sistema rechaza e informa que ya existe.
- [ ] **CA-N03:** Con datos inválidos, el sistema indica qué campos corregir.
- [ ] **CA-N04:** El producto queda guardado y consultable después del registro.

---

## HU-CAT-02 — Notificar cambios del catálogo

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-04 |

**Como** responsable de integración, **quiero** que el catálogo avise cuando se crea o modifica un producto, **para** que inventario, pedidos u otros sistemas reaccionen sin depender de consultas manuales.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-CAT-13 | El aviso se envía solo después de guardar el producto correctamente |
| RN-CAT-14 | En desarrollo puede bastar con registro en bitácora |

### Criterios de aceptación (CA-N)

- [ ] **CA-N05:** Tras registrar un producto, queda constancia de la notificación de creación.
- [ ] **CA-N08:** Si el guardado falla, no se envía notificación.

---

## HU-CAT-03 — Recibir mensajes claros de error

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-05, RF-09 |

**Como** consumidor del catálogo (persona o sistema integrado), **quiero** mensajes de error comprensibles cuando envío datos incorrectos, **para** corregir la información sin soporte técnico.

### Criterios de aceptación (CA-N)

- [ ] **CA-N03:** Errores de validación indican el campo y el motivo.
- [ ] **CA-N07:** Errores de reglas de negocio se explican en lenguaje de negocio, no solo código técnico.

---

## Historias preparadas (próximas funcionalidades)

| HU | Requerimiento | Historia resumida |
|---|---|---|
| HU-CAT-04 | RF-10 | **Como** administrador, **quiero** actualizar nombre y descripción de un producto activo |
| HU-CAT-05 | RF-11 | **Como** administrador, **quiero** cambiar el precio y que quede registro del cambio |
| HU-CAT-06 | RF-12 | **Como** administrador, **quiero** aumentar unidades disponibles (reabastecimiento) |
| HU-CAT-07 | RF-13 | **Como** administrador, **quiero** reducir stock cuando corresponda |
| HU-CAT-08 | RF-14 | **Como** administrador, **quiero** desactivar un producto sin borrarlo del historial |
| HU-CAT-09 | RF-15 | **Como** operador, **quiero** consultar y listar productos del catálogo |

### Reglas comunes (RN-CAT-07 a RN-CAT-10)

- Solo productos **activos** admiten cambios de detalle, precio o stock.
- No se puede descontar más stock del disponible.
- Desactivar un producto ya inactivo no genera error.

---

## Trazabilidad

| Requerimiento | Historia |
|---|---|
| RF-01 | HU-CAT-01 |
| RF-04 | HU-CAT-02 |
| RF-05, RF-09 | HU-CAT-03 |
| RF-10–RF-15 | HU-CAT-04–09 (preparadas) |

Implementación técnica: ver [ANEXO-HISTORIAS-TECNICAS-CATALOG.md](./ANEXO-HISTORIAS-TECNICAS-CATALOG.md).
