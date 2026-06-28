# Requerimientos — Observabilidad de microservicios (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Versión:** 1.0 · **Alcance:** básico, práctico, sin cambios obligatorios de código en esta etapa.

**Historias de usuario:** [HISTORIAS-USUARIO-OBSERVABILIDAD.md](./HISTORIAS-USUARIO-OBSERVABILIDAD.md)

---

## 1. Propósito

Justificar la necesidad de **observar** ShopDemo en producción/laboratorio nube: sin métricas, logs centralizados y correlación, un fallo en el flujo Orders → Inventory es difícil de diagnosticar cuando hay decenas de réplicas y cuatro APIs.

---

## 2. Problema actual

| Situación | Impacto |
|---|---|
| Logs solo en stdout del contenedor | Hay que entrar a cada instancia |
| Sin dashboard unificado en nube | No hay vista de salud del sistema |
| `traceId` existe en código pero no se explota en nube | Correlación manual o inexistente |
| OpenTelemetry solo en Analytics | Catalog/Orders/Inventory no exportan trazas aún |

---

## 3. Objetivos

| ID | Objetivo |
|---|---|
| OBJ-OBS-01 | Centralizar **logs** de las 4 APIs en Azure y AWS |
| OBJ-OBS-02 | Consultar **métricas** de infraestructura y HTTP |
| OBJ-OBS-03 | Documentar **trazas** y correlación con `traceId` + herramientas cloud |
| OBJ-OBS-04 | Configurar **alertas** básicas (5xx, reinicios, CPU) |
| OBJ-OBS-05 | Demostrar **agregación** en Log Analytics y CloudWatch |
| OBJ-OBS-06 | Investigar un error E2E usando correlación por `traceId` |
| OBJ-OBS-07 | Cubrir **ACA + AKS** (Azure) y **ECS + EKS** (AWS) |

---

## 4. Alcance incluido

- Diagnósticos de Container Apps y AKS hacia Log Analytics
- Log groups y Container Insights en ECS/EKS
- Consultas KQL (Azure) y Logs Insights (AWS)
- Alertas de métrica simples
- Uso del `traceId` existente en `ExceptionHandlingMiddleware`
- Métricas de Event Hubs en Azure Portal
- Aspire Dashboard como referencia **solo local**

## 5. No incluido en el curso

| Tema | Motivo |
|---|---|
| Modificar Program.cs de Catalog/Orders/Inventory para OTel | El lab usa observabilidad de plataforma (Log Analytics / CloudWatch) |
| IA para predicción de fallos | No forma parte del lab introductorio |
| Grafana/Prometheus self-hosted | Complejidad extra para lab básico |
| Optimización avanzada de costos en Log Analytics / CloudWatch | Fuera del curso introductorio |

---

## 6. Criterios de aceptación

| # | Criterio |
|---|---|
| CA-OBS-01 | Logs de las 4 APIs visibles en Log Analytics (Azure) o CloudWatch (AWS) |
| CA-OBS-02 | Al menos 1 alerta configurada y probada (umbral CPU o HTTP 5xx) |
| CA-OBS-03 | Alumno localiza un log usando `traceId` de una respuesta de error |
| CA-OBS-04 | Documentación completada para ACA, AKS, ECS y EKS |
| CA-OBS-05 | Flujo de investigación E2E documentado y reproducido |

---

## 7. Dependencias

- APIs desplegadas: [IMPLEMENTACION-DESPLIEGUE-AZURE.md](../despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md), [IMPLEMENTACION-DESPLIEGUE-AWS.md](../despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md), AKS, EKS
- Event Hubs opcional para métricas de mensajería

---

## Referencias

- [TEORIA-OBSERVABILIDAD.md](./TEORIA-OBSERVABILIDAD.md)
- [azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md](./azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md)
- [aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md](./aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md)
