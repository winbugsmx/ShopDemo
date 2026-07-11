# Anexo — Pedagogía: Despliegue AKS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | C — Objetivos del curso |

---

## 1. Objetivos de aprendizaje

1. Crear y operar cluster **AKS** vinculado a **ACR**.
2. Instalar **Ingress NGINX** con Helm en nube.
3. Reutilizar manifiestos de Minikube en `k8s/azure/`.
4. Configurar **Secrets**, probes y **HPA** en producción-lab.
5. Automatizar con **deploy-aks.yml**.

---

## 2. Tiempo estimado

| Actividad | Duración |
|---|---|
| Cluster + ACR | 1–1.5 h |
| Ingress + manifiestos | 1.5–2 h |
| E2E + CI | 1 h |
| **Total** | **3.5–4.5 h** |

---

## 3. Entregables

| # | Entregable |
|---|---|
| 1 | Cluster AKS con pods Running |
| 2 | Captura Ingress con flujo E2E |
| 3 | Evidencia recuperación tras delete pod |
| 4 | Paso Portal + CLI documentado |

---

## 4. Posición

Etapa 10 — extensión de Kubernetes local y ACA. Complementa serverless con orquestación K8s gestionada.

---

## 5. Referencias

- [IMPLEMENTACION-DESPLIEGUE-AKS.md](./IMPLEMENTACION-DESPLIEGUE-AKS.md)
- [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AKS.md](./ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AKS.md)
