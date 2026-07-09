# Documento de Requerimientos — Despliegue en Azure (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Módulo** | Despliegue Azure — tienda en la nube |
| **Plataforma** | Microsoft Azure (Container Apps) |
| **Versión** | 2.0 (enfoque negocio) |
| **Fecha** | Julio 2026 |

**Documentos relacionados:**

| Capa | Documento |
|---|---|
| Historias de usuario | [HISTORIAS-USUARIO-DESPLIEGUE-AZURE.md](./HISTORIAS-USUARIO-DESPLIEGUE-AZURE.md) |
| Especificación técnica | [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AZURE.md](./ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AZURE.md) |
| Historias técnicas | [ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AZURE.md](./ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AZURE.md) |
| Pedagogía (curso) | [ANEXO-PEDAGOGIA-DESPLIEGUE-AZURE.md](./ANEXO-PEDAGOGIA-DESPLIEGUE-AZURE.md) |

---

## Resumen en lenguaje llano

ShopDemo debe poder **funcionar en Azure** igual que en la máquina local: un operador puede **registrar productos**, **crear y confirmar pedidos**, y **ver los eventos del negocio** sin depender de `localhost`. La tienda queda accesible por URLs públicas seguras, con datos y secretos protegidos, y el flujo completo (catálogo → inventario → pedidos → analítica) debe completarse de punta a punta en la nube.

---

## 1. Propósito

Definir **qué debe lograr** el despliegue de ShopDemo en Azure desde la perspectiva operativa y de negocio: disponibilidad del e-commerce en la nube, continuidad del flujo E2E y capacidad de actualizar el release sin interrumpir la operación.

---

## 2. Actores

| Actor | Rol |
|---|---|
| **Operador de la tienda** | Ejecuta el flujo de negocio (productos, pedidos) contra APIs en nube |
| **Responsable de TI** | Publica, configura y mantiene el entorno Azure |
| **Equipo de soporte** | Verifica salud del sistema y responde incidentes |
| **Integraciones externas** | Consumen APIs públicas (catálogo, pedidos, analítica) |

---

## 3. Contexto de negocio

Flujo integrado que debe funcionar en Azure:

| Paso | Qué ocurre |
|---|---|
| 1 | Se **registra un producto** en el catálogo desplegado |
| 2 | El **inventario** recibe el evento y asigna stock |
| 3 | Un **pedido** incluye ese producto |
| 4 | Al **confirmar el pedido**, se reserva stock vía comunicación entre servicios |
| 5 | **Analítica** muestra los eventos observados del flujo |
| 6 | Un **agente o integración** puede consultar el estado vía MCP Gateway |

---

## 4. Objetivos operativos

| ID | Objetivo |
|---|---|
| OBJ-AZ-01 | La tienda ShopDemo está **disponible en Azure** con URLs accesibles para operación y pruebas |
| OBJ-AZ-02 | El **flujo E2E** (producto → pedido → confirmación → eventos) se completa sin errores en nube |
| OBJ-AZ-03 | Los **datos de negocio** (catálogo, pedidos, inventario) persisten durante la vida del entorno |
| OBJ-AZ-04 | Los **secretos y credenciales** no quedan expuestos en repositorios ni documentación pública |
| OBJ-AZ-05 | El responsable de TI puede **actualizar una versión** del release y verificar que sigue operativo |
| OBJ-AZ-06 | Existe **documentación operativa** reproducible (Portal y línea de comandos) para el equipo |

---

## 5. Alcance

### 5.1 Incluido (MVP lab)

| ID | Requerimiento de negocio |
|---|---|
| RF-AZ-01 | Registrar productos en catálogo desplegado en Azure |
| RF-AZ-02 | Inventario operativo con stock asignado tras crear producto |
| RF-AZ-03 | Crear y confirmar pedidos reservando stock correctamente |
| RF-AZ-04 | Consultar eventos de negocio observados en analítica |
| RF-AZ-05 | Acceder al gateway MCP para consultas asistidas por agentes |
| RF-AZ-06 | Verificar salud de cada servicio antes de operar el flujo |
| RF-AZ-07 | Actualizar el release publicando una nueva versión de las aplicaciones |

