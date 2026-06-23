# Requerimientos — Despliegue de contenedores en AWS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Plataforma:** Amazon Web Services  
**Servicio de cómputo:** Amazon ECS con Fargate  
**Versión:** 1.0

---

## 1. Propósito

Justificar el despliegue de los microservicios ShopDemo containerizados en **AWS**, con el mismo alcance funcional que la pista Azure, pero usando **ECR + ECS Fargate**, documentado con **Consola AWS** y **AWS CLI**.

---

## 2. Problema actual

Los alumnos pueden ejecutar `docker compose` en local, pero:

- No existe guía para **AWS** equivalente a Container Apps
- Orders depende de una URL de Inventory que debe resolverse en la nube
- Las imágenes no están en un registro AWS (**ECR**)
- Event Hubs está en Azure — se requiere estrategia **cross-cloud** explícita para el lab

---

## 3. Objetivos

| ID | Objetivo |
|---|---|
| OBJ-AW-01 | Publicar imágenes ShopDemo en **Amazon ECR** |
| OBJ-AW-02 | Ejecutar Catalog, Orders, Inventory y Analytics en **ECS Fargate** |
| OBJ-AW-03 | PostgreSQL y Azurite en **contenedores ECS** (enfoque lab) |
| OBJ-AW-04 | Orders descubre Inventory vía **Cloud Map** |
| OBJ-AW-05 | APIs se conectan a **Azure Event Hubs** (código actual sin cambios) |
| OBJ-AW-06 | Documentar pasos en **Consola AWS** y **AWS CLI** |
| OBJ-AW-07 | Pipeline básico GitHub Actions hacia ECR/ECS |

---

## 4. Alcance

### Incluido

- VPC básica, subnets, security groups
- ECR (4 repositorios)
- ECS cluster Fargate
- Task definitions y services por API
- ALB para APIs públicas (Catalog, Orders, Analytics)
- Service discovery para Inventory
- PostgreSQL + Azurite como ECS services
- Secrets en Parameter Store / Secrets Manager (lab)

### Excluido

- Amazon RDS / Aurora (BD gestionada)
- MSK / Kinesis (sustituto de Event Hubs)
- EKS (Kubernetes)
- App Runner
- Despliegue de Aspire AppHost
- Multi-región y DR

---

## 5. Requerimientos funcionales

| ID | Requerimiento |
|---|---|
| RF-AW-01 | APIs accesibles vía DNS del ALB |
| RF-AW-02 | Flujo Catalog → Event Hubs → Analytics observable |
| RF-AW-03 | Orders confirma pedido llamando Inventory por service discovery |
| RF-AW-04 | Actualizar versión mediante nueva imagen en ECR + redeploy |

---

## 6. Requerimientos no funcionales

| ID | Requerimiento |
|---|---|
| RNF-AW-01 | Implementación en 3–5 horas (primer despliegue) |
| RNF-AW-02 | Región única (`us-east-1` recomendada) |
| RNF-AW-03 | Salida a internet permitida hacia Azure Event Hubs |
| RNF-AW-04 | Documentación dual Consola + CLI |

---

## 7. Matriz de servicios ECS

| Servicio ECS | Repositorio ECR | ALB público | Service discovery |
|---|---|---|---|
| `shopdemo-catalog` | `shopdemo-catalog` | Sí | No |
| `shopdemo-orders` | `shopdemo-orders` | Sí | No (cliente de Inventory) |
| `shopdemo-inventory` | `shopdemo-inventory` | No (lab) | Sí (`inventory`) |
| `shopdemo-analytics` | `shopdemo-analytics` | Sí | No |
| `shopdemo-postgres` | — (imagen Docker Hub) | No | Opcional (`postgres`) |
| `shopdemo-azurite` | — (imagen Microsoft) | No | Opcional (`azurite`) |

---

## 8. Criterios de aceptación

| # | Criterio |
|---|---|
| CA-AW-01 | 4 servicios ECS en estado `RUNNING` |
| CA-AW-02 | Health/Swagger responde en URL del ALB de Catalog |
| CA-AW-03 | `GET /api/analytics/events` devuelve eventos tras crear producto |
| CA-AW-04 | Confirmación de pedido en Orders exitosa |
| CA-AW-05 | Alumno ejecutó pasos por Consola y por CLI |

---

## 9. Consideración cross-cloud (Event Hubs)

El código usa `Azure.Messaging.EventHubs`. En AWS:

- Los task definitions incluyen `EventHubs__ConnectionString` apuntando al namespace Azure
- Los security groups deben permitir **egress HTTPS (443)** hacia internet
- Latencia y costos cross-cloud son aceptables para **laboratorio**, no para producción

---

## 10. Referencias

- [TEORIA-CONTENEDORES-AWS.md](./TEORIA-CONTENEDORES-AWS.md)
- [IMPLEMENTACION-DESPLIEGUE-AWS.md](./IMPLEMENTACION-DESPLIEGUE-AWS.md)
- [IMPLEMENTACION-DESPLIEGUE-AZURE.md](../azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md) (pista paralela)
