# Documento de Requerimientos — Analytics (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Módulo** | Analytics — visibilidad de eventos de negocio |
| **Versión** | 2.0 (enfoque negocio) |
| **Fecha** | Julio 2026 |

**Documentos relacionados:**

| Capa | Documento |
|---|---|
| Historias | [HISTORIAS-USUARIO-ANALYTICS-ASPIRE.md](./HISTORIAS-USUARIO-ANALYTICS-ASPIRE.md) |
| Especificación técnica | [ANEXO-ESPECIFICACION-TECNICA-ANALYTICS-ASPIRE.md](./ANEXO-ESPECIFICACION-TECNICA-ANALYTICS-ASPIRE.md) |
| Historias técnicas | [ANEXO-HISTORIAS-TECNICAS-ANALYTICS-ASPIRE.md](./ANEXO-HISTORIAS-TECNICAS-ANALYTICS-ASPIRE.md) |
| Pedagogía | [ANEXO-PEDAGOGIA-ANALYTICS-ASPIRE.md](./ANEXO-PEDAGOGIA-ANALYTICS-ASPIRE.md) |

---

## Resumen en lenguaje llano

El negocio necesita **ver qué está pasando en la tienda** sin revisar cada sistema por separado. Analytics **observa los eventos** del flujo (producto creado, pedido confirmado, stock actualizado) y los muestra en un **panel consultable**, sin modificar catálogo, pedidos ni inventario. En desarrollo local, un orquestador arranca todos los servicios juntos para facilitar pruebas.

---

## 1. Propósito

Definir qué debe lograr Analytics y la orquestación local: visibilidad de eventos de negocio y demostración del patrón fan-out (mismo evento, múltiples consumidores).

---

## 2. Actores

| Actor | Rol |
|---|---|
| **Responsable de operaciones** | Consulta eventos recientes del flujo de la tienda |
| **Equipo de soporte** | Verifica que acciones de negocio generan eventos esperados |
| **Responsable de TI** | Arranca el entorno integrado local para pruebas |

---

## 3. Contexto de negocio

| Paso | Qué ocurre |
|---|---|
| 1 | Se registra un **producto** en catálogo |
| 2 | Se publica un **evento** al bus de mensajería |
| 3 | **Inventario** consume y asigna stock (sin intervención manual) |
| 4 | **Analytics** observa el mismo evento en paralelo |
| 5 | Operaciones **consulta** la lista de eventos observados |
| 6 | Se crea y **confirma un pedido**; nuevos eventos aparecen en analítica |

---

## 4. Objetivos operativos

| ID | Objetivo |
|---|---|
| OBJ-AN-01 | **Ver eventos del negocio** en un panel consultable tras acciones de la tienda |
| OBJ-AN-02 | Confirmar que **inventario sigue operando** sin regresión al agregar analítica |
| OBJ-AN-03 | Demostrar que **un mismo evento** alimenta inventario y analítica en paralelo |
| OBJ-AN-04 | Arrancar el **entorno completo** local con un solo comando para pruebas E2E |
| OBJ-AN-05 | Mantener **catálogo, pedidos e inventario sin cambios** de dominio en fase 1 |

---

## 5. Requerimientos de negocio

| ID | Requerimiento |
|---|---|
| RF-AN-01 | Tras registrar producto, el evento es **consultable** en analítica |
| RF-AN-02 | Tras confirmar pedido, los eventos relacionados son **visibles** |
| RF-AN-03 | Inventario **sigue auto-registrando stock** al crear producto |
| RF-AN-04 | Analítica **no modifica** otros sistemas (solo observa) |
| RF-AN-05 | El entorno local integrado levanta **catálogo, pedidos, inventario y analítica** juntos |
| RF-AN-06 | Pedidos confirma reservas usando inventario **sin URLs manuales** en desarrollo integrado |

---

## 6. Reglas de negocio

| ID | Regla |
|---|---|
| RN-AN-01 | Analítica consume el bus con grupo de consumo **distinto** de inventario |
| RN-AN-02 | Analítica almacena últimos eventos en memoria (límite de ventana consultable) |
| RN-AN-03 | Analítica no ejecuta lógica de venta, stock ni pedidos |
| RN-AN-04 | Los eventos observados reflejan el envelope de integración compartido |

---

## 7. Fuera de alcance

- Persistencia durable de eventos (histórico largo plazo)
- Autenticación en API de analítica
- Modificar dominio de Catalog, Orders, Inventory

---

## 8. Criterios de aceptación (CA-N)

| ID | Criterio |
|---|---|
| CA-N-AN-01 | Dado producto válido creado, cuando operaciones consulta analítica, entonces ve evento de creación |
| CA-N-AN-02 | Dado pedido confirmado, cuando se consulta analítica, entonces aparecen eventos de pedidos |
| CA-N-AN-03 | Dado producto creado, cuando se revisa inventario, entonces stock asignado sin regresión |
| CA-N-AN-04 | Dado entorno integrado local, cuando responsable TI ejecuta un arranque, entonces las 4 APIs están operativas |
| CA-N-AN-05 | Dado confirmación de pedido en entorno integrado, entonces se completa sin error de conexión a inventario |

---

## 9. Trazabilidad

| RF | Historia |
|---|---|
| RF-AN-01, RF-AN-04 | [HU-AN-01](./HISTORIAS-USUARIO-ANALYTICS-ASPIRE.md#hu-an-01--observar-eventos-del-negocio) |
| RF-AN-02 | [HU-AN-02](./HISTORIAS-USUARIO-ANALYTICS-ASPIRE.md#hu-an-02--consultar-historial-reciente) |
| RF-AN-03 | [HU-AN-01](./HISTORIAS-USUARIO-ANALYTICS-ASPIRE.md#hu-an-01--observar-eventos-del-negocio) |
| RF-AN-05, RF-AN-06 | [HU-AH-01](./HISTORIAS-USUARIO-ANALYTICS-ASPIRE.md#hu-ah-01--arrancar-entorno-integrado) |

---

## 10. Referencias

- [IMPLEMENTACION-ANALYTICS-ASPIRE.md](./IMPLEMENTACION-ANALYTICS-ASPIRE.md)
- [INTEGRACION-AZURE-EVENT-HUBS.md](../INTEGRACION-AZURE-EVENT-HUBS.md)