### 5.2 Fuera de alcance

- Alta disponibilidad multi-región o recuperación ante desastres enterprise
- Base de datos PostgreSQL gestionada de producción
- Certificados personalizados, WAF o API Management avanzado
- Publicación automática desde Aspire AppHost (`azd up`)

---

## 6. Reglas de negocio / operación

| ID | Regla |
|---|---|
| RN-AZ-01 | El catálogo, pedidos, analítica y MCP son **accesibles externamente**; inventario es de uso interno entre servicios |
| RN-AZ-02 | Los eventos de negocio deben fluir por el bus de mensajería configurado (Event Hubs) |
| RN-AZ-03 | La confirmación de pedido **no debe fallar** por indisponibilidad de la URL interna de inventario |
| RN-AZ-04 | Los datos en PostgreSQL de laboratorio pueden ser **efímeros** si se recrea el contenedor (debe documentarse al operador) |
| RN-AZ-05 | Ningún secreto (connection strings, API keys) se commitea al repositorio |

---

## 7. Criterios de aceptación de negocio (CA-N)

| ID | Criterio |
|---|---|
| CA-N-AZ-01 | Dado el entorno Azure desplegado, cuando el operador consulta la salud del catálogo, entonces recibe respuesta exitosa |
| CA-N-AZ-02 | Dado un producto con datos válidos, cuando se registra en catálogo en nube, entonces aparece en analítica como evento observado |
| CA-N-AZ-03 | Dado un pedido creado, cuando se confirma en nube, entonces la reserva de stock se completa sin error de comunicación |
| CA-N-AZ-04 | Dado un release actualizado, cuando el responsable de TI publica la nueva versión, entonces el flujo E2E sigue funcionando |
| CA-N-AZ-05 | Dado un incidente reportado, cuando soporte revisa la documentación, entonces encuentra pasos equivalentes en Portal y CLI |
| CA-N-AZ-06 | Dado el gateway MCP desplegado, cuando un agente consulta el estado de la tienda, entonces recibe información coherente con las APIs |

---

## 8. Trazabilidad

| Requerimiento | Historia de usuario |
|---|---|
| RF-AZ-01, RF-AZ-06 | [HU-AZ-01](./HISTORIAS-USUARIO-DESPLIEGUE-AZURE.md#hu-az-01--operar-catálogo-en-nube) |
| RF-AZ-02, RF-AZ-03 | [HU-AZ-02](./HISTORIAS-USUARIO-DESPLIEGUE-AZURE.md#hu-az-02--completar-flujo-de-pedido-en-nube) |
| RF-AZ-04 | [HU-AZ-03](./HISTORIAS-USUARIO-DESPLIEGUE-AZURE.md#hu-az-03--observar-eventos-de-negocio) |
| RF-AZ-05 | [HU-AZ-04](./HISTORIAS-USUARIO-DESPLIEGUE-AZURE.md#hu-az-04--consultar-tienda-vía-agente) |
| RF-AZ-07 | [HU-AZ-05](./HISTORIAS-USUARIO-DESPLIEGUE-AZURE.md#hu-az-05--actualizar-release-sin-interrumpir-operación) |

---

## 9. Referencias

- [GUIA-ESTRUCTURA-DOCUMENTACION.md](../../GUIA-ESTRUCTURA-DOCUMENTACION.md)
- [IMPLEMENTACION-DESPLIEGUE-AZURE.md](./IMPLEMENTACION-DESPLIEGUE-AZURE.md)
- [ALCANCE-LAB-RELEASE.md](../ALCANCE-LAB-RELEASE.md)
- [ARQUITECTURA.md](../../ARQUITECTURA.md)
