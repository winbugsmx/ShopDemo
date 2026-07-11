# Documento de Requerimientos — Observabilidad (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Módulo** | Observabilidad — diagnóstico operativo |
| **Versión** | 2.0 (enfoque negocio) |
| **Fecha** | Julio 2026 |

**Documentos relacionados:**

| Capa | Documento |
|---|---|
| Historias | [HISTORIAS-USUARIO-OBSERVABILIDAD.md](./HISTORIAS-USUARIO-OBSERVABILIDAD.md) |
| Especificación técnica | [ANEXO-ESPECIFICACION-TECNICA-OBSERVABILIDAD.md](./ANEXO-ESPECIFICACION-TECNICA-OBSERVABILIDAD.md) |
| Historias técnicas | [ANEXO-HISTORIAS-TECNICAS-OBSERVABILIDAD.md](./ANEXO-HISTORIAS-TECNICAS-OBSERVABILIDAD.md) |
| Pedagogía | [ANEXO-PEDAGOGIA-OBSERVABILIDAD.md](./ANEXO-PEDAGOGIA-OBSERVABILIDAD.md) |

---

## Resumen en lenguaje llano

Cuando un pedido falla en la nube, el equipo debe poder **saber qué pasó sin entrar a cada contenedor**. Observabilidad permite **centralizar logs**, consultar **métricas de salud**, **seguir una petición** por su identificador de rastreo y **recibir alertas** antes de que el cliente reporte el problema.

---

## 1. Propósito

Definir qué debe lograr la observabilidad de ShopDemo: diagnosticar fallos del flujo de pedidos y del e-commerce en entornos Azure y AWS.

---

## 2. Actores

| Actor | Rol |
|---|---|
| **Equipo de soporte** | Investiga incidentes y correlaciona errores |
| **Responsable de TI** | Configura agregación de logs y alertas |
| **Operador de la tienda** | Reporta síntomas (pedido fallido, lentitud) |

---

## 3. Objetivos operativos

| ID | Objetivo |
|---|---|
| OBJ-OBS-01 | **Diagnosticar fallos** del flujo de pedidos sin acceso SSH a contenedores |
| OBJ-OBS-02 | **Centralizar logs** de catálogo, pedidos, inventario y analítica |
| OBJ-OBS-03 | **Consultar métricas** de salud (CPU, reinicios, errores HTTP) |
| OBJ-OBS-04 | **Correlacionar** una petición fallida con sus registros |
| OBJ-OBS-05 | **Recibir alertas** ante degradación o errores repetidos |
| OBJ-OBS-06 | Cubrir los **cuatro entornos de cómputo** del lab (ACA, AKS, ECS, EKS) |

---

## 4. Requerimientos de negocio

| ID | Requerimiento |
|---|---|
| RF-OBS-01 | Ver logs de las 4 APIs de negocio en un panel cloud unificado |
| RF-OBS-02 | Localizar el origen de un error HTTP 5xx en menos de 15 minutos (lab) |
| RF-OBS-03 | Seguir una petición usando el identificador devuelto al cliente |
| RF-OBS-04 | Configurar al menos una alerta por umbral (errores o CPU) |
| RF-OBS-05 | Documentar flujo de investigación E2E reproducible |

---

## 5. Reglas de operación

| ID | Regla |
|---|---|
| RN-OBS-01 | Toda respuesta de error al cliente incluye identificador de rastreo |
| RN-OBS-02 | Logs no contienen secretos ni connection strings completos |
| RN-OBS-03 | Alertas deben probarse (disparo simulado o umbral real) antes de cerrar el módulo |

---

## 6. Fuera de alcance

- Modificar código de Source/Catalog, Source/Orders, Source/Inventory para OpenTelemetry (fase actual)
- Grafana/Prometheus self-hosted
- ML para predicción de fallos

---

## 7. Criterios de aceptación (CA-N)

| ID | Criterio |
|---|---|
| CA-N-OBS-01 | Dado un entorno desplegado, cuando soporte abre el panel de logs, entonces ve entradas de las 4 APIs |
| CA-N-OBS-02 | Dado un error con identificador de rastreo, cuando se busca en logs, entonces se encuentra el registro asociado |
| CA-N-OBS-03 | Dado umbral configurado, cuando se supera, entonces la alerta se dispara o queda documentada la prueba |
| CA-N-OBS-04 | Dado un incidente E2E simulado, cuando se sigue la guía, entonces se identifica el servicio afectado |
| CA-N-OBS-05 | Dado cada plataforma del lab, cuando se revisa documentación, entonces ACA, AKS, ECS y EKS están cubiertos |

---

## 8. Referencias

- [azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md](./azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md)
- [aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md](./aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md)
- [despliegue/](../despliegue/)
