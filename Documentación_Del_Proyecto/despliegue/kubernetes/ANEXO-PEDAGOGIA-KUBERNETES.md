# Anexo — Pedagogía: Kubernetes local (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | C — Objetivos del curso |

---

## 1. Objetivos de aprendizaje

1. Desplegar microservicios en **Minikube** con manifiestos YAML.
2. Configurar **Ingress NGINX**, **Secrets** y **probes** HTTP.
3. Usar **StatefulSet** para PostgreSQL y **HPA** de demostración.
4. Ejecutar **flujo E2E** vía un único host.
5. Preparar manifiestos para **AKS/EKS**.

---

## 2. Tiempo estimado

| Actividad | Duración |
|---|---|
| Docker Compose previo | 30 min |
| Minikube + manifiestos | 2–3 h |
| E2E + kubectl | 1 h |
| **Total** | **3–4 h** |

---

## 3. Entregables

| # | Entregable |
|---|---|
| 1 | Todos los pods Running en `shopdemo` |
| 2 | Captura Ingress con rutas funcionando |
| 3 | Evidencia flujo E2E |
| 4 | `kubectl get hpa` con HPA Catalog |

---

## 4. Posición en roadmap

Etapa 9 — entre release ACA/ECS y AKS/EKS. Kubernetes local es prerequisito recomendado para etapas 10–11.

---

## 5. Referencias

- [IMPLEMENTACION-KUBERNETES-LOCAL.md](./IMPLEMENTACION-KUBERNETES-LOCAL.md)
- [TEORIA-KUBERNETES-OPERACIONES.md](./TEORIA-KUBERNETES-OPERACIONES.md)
