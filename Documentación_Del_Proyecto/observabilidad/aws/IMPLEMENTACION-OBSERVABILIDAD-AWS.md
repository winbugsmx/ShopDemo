# Implementación — Observabilidad en AWS (ECS + EKS)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Prerequisitos:** ShopDemo en [ECS](../../despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md) y/o [EKS](../../despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md).  
**Teoría:** [TEORIA-OBSERVABILIDAD.md](../TEORIA-OBSERVABILIDAD.md)

---

## Índice

### Parte A — ECS Fargate
1. [Paso A1 — Log groups](#parte-a--ecs-fargate)
2. [Paso A2 — Ver logs en CloudWatch](#paso-a2--ver-logs-en-cloudwatch)
3. [Paso A3 — Métricas ECS](#paso-a3--métricas-ecs)
4. [Paso A4 — Correlación traceId](#paso-a4--correlación-traceid)
5. [Paso A5 — Alertas CloudWatch](#paso-a5--alertas-cloudwatch)

### Parte B — EKS
6. [Paso B1 — Container Insights](#parte-b--eks)
7. [Paso B2 — Logs de pods](#paso-b2--logs-de-pods)
8. [Paso B3 — Métricas y Logs Insights](#paso-b3--métricas-y-logs-insights)
9. [Paso B4 — Investigación E2E](#paso-b4--investigación-e2e)

---

## Parte A — ECS Fargate

### Paso A1 — Log groups

**Objetivo:** Cada servicio ECS envía `stdout` a CloudWatch Logs.

| # | Consola AWS | CLI |
|---|---|---|
| 1 | **CloudWatch** → **Log groups** | `aws logs describe-log-groups --log-group-name-prefix /ecs/shopdemo` |
| 2 | Verificar grupos `/ecs/shopdemo-catalog`, `orders`, etc. | |
| 3 | Si faltan: en **task definition** → `logConfiguration` → `awslogs` | Ver [IMPLEMENTACION-DESPLIEGUE-AWS.md](../../despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md) |

**Explicación:** Sin driver `awslogs`, los logs se pierden al terminar la tarea Fargate.

---

### Paso A2 — Ver logs en CloudWatch

#### Consola

1. **ECS** → cluster `shopdemo-cluster` → service `shopdemo-orders` → **Logs**
2. Abrir stream más reciente

#### CLI

```bash
aws logs tail /ecs/shopdemo-orders --follow --region $AWS_REGION
```

#### Logs Insights — buscar reservas de stock

```sql
fields @timestamp, @message
| filter @message like /Reserving stock/
| sort @timestamp desc
| limit 50
```

---

### Paso A3 — Métricas ECS

| # | Consola |
|---|---|
| 1 | **ECS** → cluster → **Metrics** |
| 2 | **CPUUtilization**, **MemoryUtilization** por servicio |
| 3 | **ALB** → **Monitoring** → Target response time, HTTP 5xx |

**Event Hubs:** métricas en **Azure Portal** (ShopDemo en AWS sigue publicando a Azure EH).

---

### Paso A4 — Correlación traceId

| # | Paso |
|---|---|
| 1 | Provocar error en confirmación de pedido |
| 2 | Copiar `traceId` del JSON de respuesta |
| 3 | CloudWatch Logs Insights: |

```sql
fields @timestamp, @message
| filter @message like /PEGAR_TRACE_ID/
| sort @timestamp desc
```

**Explicación:** Mismo mecanismo que Azure — `traceId` en `ExceptionHandlingMiddleware` sin cambios de código.

---

### Paso A5 — Alertas CloudWatch

**Objetivo:** Reacción ante CPU alta o errores.

#### Consola

1. **CloudWatch** → **Alarms** → **Create alarm**
2. Metric: `ECS/Service` → `CPUUtilization` → `shopdemo-orders`
3. Threshold: > 80 % durante 2 períodos de 5 min
4. Notification: SNS topic email

#### CLI

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name shopdemo-orders-cpu-high \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:ACCOUNT:shopdemo-alerts
```

---

## Parte B — EKS

### Paso B1 — Container Insights

| # | Consola | CLI |
|---|---|---|
| 1 | **EKS** → cluster → **Add-ons** → **Amazon CloudWatch Observability** | Instalar addon observability |
| 2 | O habilitar Container Insights en cluster | `aws eks update-cluster-config` (según versión) |

**Explicación:** Agrega métricas de pod/node a CloudWatch sin instalar Fluent Bit manualmente (versiones recientes).

---

### Paso B2 — Logs de pods

```bash
kubectl logs -n shopdemo -l app=shopdemo-orders --tail=100 -f
kubectl logs -n shopdemo -l app=shopdemo-inventory --since=10m
```

Log group típico: `/aws/containerinsights/<cluster>/application`

---

### Paso B3 — Métricas y Logs Insights

```bash
kubectl top pods -n shopdemo
kubectl get hpa -n shopdemo
```

**Logs Insights** (grupo application):

```sql
fields @timestamp, kubernetes.pod_name, @message
| filter kubernetes.namespace_name = "shopdemo"
| filter @message like /OrderId/ or @message like /stock/
| sort @timestamp desc
| limit 100
```

---

### Paso B4 — Investigación E2E

| # | Acción |
|---|---|
| 1 | Postman: flujo crear pedido → confirmar |
| 2 | Si falla: copiar `traceId` |
| 3 | Logs Insights en orders + inventory |
| 4 | `kubectl describe pod -n shopdemo -l app=shopdemo-inventory` |
| 5 | Verificar probe: `curl http://<ingress>/orders/health` |

---

## Checklist de validación

| # | Criterio | ECS | EKS |
|---|---|---|---|
| 1 | Log groups con datos recientes | ✓ | ✓ |
| 2 | Métricas CPU consultadas | ✓ | ✓ |
| 3 | Alarma creada | ✓ | ✓ |
| 4 | Búsqueda por traceId | ✓ | ✓ |
| 5 | Escenario E2E documentado | ✓ | ✓ |

---

## Referencias

- [IMPLEMENTACION-DESPLIEGUE-AWS.md](../../despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md)
- [IMPLEMENTACION-DESPLIEGUE-EKS.md](../../despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md)
