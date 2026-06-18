# Implementación — Resiliencia en AWS (ECS + EKS)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Prerequisitos:** ShopDemo en ECS y/o EKS. **Teoría:** [TEORIA-RESILIENCIA.md](../TEORIA-RESILIENCIA.md)

---

## Índice

### Parte A — ECS Fargate
1. [Health checks ALB + container](#parte-a--ecs-fargate)
2. [Desired count y redundancia](#paso-a2--desired-count)
3. [Deployment circuit breaker](#paso-a3--deployment-circuit-breaker)
4. [Recuperación de tarea](#paso-a4--recuperación)
5. [Event Hubs cross-cloud](#paso-a5--event-hubs)

### Parte B — EKS
6. [Probes K8s](#parte-b--eks)
7. [HPA Catalog](#paso-b2--hpa)
8. [Eliminar pod y observar recuperación](#paso-b3--fallo-de-pod)
9. [Comunicación Orders→Inventory](#paso-b4--comunicación-síncrona)

---

## Parte A — ECS Fargate

### Paso A1 — Health checks

**Objetivo:** ALB solo enruta a tareas sanas.

| # | Consola |
|---|---|
| 1 | **EC2** → **Target Groups** → `tg-shopdemo-orders` |
| 2 | Health check path: `/health` |
| 3 | Healthy threshold: 2, Interval: 30 s |
| 4 | Matcher: HTTP `200` |

En **task definition** (container health check opcional):

```json
"healthCheck": {
  "command": ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"],
  "interval": 30,
  "timeout": 5,
  "retries": 3
}
```

**Explicación:** Doble capa — ALB (externo) y ECS (interno) usan `/health` del código ShopDemo.

---

### Paso A2 — Desired count

| # | Consola / CLI |
|---|---|
| 1 | ECS service → **Desired tasks**: `2` (lab con redundancia) |
| 2 | `aws ecs update-service --cluster shopdemo-cluster --service shopdemo-inventory --desired-count 2` |

**Inventory** es crítico para Orders síncrono — mínimo 2 tareas reduce impacto de un fallo.

---

### Paso A3 — Deployment circuit breaker

| # | Consola |
|---|---|
| 1 | ECS service → **Deployment configuration** |
| 2 | Enable **Deployment circuit breaker** + rollback |
| 3 | Si nueva task definition falla health check → rollback automático |

**Explicación:** Resiliencia del **despliegue**, no solo del runtime.

---

### Paso A4 — Recuperación

```bash
# Listar tareas
aws ecs list-tasks --cluster shopdemo-cluster --service-name shopdemo-orders

# Detener una tarea (ECS lanza otra)
aws ecs stop-task --cluster shopdemo-cluster --task <TASK_ARN>
```

| # | Validar |
|---|---|
| 1 | Nueva tarea en `RUNNING` |
| 2 | ALB target `healthy` |
| 3 | Postman: crear pedido OK |

---

### Paso A5 — Event Hubs

Mismo escenario que Azure: Inventory detenido → crear producto → evento en Azure EH → al levantar Inventory, consumer procesa.

**Requisito de red:** tareas ECS con salida HTTPS a `*.servicebus.windows.net`.

---

## Parte B — EKS

### Paso B1 — Probes

```bash
kubectl apply -f k8s/
kubectl describe pod -n shopdemo -l app=shopdemo-orders
```

Verificar `Liveness: http-get /alive` y `Readiness: http-get /health`.

---

### Paso B2 — HPA

```bash
kubectl apply -f k8s/catalog/hpa.yaml
kubectl get hpa shopdemo-catalog-hpa -n shopdemo
```

Si `TARGETS` muestra `<unknown>`:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

---

### Paso B3 — Fallo de pod

```bash
kubectl delete pod -n shopdemo -l app=shopdemo-inventory
kubectl get pods -n shopdemo -w
```

Probar confirmación de pedido durante y después del reinicio.

---

### Paso B4 — Comunicación síncrona

**Objetivo:** Entender límite de resiliencia actual sin Polly en `InventoryHttpClient`.

| Escenario | Comportamiento |
|---|---|
| Inventory pod caído | Orders → 500, `traceId` en respuesta |
| Inventory lento | Timeout depende de HttpClient (default 100 s) |
| Inventory 2 réplicas + Service | K8s balancea; una réplica caída no tumba todo |

**Mitigación documentada (sin código):**

- Múltiples réplicas Inventory
- Health checks en ALB/Ingress
- Alertas CloudWatch (ver observabilidad)
- Futuro: `AddStandardResilienceHandler` en Orders DI

---

## Checklist

| # | Criterio | ECS | EKS |
|---|---|---|---|
| 1 | Health check `/health` activo | ALB + task | K8s probes |
| 2 | Redundancia (≥1, ideal 2 en Inventory) | desired count | replicas + HPA |
| 3 | Recuperación probada | stop-task | delete pod |
| 4 | Circuit breaker / rolling update | ECS breaker | rollout |
| 5 | Event Hubs async demostrado | ✓ | ✓ |

---

## Referencias

- [IMPLEMENTACION-DESPLIEGUE-AWS.md](../../despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md)
- [IMPLEMENTACION-DESPLIEGUE-EKS.md](../../despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md)
