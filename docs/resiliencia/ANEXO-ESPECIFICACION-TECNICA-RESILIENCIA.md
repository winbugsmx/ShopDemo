# Anexo — Especificación técnica: Resiliencia (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | B — Especificación técnica |

---

## 1. Patrones en ShopDemo

| Patrón | Implementación | Tipo |
|---|---|---|
| Orders → Inventory HTTP | Síncrono | Fallo bloquea confirmación |
| Catalog → Event Hubs → Inventory | Asíncrono | Fallo consumidor no bloquea alta producto |
| Health `/health`, `/alive` | Código + plataforma | Liveness/Readiness |
| Event Hubs | Buffer desacoplado | Resiliencia mensajería |

---

## 2. Configuración por plataforma

| Plataforma | Health | Réplicas | Escalado |
|---|---|---|---|
| ACA | Probe HTTP `/health` | min 1, max 3 lab | KEDA / reglas ACA |
| AKS/EKS | Probes en Deployment | replicas ≥ 1 | HPA Catalog (`k8s/catalog/hpa.yaml`) |
| ECS | ALB health check | desired count ≥ 1 | Manual / auto scaling lab |

---

## 3. Endpoints de salud (código)

| Servicio | Liveness | Readiness |
|---|---|---|
| Catalog | `/health` | `/alive` |
| Orders | `/health` | `/alive` |
| Inventory | `/health` | `/alive` |
| Analytics | `/health` | `/alive` |
| MCP | `/health` | — |

---

## 4. Manifiestos K8s (probes)

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
readinessProbe:
  httpGet:
    path: /alive
    port: 8080
```

---

## 5. RNF

| ID | Requerimiento |
|---|---|
| RNF-RES-01 | Sin cambios .NET obligatorios (Polly opcional) |
| RNF-RES-02 | HPA solo Catalog en lab (demo) |
| RNF-RES-03 | Rolling update por defecto en K8s/ACA/ECS |

---

## 6. CA-T

| ID | Criterio |
|---|---|
| CA-T-RES-01 | `kubectl delete pod` / restart ECS task → servicio Ready |
| CA-T-RES-02 | Probes configurados 4 servicios × plataforma |
| CA-T-RES-03 | `kubectl get hpa` o réplicas ACA documentadas |
| CA-T-RES-04 | Rolling update sin 100% downtime |
| CA-T-RES-05 | Guías azure/ y aws/ completas |

---

## 7. Referencias

- [TEORIA-RESILIENCIA.md](./TEORIA-RESILIENCIA.md)
- [observabilidad/](../observabilidad/) — logs para validar recuperación
