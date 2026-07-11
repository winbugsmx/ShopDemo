# Documento de Requerimientos — Despliegue en AWS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Módulo** | Despliegue AWS — tienda en la nube |
| **Plataforma** | Amazon Web Services (ECS Fargate) |
| **Versión** | 2.0 (enfoque negocio) |
| **Fecha** | Julio 2026 |

**Documentos relacionados:**

| Capa | Documento |
|---|---|
| Historias de usuario | [HISTORIAS-USUARIO-DESPLIEGUE-AWS.md](./HISTORIAS-USUARIO-DESPLIEGUE-AWS.md) |
| Especificación técnica | [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AWS.md](./ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AWS.md) |
| Historias técnicas | [ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AWS.md](./ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AWS.md) |
| Pedagogía (curso) | [ANEXO-PEDAGOGIA-DESPLIEGUE-AWS.md](./ANEXO-PEDAGOGIA-DESPLIEGUE-AWS.md) |

---

## Resumen en lenguaje llano

ShopDemo debe **funcionar en AWS** con el mismo flujo de negocio que en Azure y en local: registrar productos, gestionar inventario, procesar pedidos y observar eventos. El equipo de TI despliega las aplicaciones en contenedores accesibles por internet, protege los secretos y garantiza que pedidos e inventario se comuniquen correctamente en la nube.

---

## 1. Propósito

Definir qué debe lograr el despliegue de ShopDemo en AWS desde la operación del e-commerce: disponibilidad del flujo E2E, acceso controlado a APIs y capacidad de actualizar el release.

---

## 2. Actores

| Actor | Rol |
|---|---|
| **Operador de la tienda** | Ejecuta flujos de productos y pedidos en nube AWS |
| **Responsable de TI** | Configura VPC, ECS, secretos y publicaciones |
| **Equipo de soporte** | Diagnostica incidentes y verifica salud del sistema |
| **Integraciones externas** | Consumen APIs vía balanceador de carga |

---

## 3. Contexto de negocio

| Paso | Qué ocurre |
|---|---|
| 1 | Producto registrado en catálogo AWS |
| 2 | Inventario asigna stock vía evento |
| 3 | Pedido creado y confirmado con reserva de stock |
| 4 | Analítica muestra eventos del flujo |
| 5 | MCP Gateway disponible para consultas asistidas |

---

## 4. Objetivos operativos

| ID | Objetivo |
|---|---|
| OBJ-AW-01 | La tienda ShopDemo está **disponible en AWS** con URLs accesibles vía balanceador |
| OBJ-AW-02 | El **flujo E2E** se completa sin errores en el entorno ECS |
| OBJ-AW-03 | Pedidos localiza inventario **sin configuración manual** de URLs locales |
| OBJ-AW-04 | Los **secretos** se gestionan de forma segura (no en repositorio) |
| OBJ-AW-05 | El responsable de TI puede **actualizar versiones** y validar operación |
| OBJ-AW-06 | Existe documentación operativa en **Consola AWS** y **AWS CLI** |

---

## 5. Alcance

### 5.1 Incluido (MVP lab)

| ID | Requerimiento de negocio |
|---|---|
| RF-AW-01 | APIs de catálogo, pedidos, analítica y MCP accesibles por DNS público |
| RF-AW-02 | Flujo catálogo → eventos → analítica observable |
| RF-AW-03 | Confirmación de pedido exitosa con reserva de stock |
| RF-AW-04 | Inventario accesible internamente para pedidos |
| RF-AW-05 | Actualización de release mediante nueva versión de imágenes |
| RF-AW-06 | Conexión al bus de eventos (Azure Event Hubs cross-cloud en lab) |

### 5.2 Fuera de alcance

- Amazon RDS / Aurora gestionado
- MSK / Kinesis como sustituto de Event Hubs
- Multi-región y recuperación ante desastres
- EKS (documento propio en [despliegue/eks/](../eks/))

---

## 6. Reglas de negocio / operación

| ID | Regla |
|---|---|
| RN-AW-01 | APIs públicas (catálogo, pedidos, analítica, MCP) vía ALB; inventario por descubrimiento interno |
| RN-AW-02 | Eventos de negocio fluyen por Event Hubs (cross-cloud aceptable en lab) |
| RN-AW-03 | Tras reinicio de PostgreSQL, el responsable de TI actualiza parámetros de conexión |
| RN-AW-04 | Secretos en Parameter Store / Secrets Manager, nunca en git |

---

## 7. Criterios de aceptación de negocio (CA-N)

| ID | Criterio |
|---|---|
| CA-N-AW-01 | Dado el entorno AWS, cuando se consulta salud del catálogo, entonces responde correctamente vía ALB |
| CA-N-AW-02 | Dado un producto creado en nube, cuando se consulta analítica, entonces el evento es visible |
| CA-N-AW-03 | Dado un pedido, cuando se confirma, entonces la reserva de stock se completa |
| CA-N-AW-04 | Dado un release actualizado, cuando se despliega nueva versión, entonces el flujo E2E sigue operativo |
| CA-N-AW-05 | Dado soporte revisando documentación, entonces encuentra pasos en Consola y CLI |

---

## 8. Trazabilidad

| Requerimiento | Historia |
|---|---|
| RF-AW-01, RF-AW-06 | [HU-AW-01](./HISTORIAS-USUARIO-DESPLIEGUE-AWS.md#hu-aw-01--acceder-a-apis-en-nube) |
| RF-AW-02 | [HU-AW-02](./HISTORIAS-USUARIO-DESPLIEGUE-AWS.md#hu-aw-02--verificar-eventos-del-negocio) |
| RF-AW-03, RF-AW-04 | [HU-AW-03](./HISTORIAS-USUARIO-DESPLIEGUE-AWS.md#hu-aw-03--procesar-pedidos-con-inventario) |
| RF-AW-05 | [HU-AW-04](./HISTORIAS-USUARIO-DESPLIEGUE-AWS.md#hu-aw-04--actualizar-release) |

---

## 9. Referencias

- [GUIA-ESTRUCTURA-DOCUMENTACION.md](../../GUIA-ESTRUCTURA-DOCUMENTACION.md)
- [IMPLEMENTACION-DESPLIEGUE-AWS.md](./IMPLEMENTACION-DESPLIEGUE-AWS.md)
- [despliegue/azure/](../azure/) — pista paralela Azure
