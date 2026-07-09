# Documento de Requerimientos — Kubernetes local (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Módulo** | Despliegue Kubernetes — entorno local (Minikube) |
| **Versión** | 2.0 (enfoque negocio) |
| **Fecha** | Julio 2026 |

**Documentos relacionados:**

| Capa | Documento |
|---|---|
| Historias de usuario | [HISTORIAS-USUARIO-KUBERNETES.md](./HISTORIAS-USUARIO-KUBERNETES.md) |
| Especificación técnica | [ANEXO-ESPECIFICACION-TECNICA-KUBERNETES.md](./ANEXO-ESPECIFICACION-TECNICA-KUBERNETES.md) |
| Historias técnicas | [ANEXO-HISTORIAS-TECNICAS-KUBERNETES.md](./ANEXO-HISTORIAS-TECNICAS-KUBERNETES.md) |
| Pedagogía | [ANEXO-PEDAGOGIA-KUBERNETES.md](./ANEXO-PEDAGOGIA-KUBERNETES.md) |

---

## Resumen en lenguaje llano

Antes de llevar ShopDemo a la nube, el equipo debe poder **ejecutar la tienda completa en Kubernetes local** (Minikube): mismas APIs, mismo flujo de productos y pedidos, acceso por un único punto de entrada (`shopdemo.local`). Esto valida que los manifiestos funcionan y se reutilizarán en AKS y EKS.

---

## 1. Propósito

Definir qué debe lograr el despliegue local en Kubernetes: operar el e-commerce con flujo E2E, verificar salud de servicios y preparar manifiestos reutilizables en nube.

---

## 2. Actores

| Actor | Rol |
|---|---|
| **Operador de la tienda** | Prueba flujos de negocio vía Ingress local |
| **Responsable de TI** | Despliega y mantiene el cluster Minikube |
| **Equipo de soporte** | Revisa logs y estado de pods ante incidentes |

---

## 3. Objetivos operativos

| ID | Objetivo |
|---|---|
| OBJ-K8-01 | La tienda ShopDemo **funciona en Kubernetes local** con flujo E2E completo |
| OBJ-K8-02 | Un **punto de entrada único** (Ingress) expone catálogo, pedidos, inventario, analítica y MCP |
| OBJ-K8-03 | Los servicios reportan **salud** antes de recibir tráfico de negocio |
| OBJ-K8-04 | Los **datos y secretos** están configurados sin exponer credenciales |
| OBJ-K8-05 | Los manifiestos son **reutilizables** en AKS y EKS cambiando solo imágenes y carpeta cloud |

---

## 4. Alcance

### 4.1 Incluido

| ID | Requerimiento de negocio |
|---|---|
| RF-K8-01 | Registrar productos y completar pedidos vía Ingress local |
| RF-K8-02 | Inventario y analítica operativos con eventos del bus |
| RF-K8-03 | PostgreSQL y almacenamiento de checkpoints disponibles en cluster |
| RF-K8-04 | Verificar salud de cada servicio antes de operar |
| RF-K8-05 | Escalar catálogo bajo carga (demostración HPA) |

### 4.2 Fuera de alcance

- Service mesh (Istio/Linkerd)
- GitOps (ArgoCD) en producción
- Helm charts empaquetados de ShopDemo (solo Ingress Helm en AKS/EKS)

---

## 5. Reglas de operación

| ID | Regla |
|---|---|
| RN-K8-01 | Namespace único `shopdemo` para todos los recursos |
| RN-K8-02 | Orden de despliegue: infraestructura (postgres, azurite) → APIs → ingress |
| RN-K8-03 | Secretos generados localmente; nunca commitear `k8s/secrets.yaml` |
| RN-K8-04 | Host Ingress: `shopdemo.local` en archivo hosts del operador |

---

## 6. Criterios de aceptación de negocio (CA-N)

| ID | Criterio |
|---|---|
| CA-N-K8-01 | Dado el cluster local, cuando el operador accede a rutas del Ingress, entonces las APIs responden |
| CA-N-K8-02 | Dado un flujo producto → pedido → confirmación, cuando se ejecuta vía Ingress, entonces se completa sin error |
| CA-N-K8-03 | Dado un servicio no saludable, cuando el orquestador lo detecta, entonces no enruta tráfico hasta recuperación |
| CA-N-K8-04 | Dado manifiestos validados en local, cuando se aplican en AKS/EKS, entonces el mismo stack despliega con imágenes cloud |

---

## 7. Referencias

- [k8s/README.md](../../../k8s/README.md)
- [IMPLEMENTACION-KUBERNETES-LOCAL.md](./IMPLEMENTACION-KUBERNETES-LOCAL.md)
- [despliegue/aks/](../aks/) · [despliegue/eks/](../eks/)
