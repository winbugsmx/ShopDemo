# Anexo — Pedagogía: Despliegue AWS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | C — Objetivos del curso |
| **Audiencia** | Instructor y alumno |

---

## 1. Objetivos de aprendizaje

1. Publicar imágenes en **Amazon ECR** y desplegar en **ECS Fargate**.
2. Configurar **VPC, ALB y security groups** para microservicios.
3. Usar **Cloud Map** para descubrimiento de Inventory.
4. Gestionar secretos en **SSM Parameter Store**.
5. Integrar **Event Hubs cross-cloud** desde AWS.
6. Automatizar con **GitHub Actions** (`deploy-aws.yml`).
7. Operar vía **Consola AWS** y **AWS CLI**.

---

## 2. Contexto pedagógico

| Aspecto | Detalle |
|---|---|
| Posición | Etapa 8 — Release AWS serverless |
| Prerequisito | Etapa 7 Azure ACA (conceptos paralelos) o experiencia equivalente |
| Siguiente | Etapa 11 EKS |

---

## 3. Tiempo estimado

| Actividad | Duración |
|---|---|
| Preparación IAM y VPC | 45–60 min |
| Primer despliegue ECS | 2–4 h |
| Validación E2E | 45 min |
| **Total** | **3–5 h** |

---

## 4. Entregables del alumno

| # | Entregable |
|---|---|
| 1 | Cluster ECS con servicios Running |
| 2 | Captura Swagger Catalog vía ALB |
| 3 | Evidencia E2E con evento en Analytics |
| 4 | Paso documentado en Consola y CLI |
| 5 | (Opcional) Run `deploy-aws.yml` |

---

## 5. Reflexión guiada

1. ¿Por qué Event Hubs sigue en Azure aunque el cómputo esté en AWS?
2. ¿Qué ventaja ofrece Cloud Map frente a URLs hardcodeadas?
3. ¿Cuándo elegir ECS vs EKS para ShopDemo?

---

## 6. Referencias

- [IMPLEMENTACION-DESPLIEGUE-AWS.md](./IMPLEMENTACION-DESPLIEGUE-AWS.md)
- [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AWS.md](./ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AWS.md)
