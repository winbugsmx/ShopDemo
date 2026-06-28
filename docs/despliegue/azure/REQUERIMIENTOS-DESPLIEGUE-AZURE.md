# Requerimientos — Despliegue de contenedores en Azure (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Plataforma:** Microsoft Azure  
**Servicio de cómputo:** Azure Container Apps  
**Versión:** 1.0

**Historias de usuario:** [HISTORIAS-USUARIO-DESPLIEGUE-AZURE.md](./HISTORIAS-USUARIO-DESPLIEGUE-AZURE.md)

---

## 1. Propósito

Justificar y delimitar el trabajo necesario para desplegar los microservicios ShopDemo **empaquetados en Docker** hacia Azure, usando un enfoque **básico, práctico y reproducible** para alumnos.

---

## 2. Problema actual

| Situación | Limitación |
|---|---|
| `docker-compose.yml` por servicio | Solo funciona en la máquina local del alumno |
| URLs `localhost` y `host.docker.internal` | No válidas en la nube |
| Secretos en `.env` local | No deben copiarse tal cual a producción |
| Sin registro de imágenes central | Cada alumno construye en local sin estándar |
| Aspire AppHost | Orquesta en dev local; en nube cada API se despliega como contenedor independiente (etapa 7+) |

**Necesidad:** un camino documentado para subir las **mismas imágenes Docker** a Azure y ejecutarlas en **Container Apps**, configurando red, secretos y dependencias.

---

## 3. Objetivos

| ID | Objetivo |
|---|---|
| OBJ-AZ-01 | Publicar imágenes de Catalog, Orders, Inventory, Analytics y MCP en **ACR** |
| OBJ-AZ-02 | Ejecutar **5** Container Apps (4 APIs + MCP Gateway) |
| OBJ-AZ-03 | PostgreSQL en ACI; checkpoints Event Hubs vía **Storage Account** (ACA) o Azurite (AKS) |
| OBJ-AZ-04 | Conectar APIs a **Azure Event Hubs** existente vía secretos |
| OBJ-AZ-05 | Permitir que Orders invoque Inventory por **URL interna** de ACA |
| OBJ-AZ-06 | Documentar cada paso en **Portal Azure** y **Azure CLI** |
| OBJ-AZ-07 | Incluir pipeline básico **GitHub Actions** (build + push + deploy) |

---

## 4. Alcance

### Incluido

- Ajustes Docker: Dockerfile de Analytics, variables de entorno cloud
- Creación de Resource Group, ACR, Log Analytics, Container Apps Environment
- Despliegue de **5** Container Apps (4 APIs + MCP Gateway)
- PostgreSQL en ACI (3 bases o 3 instancias)
- Storage Account para checkpoints de Inventory/Analytics en ACA
- Configuración de secretos Event Hubs
- Guías Script, CLI y Portal (+ AKS opcional, etapa 10)

### No incluido en el lab

- `azd up` / publicación automática desde Aspire AppHost
- Azure Database for PostgreSQL gestionado
- Alta disponibilidad multi-región
- WAF, API Management, certificados custom avanzados
- Despliegue del AppHost Aspire como servicio en nube

---

## 5. Requerimientos funcionales

| ID | Requerimiento |
|---|---|
| RF-AZ-01 | El alumno puede crear un producto vía Catalog desplegado en ACA |
| RF-AZ-02 | Inventory recibe eventos y/o stock operativo con PostgreSQL en contenedor |
| RF-AZ-03 | Orders confirma pedidos reservando stock en Inventory por HTTP |
| RF-AZ-04 | Analytics expone eventos observados en `GET /api/analytics/events` |
| RF-AZ-05 | Las imágenes se actualizan mediante nuevo push a ACR y revisión en ACA |

---

## 6. Requerimientos no funcionales

| ID | Requerimiento |
|---|---|
| RNF-AZ-01 | Tiempo de implementación estimado: 2–4 horas por alumno |
| RNF-AZ-02 | Costo acotado a tier Basic / consumo mínimo de ACA |
| RNF-AZ-03 | Secretos nunca en repositorio git |
| RNF-AZ-04 | Documentación con capturas conceptuales y comandos reproducibles |
| RNF-AZ-05 | Coexistencia con `docker compose` local sin romper flujos del curso |

---

## 7. Matriz de servicios

| Servicio | Imagen ACR | Puerto contenedor | Ingress ACA | Dependencias |
|---|---|---|---|---|
| Catalog | `shopdemo-catalog` | 8080 | Externo | PostgreSQL, Event Hubs |
| Orders | `shopdemo-orders` | 8080 | Externo | PostgreSQL, Inventory URL, Event Hubs |
| Inventory | `shopdemo-inventory` | 8080 | Interno (+ opcional externo) | PostgreSQL, Azurite, Event Hubs |
| Analytics | `shopdemo-analytics` | 8080 | Externo | Azurite, Event Hubs |

---

## 8. Criterios de aceptación

| # | Criterio |
|---|---|
| CA-AZ-01 | `az containerapp list` muestra las 4 aplicaciones en estado Running |
| CA-AZ-02 | Swagger o health responde en la URL pública de Catalog |
| CA-AZ-03 | Flujo crear producto → analytics/events lista el evento (con Event Hubs on) |
| CA-AZ-04 | Confirmar pedido en Orders no falla por URL de Inventory |
| CA-AZ-05 | Alumno completó al menos un paso por Portal y el equivalente por CLI |

---

## 9. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Costos inesperados | Resource Group dedicado; `minReplicas: 0`; teardown documentado |
| PostgreSQL efímero en ACI | Aviso en guía: datos se pierden al recrear contenedor |
| Connection string expuesta | Usar secrets de Container Apps |
| Imagen no arranca | Revisar logs en Log Analytics; verificar `ASPNETCORE_URLS` y puerto 8080 |

---

## 10. Referencias

- [TEORIA-CONTENEDORES-AZURE.md](./TEORIA-CONTENEDORES-AZURE.md)
- [IMPLEMENTACION-DESPLIEGUE-AZURE.md](./IMPLEMENTACION-DESPLIEGUE-AZURE.md)
- [ARQUITECTURA.md](../../ARQUITECTURA.md)
