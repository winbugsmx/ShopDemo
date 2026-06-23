# Implementación — Resiliencia en Azure (ACA + AKS)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Prerequisitos:** APIs desplegadas. **Teoría:** [TEORIA-RESILIENCIA.md](../TEORIA-RESILIENCIA.md)

---

## Índice

### Parte A — Container Apps
1. [Health probes HTTP](#parte-a--container-apps)
2. [Réplicas mínimas y máximas](#paso-a2--réplicas)
3. [Prueba de recuperación](#paso-a3--prueba-de-recuperación)
4. [Resiliencia asíncrona Event Hubs](#paso-a4--event-hubs)

### Parte B — AKS
5. [Probes en manifiestos](#parte-b--aks)
6. [HPA Catalog](#paso-b2--hpa)
7. [Simulación de fallo de pod](#paso-b3--simulación-de-fallo)
8. [Rolling update sin downtime total](#paso-b4--rolling-update)

---

## Parte A — Container Apps

### Paso A1 — Health probes HTTP

**Objetivo:** ACA no envía tráfico a revisiones que no respondan `/health`.

| # | Portal | Valor |
|---|---|---|
| 1 | Container App → **Containers** → **Health probes** | |
| 2 | **Liveness probe** | HTTP GET `/alive` puerto `8080` |
| 3 | **Readiness probe** | HTTP GET `/health` puerto `8080` |
| 4 | Initial delay: `15` s, Period: `10` s | |

#### CLI (ejemplo Catalog)

```bash
az containerapp update \
  --name ca-shopdemo-catalog \
  --resource-group $RG \
  --probe-type Liveness \
  --probe-http-path /alive \
  --probe-port 8080
```

**Explicación:** Los endpoints ya existen en el código (`Program.cs` / `ServiceDefaults`). La plataforma reinicia o retira instancias enfermas.

Repetir para **Orders, Inventory, Analytics**.

---

### Paso A2 — Réplicas

**Objetivo:** Redundancia básica ante fallo de una instancia.

| # | Portal |
|---|---|
| 1 | Container App → **Scale** |
| 2 | Min replicas: `1`, Max replicas: `3` (lab) |
| 3 | HTTP scale rule (opcional): concurrent requests > 50 → escalar |

```bash
az containerapp update -n ca-shopdemo-catalog -g $RG --min-replicas 1 --max-replicas 3
```

**Orders → Inventory:** mantener Inventory con min replicas ≥ 1 para reducir fallos síncronos.

---

### Paso A3 — Prueba de recuperación

| # | Paso |
|---|---|
| 1 | `az containerapp replica list -n ca-shopdemo-orders -g $RG` |
| 2 | Portal → **Revisions** → **Restart** una réplica o escalar a 2 y detener una |
| 3 | Verificar: `curl https://<fqdn-orders>/health` → 200 |
| 4 | Postman: confirmar pedido sigue funcionando |

**Resultado esperado:** ACA levanta nueva réplica; el usuario percibe solo latencia breve.

---

### Paso A4 — Event Hubs

**Objetivo:** Resiliencia **asíncrona** — Catalog publica aunque Inventory esté lento.

| # | Verificación |
|---|---|
| 1 | Detener Container App Inventory temporalmente |
| 2 | Crear producto en Catalog → evento en Event Hubs |
| 3 | Levantar Inventory → consumer procesa backlog |

**Explicación:** El patrón de mensajería absorbe desconexión temporal; el flujo **síncrono** Orders→Inventory sigue requiriendo Inventory activo.

---

## Parte B — AKS

### Paso B1 — Probes

**Objetivo:** Usar manifiestos `k8s/*/deployment.yaml` ya configurados.

```bash
kubectl apply -f k8s/catalog/
kubectl describe pod -n shopdemo -l app=shopdemo-catalog | findstr -i "Liveness Readiness"
```

Debe mostrar `http-get /health` y `http-get /alive` en **Success**.

---

### Paso B2 — HPA

```bash
kubectl apply -f k8s/catalog/hpa.yaml
kubectl get hpa -n shopdemo
```

| Campo | Valor |
|---|---|
| minReplicas | 1 |
| maxReplicas | 3 |
| CPU target | 70 % |

**Explicación:** Ante pico de creación de productos, Catalog escala horizontalmente.

---

### Paso B3 — Simulación de fallo

```bash
kubectl get pods -n shopdemo -l app=shopdemo-inventory
kubectl delete pod -n shopdemo <nombre-pod-inventory>
kubectl get pods -n shopdemo -w
```

| # | Validar |
|---|---|
| 1 | Nuevo pod Inventory en `Running` |
| 2 | `curl http://<ingress>/inventory/health` |
| 3 | Confirmar pedido en Postman |

**Causalidad:** Durante el vacío de pod, Orders puede fallar al confirmar — observable en logs (ver [observabilidad](../observabilidad/azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md)).

---

### Paso B4 — Rolling update

```bash
# Tras nuevo push de imagen a ACR
kubectl set image deployment/shopdemo-catalog catalog-api=$ACR_LOGIN/shopdemo-catalog:v2 -n shopdemo
kubectl rollout status deployment/shopdemo-catalog -n shopdemo
```

**Explicación:** Kubernetes crea pods nuevos antes de terminar los viejos (maxUnavailable controlado) — continuidad parcial del servicio.

---

## Checklist

| # | Criterio | ACA | AKS |
|---|---|---|---|
| 1 | Health probes configurados | ✓ | ✓ |
| 2 | ≥ 1 réplica por API crítica | ✓ | ✓ |
| 3 | Recuperación tras fallo probada | ✓ | ✓ |
| 4 | HPA o scale rule activo | scale rule | HPA Catalog |
| 5 | Event Hubs demostrado | ✓ | ✓ |

---

## Referencias

- [IMPLEMENTACION-DESPLIEGUE-AZURE.md](../../despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md)
- [IMPLEMENTACION-DESPLIEGUE-AKS.md](../../despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md)
- [k8s/catalog/hpa.yaml](../../../k8s/catalog/hpa.yaml)
