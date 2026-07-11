# Documento de Requerimientos — Catálogo de productos (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Módulo** | Catalog — gestión del catálogo de productos |
| **Versión** | 2.0 (enfoque negocio) |
| **Fecha** | Junio 2026 |

**Documentos relacionados:**

| Capa | Documento |
|---|---|
| Historias de usuario | [HISTORIAS-USUARIO-CATALOG.md](./HISTORIAS-USUARIO-CATALOG.md) |
| Especificación técnica | [ANEXO-ESPECIFICACION-TECNICA-CATALOG.md](./ANEXO-ESPECIFICACION-TECNICA-CATALOG.md) |
| Historias técnicas | [ANEXO-HISTORIAS-TECNICAS-CATALOG.md](./ANEXO-HISTORIAS-TECNICAS-CATALOG.md) |
| Pedagogía (curso) | [ANEXO-PEDAGOGIA-CATALOG.md](./ANEXO-PEDAGOGIA-CATALOG.md) |

---

## Resumen en lenguaje llano

El módulo **Catálogo** permite que un administrador de la tienda **registre y mantenga los productos** que se venden en ShopDemo. Cada producto tiene nombre, descripción, precio, categoría y cantidad disponible. Una vez registrado, el producto recibe un identificador único que otros procesos (inventario y pedidos) pueden usar.

Si alguien intenta registrar un producto con datos inválidos o con un nombre que ya existe, el sistema lo rechaza y explica el motivo.

---

## 1. Propósito

Definir **qué debe hacer** el catálogo de productos en ShopDemo desde la perspectiva del negocio: alta de productos, reglas de validación, disponibilidad para venta y notificación a otros procesos cuando un producto se crea o cambia.

---

## 2. Actores

| Actor | Rol |
|---|---|
| **Administrador de catálogo** | Registra y mantiene productos |
| **Sistema de inventario** | Consume el identificador del producto para asignar stock |
| **Sistema de pedidos** | Referencia productos al crear líneas de pedido |
| **Consumidor de la API** | Aplicación o integración que consulta o registra productos |

---

## 3. Contexto de negocio

Flujo integrado de la tienda (visión de negocio):

| Paso | Qué ocurre |
|---|---|
| 1 | Se **registra un producto** en el catálogo |
| 2 | Se **asigna stock** a ese producto en inventario |
| 3 | Un **cliente crea un pedido** que incluye ese producto |
| 4 | Al **confirmar el pedido**, se reserva stock |
| 5 | Se puede **consultar** cuántas unidades quedan disponibles |

---

## 4. Alcance

### 4.1 Incluido (MVP)

| ID | Requerimiento de negocio |
|---|---|
| RF-01 | Registrar un producto nuevo con nombre, precio, stock inicial y categoría |
| RF-02 | Aplicar reglas de negocio al crear y modificar productos (activo/inactivo, precios, stock) |
| RF-03 | Conservar el catálogo de forma permanente entre sesiones |
| RF-04 | Notificar a otros sistemas cuando un producto se crea o cambia |
| RF-05 | Rechazar datos inválidos con mensajes comprensibles |
| RF-06 | Permitir explorar las operaciones disponibles (documentación de la API) |
| RF-07 | Operar en un entorno de prueba reproducible para el equipo |
| RF-08 | Aplicar cambios de estructura de datos al iniciar en desarrollo |
| RF-09 | Responder de forma predecible ante errores de negocio |

### 4.2 Preparado en reglas, pendiente de exponer al usuario

| ID | Requerimiento |
|---|---|
| RF-10 | Actualizar nombre y descripción de un producto activo |
| RF-11 | Cambiar el precio de un producto |
| RF-12 | Aumentar unidades disponibles (reabastecimiento) |
| RF-13 | Reducir unidades disponibles |
| RF-14 | Desactivar un producto (sin eliminarlo del historial) |
| RF-15 | Consultar y listar productos |

### 4.3 Fuera de alcance

- Pagos, facturación y catálogo multi-tenant
- Garantías de entrega de mensajes exactly-once entre sistemas
- Catálogo con múltiples monedas por producto en la misma operación

---

## 5. Lenguaje ubicuo

