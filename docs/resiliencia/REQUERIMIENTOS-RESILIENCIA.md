# Requerimientos — Resiliencia de servicios (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Versión:** 1.0 · **Alcance:** básico, configuración en plataforma (sin cambios .NET obligatorios).

**Historias de usuario:** [HISTORIAS-USUARIO-RESILIENCIA.md](./HISTORIAS-USUARIO-RESILIENCIA.md)

---

## 1. Propósito

Justificar prácticas de **resiliencia** para ShopDemo en multicloud: los microservicios fallan de forma independiente; la plataforma y la arquitectura deben **absorber** esos fallos sin detener todo el e-commerce.

---

## 2. Objetivos

| ID | Objetivo |
|---|---|
| OBJ-RES-01 | Aplicar **health checks** en ACA, AKS, ECS y EKS |
| OBJ-RES-02 | Configurar **redundancia** (mínimo 1 réplica; escalado donde aplique) |
| OBJ-RES-03 | Documentar **comunicación síncrona vs asíncrona** en ShopDemo |
| OBJ-RES-04 | Demostrar **recuperación** tras fallo de un pod/tarea |
| OBJ-RES-05 | Usar **HPA** (K8s) o reglas de escala (ACA) como resiliencia ante carga |
| OBJ-RES-06 | Cubrir **Azure (ACA + AKS)** y **AWS (ECS + EKS)** por separado |

---

## 3. Alcance incluido

- Probes HTTP `/health` y `/alive` (ya en código)
- Réplicas múltiples en ACA (min 1, max 3 lab)
- HPA Catalog en AKS/EKS
- ECS desired count ≥ 1 + health check ALB
- Event Hubs como patrón de resiliencia asíncrona
- Rolling updates / revisiones sin downtime total

## 4. Fuera de alcance

| Tema | Motivo |
|---|---|
| Implementar Polly/retry en `InventoryHttpClient` | Etapa de código futura |
| Multi-AZ / multi-region DR | Complejidad enterprise |
| **IA para predicción de fallos** | Etapa futura (ver teoría §7) |
| Chaos Engineering (Chaos Mesh, FIS) | Opcional avanzado |

---

## 5. Criterios de aceptación

| # | Criterio |
|---|---|
| CA-RES-01 | Tras `kubectl delete pod` / reinicio de tarea ECS, el servicio vuelve a Ready |
| CA-RES-02 | Health probe configurado en los 4 servicios en cada plataforma |
| CA-RES-03 | Alumno explica diferencia fallo síncrono Orders→Inventory vs asíncrono Event Hubs |
| CA-RES-04 | Escalado manual o HPA demostrado en al menos un servicio |
| CA-RES-05 | Guías Azure y AWS completadas |

---

## Referencias

- [TEORIA-RESILIENCIA.md](./TEORIA-RESILIENCIA.md)
- [azure/IMPLEMENTACION-RESILIENCIA-AZURE.md](./azure/IMPLEMENTACION-RESILIENCIA-AZURE.md)
- [aws/IMPLEMENTACION-RESILIENCIA-AWS.md](./aws/IMPLEMENTACION-RESILIENCIA-AWS.md)
