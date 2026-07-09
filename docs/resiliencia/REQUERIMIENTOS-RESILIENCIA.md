# Documento de Requerimientos — Resiliencia (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Módulo** | Resiliencia — continuidad operativa |
| **Versión** | 2.0 (enfoque negocio) |
| **Fecha** | Julio 2026 |

**Documentos relacionados:**

| Capa | Documento |
|---|---|
| Historias | [HISTORIAS-USUARIO-RESILIENCIA.md](./HISTORIAS-USUARIO-RESILIENCIA.md) |
| Especificación técnica | [ANEXO-ESPECIFICACION-TECNICA-RESILIENCIA.md](./ANEXO-ESPECIFICACION-TECNICA-RESILIENCIA.md) |
| Historias técnicas | [ANEXO-HISTORIAS-TECNICAS-RESILIENCIA.md](./ANEXO-HISTORIAS-TECNICAS-RESILIENCIA.md) |
| Pedagogía | [ANEXO-PEDAGOGIA-RESILIENCIA.md](./ANEXO-PEDAGOGIA-RESILIENCIA.md) |

---

## Resumen en lenguaje llano

Si un servicio de la tienda falla, **el resto no debe caer en cadena**. Resiliencia garantiza que pedidos, inventario y catálogo **se recuperan solos** tras un reinicio, que solo instancias sanas reciben tráfico y que el equipo entiende la diferencia entre fallos **inmediatos** (pedido llama a inventario) y **diferidos** (eventos por mensajería).

---

## 1. Propósito

Definir qué debe lograr la resiliencia de ShopDemo: absorber fallos parciales sin detener todo el e-commerce en entornos multicloud.

---

## 2. Actores

| Actor | Rol |
|---|---|
| **Operador de la tienda** | Continúa operando mientras se recuperan servicios |
| **Responsable de TI** | Configura health checks, réplicas y escalado |
| **Equipo de soporte** | Explica impacto de fallos síncronos vs asíncronos |

---

## 3. Objetivos operativos

| ID | Objetivo |
|---|---|
| OBJ-RES-01 | Los servicios **se recuperan automáticamente** tras fallo de instancia |
| OBJ-RES-02 | Solo instancias **saludables** reciben tráfico de negocio |
| OBJ-RES-03 | Existe **redundancia mínima** (al menos una réplica operativa) |
| OBJ-RES-04 | El equipo **entiende** impacto de fallo pedidos→inventario vs Event Hubs |
| OBJ-RES-05 | Las **actualizaciones** de versión no dejan la tienda totalmente caída |
| OBJ-RES-06 | Prácticas aplicadas en **Azure (ACA+AKS)** y **AWS (ECS+EKS)** |

---

## 4. Requerimientos de negocio

| ID | Requerimiento |
|---|---|
| RF-RES-01 | Tras fallo de una instancia, el servicio vuelve a estar disponible sin intervención prolongada |
| RF-RES-02 | Health checks activos en los 4 servicios de negocio en cada plataforma |
| RF-RES-03 | Escalado ante carga demostrado en al menos un servicio |
| RF-RES-04 | Actualización rolling sin downtime total del e-commerce |
| RF-RES-05 | Documentación de patrones síncrono vs asíncrono en ShopDemo |

---

## 5. Reglas

| ID | Regla |
|---|---|
| RN-RES-01 | Mínimo 1 réplica operativa por servicio crítico |
| RN-RES-02 | Event Hubs desacopla inventario/analítica de publicadores |
| RN-RES-03 | Fallo síncrono Orders→Inventory bloquea confirmación; fallo asíncrono no bloquea creación de producto |

---

## 6. Fuera de alcance

- Multi-región / DR enterprise
- Chaos Engineering (Chaos Mesh, FIS)
- Polly/retry en código (opcional avanzado)

---

## 7. Criterios de aceptación (CA-N)

| ID | Criterio |
|---|---|
| CA-N-RES-01 | Dado un pod/tarea eliminada, cuando pasa el tiempo de recuperación, entonces el servicio vuelve a Ready |
| CA-N-RES-02 | Dado tráfico entrante, cuando una instancia no está saludable, entonces no recibe peticiones |
| CA-N-RES-03 | Dado soporte, cuando explica tipos de fallo, entonces diferencia síncrono vs asíncrono |
| CA-N-RES-04 | Dado pico de carga simulado, cuando se escala, entonces el servicio mantiene respuesta |
| CA-N-RES-05 | Dado guías Azure y AWS, cuando se completan, entonces resiliencia documentada en ambas nubes |

---

## 8. Referencias

- [azure/IMPLEMENTACION-RESILIENCIA-AZURE.md](./azure/IMPLEMENTACION-RESILIENCIA-AZURE.md)
- [aws/IMPLEMENTACION-RESILIENCIA-AWS.md](./aws/IMPLEMENTACION-RESILIENCIA-AWS.md)