| Término | Significado para el negocio | Evitar |
|---|---|---|
| **Producto** | Artículo que se vende en la tienda | “Item”, “SKU” |
| **Nombre del producto** | Texto identificativo (3 a 200 caracteres) | Nombre libre sin validar |
| **Precio** | Monto y moneda del producto | Solo un número sin moneda |
| **Stock** | Unidades disponibles para venta | “Cantidad” ambigua |
| **Categoría** | Clasificación del producto (Electrónica, Ropa, etc.) | Etiquetas libres sin catálogo |
| **Producto activo** | Se puede vender y modificar | “Visible” sin definición |
| **Desactivar** | El producto deja de estar a la venta | “Eliminar” (borrado físico) |
| **Reabastecer** | Aumentar unidades disponibles | “Agregar stock” sin reglas |

---

## 6. Reglas de negocio

| ID | Regla |
|---|---|
| RN-CAT-01 | El nombre del producto debe tener entre 3 y 200 caracteres |
| RN-CAT-02 | El precio debe ser mayor o igual a cero e incluir moneda válida (3 letras, ej. USD, MXN) |
| RN-CAT-03 | El stock inicial debe ser mayor o igual a cero |
| RN-CAT-04 | La categoría debe ser una de las permitidas: Electronics, Clothing, Food, Books, Sports |
| RN-CAT-05 | No puede haber dos productos activos con el mismo nombre |
| RN-CAT-06 | Al registrar un producto, queda **activo** por defecto |
| RN-CAT-07 | Solo productos activos pueden cambiar detalles, precio o stock |
| RN-CAT-08 | Cambiar el precio al mismo valor no genera un evento de cambio |
| RN-CAT-09 | No se puede descontar más stock del disponible |
| RN-CAT-10 | Desactivar un producto ya inactivo no produce error |
| RN-CAT-13 | Los avisos a otros sistemas se envían **después** de guardar el producto |
| RN-CAT-14 | En el entorno de desarrollo, los avisos pueden registrarse en bitácora sin mensajería externa |

---

## 7. Criterios de aceptación de negocio (CA-N)

| ID | Criterio |
|---|---|
| CA-N01 | Dado un producto con datos válidos, cuando el administrador lo registra, entonces el sistema confirma el alta y asigna un identificador único |
| CA-N02 | Dado un nombre de producto que ya existe activo, cuando se intenta registrar otro igual, entonces el sistema rechaza la operación e informa el conflicto |
| CA-N03 | Dado un nombre demasiado corto o un precio negativo, cuando se intenta registrar, entonces el sistema rechaza e indica qué campo es inválido |
| CA-N04 | Dado un producto registrado, cuando se consulta el catálogo, entonces el producto aparece con todos sus datos |
| CA-N05 | Dado un producto recién registrado, entonces otros sistemas pueden ser notificados de su creación |
| CA-N06 | Dado un producto inactivo, cuando se intenta modificar precio o stock, entonces el sistema rechaza la operación |
| CA-N07 | Dado un error de regla de negocio, cuando ocurre una operación inválida, entonces el usuario recibe un mensaje claro (no un error técnico crudo) |

---

## 8. Trazabilidad

| Requerimiento | Historia de usuario |
|---|---|
| RF-01 | [HU-CAT-01](./HISTORIAS-USUARIO-CATALOG.md#hu-cat-01--registrar-producto-en-catálogo) |
| RF-04 | [HU-CAT-02](./HISTORIAS-USUARIO-CATALOG.md#hu-cat-02--notificar-cambios-del-catálogo) |
| RF-05, RF-09 | [HU-CAT-03](./HISTORIAS-USUARIO-CATALOG.md#hu-cat-03--recibir-mensajes-claros-de-error) |
| RF-10–RF-15 | Historias preparadas en [HISTORIAS-USUARIO-CATALOG.md](./HISTORIAS-USUARIO-CATALOG.md) |

---

## 9. Referencias

- [GUIA-ESTRUCTURA-DOCUMENTACION.md](../GUIA-ESTRUCTURA-DOCUMENTACION.md)
- [REQUERIMIENTOS-ORDERS.md](../orders/REQUERIMIENTOS-ORDERS.md)
- [REQUERIMIENTOS-INVENTORY.md](../inventory/REQUERIMIENTOS-INVENTORY.md)
- [RETO-TECNICO-SHOPDEMO.md](../RETO-TECNICO-SHOPDEMO.md)
