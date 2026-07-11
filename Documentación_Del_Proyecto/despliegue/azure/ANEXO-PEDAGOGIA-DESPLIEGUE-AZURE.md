# Anexo — Pedagogía: Despliegue Azure (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | C — Objetivos del curso |
| **Audiencia** | Instructor y alumno |

---

## 1. Objetivos de aprendizaje

Al completar esta etapa, el alumno será capaz de:

1. Empaquetar microservicios .NET en **imágenes Docker** y publicarlas en **ACR**.
2. Desplegar aplicaciones en **Azure Container Apps** con secretos y variables de entorno.
3. Configurar **PostgreSQL en contenedor** (ACI) para laboratorio.
4. Integrar **Azure Event Hubs** y **Storage Account** para checkpoints en nube.
5. Ejecutar el **flujo E2E** de ShopDemo contra URLs públicas de ACA.
6. Automatizar release con **GitHub Actions** hacia ACR/ACA.
7. Operar recursos Azure vía **Portal** y **Azure CLI**.

---

## 2. Contexto pedagógico

| Aspecto | Detalle del curso |
|---|---|
| Posición en el roadmap | Etapa 7 — Release Azure serverless |
| Prerequisitos | Catalog, Orders, Inventory, Analytics implementados; Docker Compose validado |
| Comparación posterior | Etapa 10 AKS reutiliza mismas imágenes ACR |
| Alternativa cloud | Etapa 8 AWS ECS (mismo alcance funcional) |

---

## 3. Tiempo estimado

| Actividad | Duración |
|---|---|
| Preparación ambiente Azure | 30–45 min |
| Primer despliegue manual (Portal o CLI) | 2–3 h |
| Validación E2E + documentación | 45–60 min |
| Pipeline CI/CD (opcional en misma sesión) | 30–45 min |
| **Total primer release** | **3–5 h** |

---

## 4. Entregables del alumno

| # | Entregable |
|---|---|
| 1 | Resource Group con ACR, ACA Environment y 5 Container Apps Running |
| 2 | Captura de health/Swagger de Catalog en FQDN público |
| 3 | Evidencia flujo E2E: producto creado → evento en Analytics → pedido confirmado |
| 4 | Al menos un paso documentado en Portal **y** equivalente en CLI |
| 5 | (Opcional) Run exitoso de `deploy-azure.yml` |

---

## 5. Alcance pedagógico vs. producción

| Tema | En el curso | Fuera del curso |
|---|---|---|
| Azure Database for PostgreSQL | No | Producción enterprise |
| `azd up` / Aspire publish | No | Flujo productivo Aspire |
| Multi-región / HA | No | DR enterprise |
| WAF / API Management | No | Seguridad perimetral avanzada |

---

## 6. Reflexión guiada

1. ¿Por qué Inventory tiene ingress **interno** y Catalog **externo**?
2. ¿Qué ocurre con los datos si se recrea el contenedor PostgreSQL en ACI?
3. ¿Cómo se relaciona este despliegue con el AppHost Aspire local?

---

## 7. Referencias de estudio

- [IMPLEMENTACION-DESPLIEGUE-AZURE.md](./IMPLEMENTACION-DESPLIEGUE-AZURE.md)
- [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AZURE.md](./ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AZURE.md)
- [TEORIA-CONTENEDORES-AZURE.md](./TEORIA-CONTENEDORES-AZURE.md)
- [Documentación_De_Estudio_Del_Curso/](../../../Documentación_De_Estudio_Del_Curso/)
