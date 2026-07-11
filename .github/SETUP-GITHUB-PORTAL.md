# Configuración GitHub — Portal web (ShopDemo)

**Curso:** Arquitectura Clean + DDD — Lite Thinking  
**Audiencia:** Alumnos que prefieren configurar CI/CD desde el **portal de GitHub** (navegador), sin usar la terminal.

Esta guía complementa:

| Documento | Cuándo usarlo |
|---|---|
| [SETUP-GITHUB.md](SETUP-GITHUB.md) | Resumen del flujo completo (infra + CI/CD) |
| [GH-CLI-COMMANDS.md](GH-CLI-COMMANDS.md) | Mismos pasos con **GitHub CLI** (`gh`) |
| [SECRETS-CHECKLIST.md](SECRETS-CHECKLIST.md) | Tablas de referencia de todos los secrets |

---

## Índice

1. [Prerrequisitos](#1-prerrequisitos)
2. [Permisos en el repositorio](#2-permisos-en-el-repositorio)
3. [Crear environments](#3-crear-environments)
4. [Secrets a nivel repositorio](#4-secrets-a-nivel-repositorio)
5. [Secrets por environment](#5-secrets-por-environment)
6. [De dónde sacar cada valor](#6-de-dónde-sacar-cada-valor)
7. [Ejecutar workflows manualmente](#7-ejecutar-workflows-manualmente)
8. [Verificar que todo funciona](#8-verificar-que-todo-funciona)
9. [Problemas frecuentes](#9-problemas-frecuentes)
10. [Checklist del alumno](#10-checklist-del-alumno)

---

## 1. Prerrequisitos

Antes de tocar GitHub, completa **en tu máquina**:

1. Fork o clon del repo `ShopDemo` en tu cuenta de GitHub.
2. Infraestructura cloud provisionada con los scripts PowerShell del curso:
   - Azure: `Source/scripts/azure/Deploy-AzureShopDemo.ps1`
   - AWS: `Source/scripts/aws/Deploy-AwsShopDemo.ps1`
3. Archivos locales con valores de lab (no se suben al repo):
   - `Source/scripts/azure/.env.azure`
   - `Source/scripts/aws/.env.aws`
4. Rama **`main`** como rama por defecto (los workflows escuchan `main`, no `master`).

> Los workflows **no crean** VPC, clusters ni Container Apps. Solo construyen imágenes y actualizan despliegues existentes.

---

## 2. Permisos en el repositorio

Necesitas rol **Admin** o **Maintain** en el repositorio para:

- Crear **Environments**
- Crear **Secrets** de Actions
- Aprobar despliegues si activas revisores en un environment

**Ruta en el portal:**

```
https://github.com/<TU-USUARIO>/ShopDemo
  → pestaña Settings (⚙️)
```

Si no ves **Settings**, pide acceso al dueño del repo o usa tu fork personal.

---

## 3. Crear environments

Los cuatro workflows usan **environments** distintos. Cada uno agrupa secrets y (opcionalmente) reglas de aprobación.

| Nombre exacto | Workflow | Plataforma |
|---|---|---|
| `azure` | deploy-azure.yml | Azure Container Apps |
| `azure-aks` | deploy-aks.yml | Azure AKS |
| `aws` | deploy-aws.yml | AWS ECS |
| `aws-eks` | deploy-eks.yml | Amazon EKS |

### Pasos en el portal

1. Abre el repositorio en GitHub.
2. **Settings** → menú lateral **Environments**.
3. Clic en **New environment**.
4. Escribe el nombre **exactamente** como en la tabla (minúsculas, con guion: `azure-aks`, `aws-eks`).
5. Clic en **Configure environment**.
6. Repite para los cuatro nombres.

### Protección opcional (laboratorio)

En la pantalla de cada environment puedes configurar:

| Opción | Recomendación lab |
|---|---|
| **Required reviewers** | Desactivado (más ágil para practicar) |
| **Wait timer** | 0 minutos |
| **Deployment branches** | Solo `main` (opcional, refuerza el flujo del curso) |

7. Clic en **Save protection rules** (o dejar vacío y guardar).

> Si ya existe un environment llamado `Prod`, **no lo borres** por costumbre; los workflows actuales **no** lo usan. Crea los cuatro de la tabla.

---

## 4. Secrets a nivel repositorio

Algunos valores pueden definirse **una sola vez** para todo el repo. Los workflows también pueden leer secrets del environment; en el lab conviene repetir `EVENT_HUBS_*` en cada environment que despliegues.

### Pasos en el portal

1. **Settings** → **Secrets and variables** → **Actions**.
2. Pestaña **Secrets**.
3. Sección **Repository secrets** → **New repository secret**.

| Nombre del secret | Valor (origen) |
|---|---|
| `EVENT_HUBS_CONNECTION_STRING` | Azure Portal → Event Hubs namespace → Shared access policies → connection string |
| `EVENT_HUB_NAME` | `shopdemo-events` (o el nombre de tu hub) |

4. **Name:** escribe el nombre **exacto** (sensible a mayúsculas).
5. **Secret:** pega el valor.
6. **Add secret**.

> Tras guardar, GitHub **no muestra** el valor otra vez. Si te equivocas, edita el secret y pégalo de nuevo.

---

## 5. Secrets por environment

Los secrets de **environment** solo los ven los jobs que declaran `environment: azure` (etc.) en el workflow.

### Pasos comunes (repetir por cada secret)

1. **Settings** → **Environments**.
2. Clic en el environment (ej. `azure`).
3. Sección **Environment secrets** → **Add secret**.
4. **Name** + **Value** → **Add secret**.

### 5.1 Environment `azure` (Container Apps)

| Secret | Obligatorio | Ejemplo / notas |
|---|---|---|
| `AZURE_CREDENTIALS` | Sí | JSON completo del Service Principal (`az ad sp create-for-rbac --sdk-auth`) |
| `ACR_NAME` | Sí | `acrshopdemolab01` |
| `AZURE_RG` | Sí | `rg-shopdemo-lab` |
| `ACA_ENV` | Sí | `aca-env-shopdemo` |
| `EVENT_HUBS_CONNECTION_STRING` | Sí | Mismo que en repositorio |
| `EVENT_HUB_NAME` | Sí | `shopdemo-events` |
| `PG_CATALOG_CONN` | Sí | Connection string PostgreSQL Catalog |
| `PG_ORDERS_CONN` | Sí | Connection string PostgreSQL Orders |
| `PG_INVENTORY_CONN` | Sí | Connection string PostgreSQL Inventory |
| `STORAGE_CHECKPOINT_CONN` | Sí | Azure Blob Storage (checkpoints ACA) |
| `INVENTORY_API_BASE_URL` | Sí | URL HTTPS de Inventory (Orders la consume) |
| `MCP_CATALOG_URL` | Sí | URL HTTPS del Container App catalog |
| `MCP_INVENTORY_URL` | Sí | URL HTTPS del Container App inventory |
| `MCP_ANALYTICS_URL` | Sí | URL HTTPS del Container App analytics |

### 5.2 Environment `azure-aks` (AKS)

| Secret | Obligatorio | Ejemplo / notas |
|---|---|---|
| `AZURE_CREDENTIALS` | Sí | Mismo JSON que en `azure` |
| `ACR_NAME` | Sí | `acrshopdemolab01` |
| `AZURE_RG` | Sí | `rg-shopdemo-lab` |
| `AKS_CLUSTER_NAME` | Sí | `aks-shopdemo` |
| `K8S_NAMESPACE` | Opcional | `shopdemo` |
| `EVENT_HUBS_CONNECTION_STRING` | Sí | Event Hubs |
| `PG_CATALOG_CONN` | Sí* | In-cluster — ver `k8s/secrets.example.yaml` |
| `PG_ORDERS_CONN` | Sí* | Idem |
| `PG_INVENTORY_CONN` | Sí* | Idem |
| `AZURITE_CHECKPOINT_CONN` | Sí* | Azurite dentro del cluster |
| `POSTGRES_USER` | Opcional | `ShopDemo` |
| `POSTGRES_PASSWORD` | Opcional | Contraseña postgres del lab |

\* Usados cuando ejecutas el workflow con **sync_secrets** activado.

### 5.3 Environment `aws` (ECS)

| Secret | Obligatorio | Ejemplo / notas |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | Sí* | IAM user del lab |
| `AWS_SECRET_ACCESS_KEY` | Sí* | Par de la access key |
| `AWS_ROLE_ARN` | Alternativa | OIDC — ver doc AWS del curso |
| `AWS_REGION` | Sí | `us-east-2` |
| `ECS_CLUSTER` | Sí | `shopdemo-cluster` |
| `LAB_PREFIX` | Opcional | `shopdemo` |
| `EVENT_HUBS_CONNECTION_STRING` | Sí | Azure Event Hubs (cross-cloud) |
| `EVENT_HUB_NAME` | Sí | `shopdemo-events` |
| `PG_CATALOG_CONN` | Sí | Connection string → SSM |
| `PG_ORDERS_CONN` | Sí | Idem |
| `PG_INVENTORY_CONN` | Sí | Idem |
| `AZURITE_CHECKPOINT_CONN` | Sí | Azurite en ECS |
| `INVENTORY_API_BASE_URL` | Sí | DNS interno / Cloud Map |
| `MCP_CATALOG_URL` | Sí | URL ALB catalog |
| `MCP_INVENTORY_URL` | Sí | URL ALB inventory |
| `MCP_ANALYTICS_URL` | Sí | URL ALB analytics |

\* Si usas `AWS_ROLE_ARN` (OIDC), puedes omitir access key en entornos bien configurados.

### 5.4 Environment `aws-eks` (EKS)

| Secret | Obligatorio | Ejemplo / notas |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | Sí* | Mismos que `aws` |
| `AWS_SECRET_ACCESS_KEY` | Sí* | Mismos que `aws` |
| `AWS_ROLE_ARN` | Recomendado | OIDC |
| `AWS_REGION` | Sí | `us-east-2` |
| `EKS_CLUSTER_NAME` | Sí | `shopdemo-eks` |
| `K8S_NAMESPACE` | Opcional | `shopdemo` |
| `EVENT_HUBS_CONNECTION_STRING` | Sí | Event Hubs |
| `PG_CATALOG_CONN` | Sí* | In-cluster |
| `PG_ORDERS_CONN` | Sí* | In-cluster |
| `PG_INVENTORY_CONN` | Sí* | In-cluster |
| `AZURITE_CHECKPOINT_CONN` | Sí* | Azurite in-cluster |
| `POSTGRES_USER` | Opcional | Lab |
| `POSTGRES_PASSWORD` | Opcional | Lab |

### Atajo: copiar secrets entre environments

GitHub **no** permite duplicar un secret con un clic. Debes:

1. Tener el valor guardado en tu `.env.azure` / `.env.aws` o en tus notas locales.
2. Entrar al environment destino → **Add secret** → mismo nombre y valor.

Para muchos secrets repetidos, la alternativa rápida es el script [sync-github-environments.ps1](scripts/sync-github-environments.ps1) o [GH-CLI-COMMANDS.md](GH-CLI-COMMANDS.md).

---

## 6. De dónde sacar cada valor

| Tipo de secret | Dónde obtenerlo |
|---|---|
| Infra Azure (ACR, RG, ACA, AKS) | `Source/scripts/azure/.env.azure` o reportes `Source/scripts/azure/deploy-*-report.json` |
| Infra AWS (región, cluster ECS/EKS) | `Source/scripts/aws/.env.aws` o `Source/scripts/aws/deploy-eks-report.json` |
| Event Hubs | Azure Portal → namespace → Shared access policies |
| PostgreSQL ACA/ECS | Salida del script de deploy o consola cloud |
| PostgreSQL / Azurite K8s | Plantilla [k8s/secrets.example.yaml](../k8s/secrets.example.yaml) |
| URLs MCP / Inventory (ACA) | Portal Azure → Container Apps → **Application Url** (FQDN) |
| URLs MCP (ECS) | Consola AWS → EC2 → Load Balancers → DNS name |
| Service Principal | [SETUP-GITHUB.md §6](SETUP-GITHUB.md#6-service-principal-azure-resumen) |
| OIDC AWS | [PREPARACION-AMBIENTE-AWS.md](../Documentación del Proyecto/despliegue/aws/PREPARACION-AMBIENTE-AWS.md) |

Documentación MCP:

- Azure: [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](../Documentación del Proyecto/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md)
- AWS: [IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md](../Documentación del Proyecto/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md)

---

## 7. Ejecutar workflows manualmente

Útil la **primera vez** (K8s) o para probar sin hacer merge.

### Pasos

1. Pestaña **Actions** del repositorio.
2. Barra lateral: elige el workflow (ej. **Deploy AKS**).
3. Clic en **Run workflow** (dropdown arriba a la derecha).
4. **Branch:** `main`.
5. Para **Deploy AKS** / **Deploy EKS**, marca según necesidad:

| Input | Cuándo marcarlo |
|---|---|
| `sync_secrets` | Primera vez o rotación de connection strings |
| `apply_manifests` | Primera vez o cambio en `k8s/**` |
| `apply_infra` | Postgres/Azurite aún no existen en el cluster |

6. **Run workflow**.

### Tras merge a `main`

No hace falta intervención manual: al integrar un PR en `main`, GitHub dispara los workflows cuyos **path filters** coincidan. Revisa la pestaña **Actions** para ver ejecuciones en curso.

### Aprobar un deployment (si activaste revisores)

1. **Actions** → run en espera.
2. O **Settings** → **Environments** → environment → **View deployments**.
3. **Review deployments** → **Approve and deploy**.

---

## 8. Verificar que todo funciona

### En GitHub

| Qué revisar | Dónde |
|---|---|
| Environments creados | Settings → Environments (4 nombres) |
| Secrets cargados | Settings → Environments → cada uno → Environment secrets |
| Workflow exitoso | Actions → run verde ✓ |
| Imagen desplegada | Log del job → paso `kubectl set image` o `az containerapp update` |

### En la nube (salud de APIs)

| Plataforma | Prueba |
|---|---|
| ACA | `https://<fqdn-catalog>/health` |
| ECS | `http://<alb-catalog>/health` |
| AKS/EKS Ingress | `http://shopdemo.local/catalog/health` (entrada en `hosts`) |

Detalle: [SECRETS-CHECKLIST.md §5](SECRETS-CHECKLIST.md#5-verificación-post-deploy).

---

## 9. Problemas frecuentes

| Síntoma | Causa probable | Solución en portal |
|---|---|---|
| Workflow no aparece | Push solo en docs o rama distinta de `main` | Merge a `main` o Run workflow manual |
| `Environment azure-aks not found` | Falta crear el environment | §3 — nombre exacto |
| `Secret AZURE_CREDENTIALS not found` | Secret en repo pero job usa environment | Crear el secret **dentro** del environment |
| Job falla en login Azure/AWS | JSON SP incorrecto o keys AWS | Editar secret en el environment |
| AKS/EKS: pods sin env | No corrió `sync_secrets` | Actions → Run workflow con `sync_secrets: true` |
| MCP no responde | URLs incorrectas en `MCP_*` | Actualizar secrets en `azure` o `aws` |
| No puedo editar Settings | Permisos insuficientes | Fork propio o rol Admin |

---

## 10. Checklist del alumno

Marca cuando completes cada bloque en el **portal**:

```
[ ] Infra provisionada (scripts PowerShell locales)
[ ] Settings → Environments: azure, azure-aks, aws, aws-eks
[ ] Repository secrets: EVENT_HUBS_CONNECTION_STRING, EVENT_HUB_NAME
[ ] Environment azure: secrets ACA (tabla §5.1)
[ ] Environment azure-aks: secrets AKS (tabla §5.2)
[ ] Environment aws: secrets ECS (tabla §5.3)
[ ] Environment aws-eks: secrets EKS (tabla §5.4)
[ ] Primer run manual AKS/EKS: sync_secrets + apply_manifests
[ ] Merge a main → Actions en verde
[ ] /health OK en la plataforma elegida
```

---

## Referencias cruzadas

| Recurso | Enlace |
|---|---|
| Resumen CI/CD | [SETUP-GITHUB.md](SETUP-GITHUB.md) |
| GitHub CLI (alternativa) | [GH-CLI-COMMANDS.md](GH-CLI-COMMANDS.md) |
| Checklist secrets | [SECRETS-CHECKLIST.md](SECRETS-CHECKLIST.md) |
| Índice workflows | [README.md](README.md) |
| Alcance lab release | [ALCANCE-LAB-RELEASE.md](../Documentación del Proyecto/despliegue/ALCANCE-LAB-RELEASE.md) |
