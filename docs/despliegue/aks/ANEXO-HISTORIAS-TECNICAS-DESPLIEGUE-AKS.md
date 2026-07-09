# Anexo — Historias técnicas: Despliegue AKS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | B — Tareas de implementación |

---

## HT-AKS-01 — Crear cluster y vincular ACR

| **HU** | HU-AKS-04 |

**Como** alumno, **quiero** cluster AKS + `az aks update --attach-acr`, **para** pull autenticado.

### Criterios (CA-T)

- [ ] **CA-T-AKS-01, CA-T-AKS-04**

---

## HT-AKS-02 — Publicar imágenes en ACR

**Como** alumno, **quiero** push de 5 imágenes, **para** deployments `k8s/azure/`.

---

## HT-AKS-03 — Instalar Ingress NGINX con Helm

| **HU** | HU-AKS-01 |

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
```

### Criterios (CA-T)

- [ ] **CA-T-AKS-03**

---

## HT-AKS-04 — Aplicar manifiestos y secrets

| **HU** | HU-AKS-01, HU-AKS-02 |

**Como** alumno, **quiero** apply compartidos + `k8s/azure/` con secrets, **para** stack completo.

### Criterios (CA-T)

- [ ] **CA-T-AKS-02, CA-T-AKS-05**

---

## HT-AKS-05 — Validar E2E y recuperación

| **HU** | HU-AKS-02, HU-AKS-03 |

**Como** alumno, **quiero** flujo E2E y `kubectl delete pod` de prueba, **para** ver auto-recuperación.

---

## HT-AKS-06 — CI/CD y documentación dual

| **HU** | HU-AKS-04 |

### Criterios (CA-T)

- [ ] **CA-T-AKS-06**

---

## Trazabilidad

| HU | HT |
|---|---|
| HU-AKS-01 | HT-AKS-03, HT-AKS-04 |
| HU-AKS-02 | HT-AKS-05 |
| HU-AKS-03 | HT-AKS-05 |
| HU-AKS-04 | HT-AKS-01, HT-AKS-06 |
