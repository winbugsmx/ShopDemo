# Implementación — Despliegue MCP Gateway en Azure (ACA + AKS)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Componente:** `AI/ShopDemo.Mcp.Api` · **Requerimientos:** [REQUERIMIENTOS-DESPLIEGUE-MCP.md](./REQUERIMIENTOS-DESPLIEGUE-MCP.md)  
**Prerequisito:** Catalog, Orders, Inventory y Analytics desplegados ([IMPLEMENTACION-DESPLIEGUE-AZURE.md](../despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md) o AKS).

> Cada paso incluye **Portal Azure** y **Azure CLI**.

---

## Índice

### Parte A — Azure Container Apps
1. [Variables](#1-variables)
2. [Paso A1 — Build y push imagen MCP](#paso-a1--build-y-push-imagen-mcp)
3. [Paso A2 — Obtener URLs de las APIs](#paso-a2--obtener-urls-de-las-apis)
4. [Paso A3 — Crear Container App MCP](#paso-a3--crear-container-app-mcp)
5. [Paso A4 — Health probes](#paso-a4--health-probes)
6. [Paso A5 — Probar MCP en ACA](#paso-a5--probar-mcp-en-aca)

### Parte B — Azure Kubernetes Service (AKS)
7. [Paso B1 — Build imagen en ACR](#paso-b1--build-imagen-en-acr)
8. [Paso B2 — Aplicar manifiestos k8s/mcp](#paso-b2--aplicar-manifiestos-k8smcp)
9. [Paso B3 — Actualizar Ingress](#paso-b3--actualizar-ingress)
10. [Paso B4 — Probar MCP en AKS](#paso-b4--probar-mcp-en-aks)

### Común
11. [Paso C1 — CI/CD GitHub Actions](#paso-c1--cicd-github-actions)
12. [Solución de problemas](#solución-de-problemas)

---

## 1. Variables

```bash
$RG = "rg-shopdemo-lab"
$ACR_NAME = "acrshopdemolab01"
$ACA_ENV = "aca-env-shopdemo"
$AKS_NAME = "aks-shopdemo"   # si usas Parte B
```

---

## Paso A1 — Build y push imagen MCP

**Objetivo:** Publicar `shopdemo-mcp` en ACR (mismo registro que las otras APIs).

### Enfoque A — Portal (Cloud Shell)

1. Abrir **Azure Cloud Shell** (bash) en el Portal
2. Clonar repo o subir código
3. Ejecutar comandos CLI del Enfoque B

### Enfoque B — Azure CLI (local)

```bash
cd I:\Curso\ShopDemo
az acr login --name $ACR_NAME
$ACR_LOGIN = az acr show --name $ACR_NAME --query loginServer -o tsv

docker build -f AI/ShopDemo.Mcp.Api/Dockerfile -t $ACR_LOGIN/shopdemo-mcp:v1 .
docker push $ACR_LOGIN/shopdemo-mcp:v1
```

**Explicación:** El Dockerfile usa contexto raíz del repo; no requiere proyectos Catalog/Orders.

**Verificación:**

```bash
az acr repository list --name $ACR_NAME -o table
az acr repository show-tags --name $ACR_NAME --repository shopdemo-mcp
```

---

## Paso A2 — Obtener URLs de las APIs

**Objetivo:** Configurar `ShopDemo__*ApiBaseUrl` para que MCP llame a las APIs ya desplegadas.

### Portal

1. **Container Apps** → `ca-shopdemo-catalog` → **Application Url** → copiar FQDN
2. Repetir para `ca-shopdemo-inventory` y `ca-shopdemo-analytics`

### CLI

```bash
$CATALOG_URL = az containerapp show -n ca-shopdemo-catalog -g $RG --query properties.configuration.ingress.fqdn -o tsv
$INVENTORY_URL = az containerapp show -n ca-shopdemo-inventory -g $RG --query properties.configuration.ingress.fqdn -o tsv
$ANALYTICS_URL = az containerapp show -n ca-shopdemo-analytics -g $RG --query properties.configuration.ingress.fqdn -o tsv

echo "https://$CATALOG_URL"
echo "https://$INVENTORY_URL"
echo "https://$ANALYTICS_URL"
```

**Nota:** Usar `https://` en ACA. Orders no es requerido por las tools MCP actuales.

---

## Paso A3 — Crear Container App MCP

**Objetivo:** Quinta Container App con Ingress externo en puerto 8080.

### Enfoque A — Portal Azure

1. **Container Apps** → **Create**
2. **Basics:** nombre `ca-shopdemo-mcp`, mismo RG y **Container Apps Environment** que las otras APIs
3. **Container:**
   - Image: `acrshopdemolab01.azurecr.io/shopdemo-mcp:v1`
   - CPU 0.5, Memory 1 Gi
   - **Environment variables:**

| Nombre | Valor |
|---|---|
| `ASPNETCORE_ENVIRONMENT` | `Production` |
| `ShopDemo__CatalogApiBaseUrl` | `https://<fqdn-catalog>` |
| `ShopDemo__InventoryApiBaseUrl` | `https://<fqdn-inventory>` |
| `ShopDemo__AnalyticsApiBaseUrl` | `https://<fqdn-analytics>` |

4. **Ingress:** Enabled, **External**, Target port **8080**
5. **Scale:** Min 1, Max 2
6. **Create**

### Enfoque B — Azure CLI

```bash
$ACR_LOGIN = az acr show --name $ACR_NAME --query loginServer -o tsv
$ACR_PASS = az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv

az containerapp create \
  --name ca-shopdemo-mcp \
  --resource-group $RG \
  --environment $ACA_ENV \
  --image "$ACR_LOGIN/shopdemo-mcp:v1" \
  --registry-server $ACR_LOGIN \
  --registry-username $ACR_NAME \
  --registry-password $ACR_PASS \
  --target-port 8080 \
  --ingress external \
  --min-replicas 1 --max-replicas 2 \
  --cpu 0.5 --memory 1.0Gi \
  --env-vars \
    ASPNETCORE_ENVIRONMENT=Production \
    ShopDemo__CatalogApiBaseUrl="https://$CATALOG_URL" \
    ShopDemo__InventoryApiBaseUrl="https://$INVENTORY_URL" \
    ShopDemo__AnalyticsApiBaseUrl="https://$ANALYTICS_URL"
```

---

## Paso A4 — Health probes

**Objetivo:** ACA reinicia o retira réplicas que no respondan.

### Portal

1. `ca-shopdemo-mcp` → **Containers** → **Edit and deploy**
2. **Health probes:**
   - **Liveness:** HTTP GET, path `/health`, port `8080`, initial delay `20` s
   - **Readiness:** HTTP GET, path `/health`, port `8080`, initial delay `10` s
3. **Create revision**

### CLI

```bash
az containerapp update \
  --name ca-shopdemo-mcp \
  --resource-group $RG \
  --probe-type Liveness \
  --probe-http-path /health \
  --probe-port 8080 \
  --probe-initial-delay 20

az containerapp update \
  --name ca-shopdemo-mcp \
  --resource-group $RG \
  --probe-type Readiness \
  --probe-http-path /health \
  --probe-port 8080 \
  --probe-initial-delay 10
```

---

## Paso A5 — Probar MCP en ACA

```bash
$MCP_FQDN = az containerapp show -n ca-shopdemo-mcp -g $RG --query properties.configuration.ingress.fqdn -o tsv
curl "https://$MCP_FQDN/health"
```

| # | Prueba | Esperado |
|---|---|---|
| 1 | Health | HTTP 200 |
| 2 | Agente MCP | URL `https://<fqdn>/mcp` |
| 3 | Tool `GetShopDemoStatus` | JSON con Catalog/Inventory/Analytics OK |

Configuración Cursor (ejemplo):

```json
{
  "mcpServers": {
    "shopdemo-azure": {
      "url": "https://<MCP_FQDN>/mcp"
    }
  }
}
```

---

## Paso B1 — Build imagen en ACR

Igual que [Paso A1](#paso-a1--build-y-push-imagen-mcp). En AKS la imagen debe estar en ACR con tag versionado (`v1` o `latest`).

---

## Paso B2 — Aplicar manifiestos k8s/mcp

**Objetivo:** Deployment + Service en namespace `shopdemo`.

### Manifiestos en repo

| Archivo | Contenido |
|---|---|
| `k8s/azure/mcp/deployment.yaml` (AKS) o `k8s/aws/mcp/deployment.yaml` (EKS) | Imagen registry, env DNS interno, probes |
| `k8s/mcp/service.yaml` | ClusterIP puerto 8080 |

**DNS interno (ya en manifiesto):**

| Variable | Valor en cluster |
|---|---|
| `ShopDemo__CatalogApiBaseUrl` | `http://shopdemo-catalog:8080` |
| `ShopDemo__InventoryApiBaseUrl` | `http://shopdemo-inventory:8080` |
| `ShopDemo__AnalyticsApiBaseUrl` | `http://shopdemo-analytics:8080` |

### CLI — aplicar MCP en AKS

```bash
az aks get-credentials --resource-group $RG --name $AKS_NAME

# Deployment ACR (k8s/azure/mcp/deployment.yaml)
kubectl apply -f k8s/azure/mcp/deployment.yaml
kubectl apply -f k8s/mcp/service.yaml
```

Si el tag push no es `latest`, ajusta la línea `image:` en `k8s/azure/mcp/deployment.yaml` o usa `kubectl set image`.

**Explicación:** Las APIs deben estar Running antes; MCP las resuelve por Service DNS.

---

## Paso B3 — Actualizar Ingress

**Objetivo:** Exponer MCP en `http://<ingress>/mcp`.

El archivo `k8s/ingress/ingress.yaml` ya incluye:

```yaml
- path: /mcp(/|$)(.*)
  backend:
    service:
      name: shopdemo-mcp
      port:
        number: 8080
```

```bash
kubectl apply -f k8s/ingress/
kubectl get ingress -n shopdemo
```

---

## Paso B4 — Probar MCP en AKS

```bash
$INGRESS_IP = kubectl get ingress shopdemo-ingress -n shopdemo -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
curl "http://$INGRESS_IP/mcp/health"
```

> La ruta de health vía Ingress puede ser `http://<ip>/mcp/health` según rewrite NGINX.

| Prueba | Comando |
|---|---|
| Pod Running | `kubectl get pods -n shopdemo -l app=shopdemo-mcp` |
| Logs | `kubectl logs -n shopdemo -l app=shopdemo-mcp --tail=50` |
| Agente | `http://shopdemo.local/mcp` (con hosts configurado) |

---

## Paso C1 — CI/CD GitHub Actions

| Workflow | MCP en |
|---|---|
| [deploy-azure.yml](../../.github/workflows/deploy-azure.yml) | Container App `ca-shopdemo-mcp` |
| [deploy-aks.yml](../../.github/workflows/deploy-aks.yml) | Deployment `shopdemo-mcp` + Ingress `/mcp` |

Configuración GitHub: [SETUP-GITHUB.md](../../.github/SETUP-GITHUB.md) · Secrets: [SECRETS-CHECKLIST.md](../../.github/SECRETS-CHECKLIST.md)

Fragmento ACA (`deploy-azure.yml`):

```yaml
- service: mcp
  dockerfile: AI/ShopDemo.Mcp.Api/Dockerfile
  image: shopdemo-mcp
  containerapp: ca-shopdemo-mcp
```

### Crear Container App MCP antes del primer CI run

El workflow **actualiza** `ca-shopdemo-mcp`; debe existir previamente (Pasos A3–A4 o script `-Mode ACA`).

---

## Solución de problemas

| Síntoma | Causa | Acción |
|---|---|---|
| Tool devuelve error HTTP | URL API incorrecta | Revisar env vars `ShopDemo__*` |
| `ImagePullBackOff` AKS | Imagen no en ACR o sin attach | `az aks update --attach-acr` |
| Health probe failed | App no arrancó | `kubectl logs` / Log stream ACA |
| 404 en `/mcp` Ingress | Ingress no aplicado | `kubectl apply -f k8s/ingress/` |
| TLS error ACA→ACA | Certificado interno | Usar FQDN https públicos en env vars |

---

## Checklist

| # | Criterio | ACA | AKS |
|---|---|---|---|
| 1 | Imagen en ACR | ✓ | ✓ |
| 2 | `/health` 200 | ✓ | ✓ |
| 3 | Agente conecta a `/mcp` | ✓ | ✓ |
| 4 | `GetShopDemoStatus` OK | ✓ | ✓ |
| 5 | CI/CD incluye mcp | ✓ | ✓ ([deploy-aks.yml](../../.github/workflows/deploy-aks.yml)) |

---

## Referencias

- [k8s/mcp/](../../k8s/mcp/)
- [AI/ShopDemo.Mcp.Api](../../AI/ShopDemo.Mcp.Api/)
- [IMPLEMENTACION-INTEGRACION-IA-AZURE.md](./azure/IMPLEMENTACION-INTEGRACION-IA-AZURE.md)
