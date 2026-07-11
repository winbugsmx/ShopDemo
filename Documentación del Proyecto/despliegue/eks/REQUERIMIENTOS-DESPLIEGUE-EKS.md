# Documento de Requerimientos — Despliegue EKS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Módulo** | Despliegue Amazon Elastic Kubernetes Service |
| **Versión** | 2.0 (enfoque negocio) |
| **Fecha** | Julio 2026 |

**Documentos relacionados:**

| Capa | Documento |
|---|---|
| Historias | [HISTORIAS-USUARIO-DESPLIEGUE-EKS.md](./HISTORIAS-USUARIO-DESPLIEGUE-EKS.md) |
| Especificación técnica | [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-EKS.md](./ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-EKS.md) |
| Historias técnicas | [ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-EKS.md](./ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-EKS.md) |
| Pedagogía | [ANEXO-PEDAGOGIA-DESPLIEGUE-EKS.md](./ANEXO-PEDAGOGIA-DESPLIEGUE-EKS.md) |

---

## Resumen en lenguaje llano

ShopDemo debe **funcionar en Amazon EKS** con el mismo flujo de tienda que en Minikube, AKS y ECS: registrar productos, procesar pedidos, observar eventos y consultar MCP. El responsable de TI opera el cluster Kubernetes en AWS y garantiza acceso estable vía Ingress.

---

## 1. Propósito

Definir qué debe lograr el despliegue en EKS: e-commerce operativo en Kubernetes gestionado en AWS, reutilizando manifiestos compartidos con imágenes ECR.

---

## 2. Actores

| Actor | Rol |
|---|---|
| **Operador de la tienda** | Ejecuta flujos vía Ingress EKS |
| **Responsable de TI** | Gestiona cluster EKS, ECR y manifiestos `k8s/aws/` |
| **Equipo de soporte** | Diagnostica pods y disponibilidad |

---

## 3. Objetivos operativos

| ID | Objetivo |
|---|---|
| OBJ-EKS-01 | Tienda **disponible en EKS** con Ingress accesible |
| OBJ-EKS-02 | **Flujo E2E** completado en cluster AWS |
| OBJ-EKS-03 | Servicios **se recuperan** tras fallos de pod |
| OBJ-EKS-04 | Imágenes desde **ECR** en deployments `k8s/aws/` |
| OBJ-EKS-05 | Documentación **Consola y CLI** reproducible |

---

## 4. Requerimientos de negocio

| ID | Requerimiento |
|---|---|
| RF-EKS-01 | APIs accesibles vía Ingress del balanceador |
| RF-EKS-02 | Confirmación de pedidos con reserva de stock |
| RF-EKS-03 | Eventos visibles en analítica |
| RF-EKS-04 | MCP Gateway en ruta `/mcp` |
| RF-EKS-05 | Salud verificada antes de tráfico |

---

## 5. Reglas de operación

| ID | Regla |
|---|---|
| RN-EKS-01 | Deployments solo desde `k8s/aws/`; nunca `k8s/azure/` en EKS |
| RN-EKS-02 | PVC Postgres requiere EBS CSI driver |
| RN-EKS-03 | Secretos K8s; no commitear valores |

---

## 6. Criterios de aceptación (CA-N)

| ID | Criterio |
|---|---|
| CA-N-EKS-01 | Ingress accesible por DNS/IP del balanceador |
| CA-N-EKS-02 | Flujo E2E exitoso |
| CA-N-EKS-03 | Recuperación tras fallo de instancia |
| CA-N-EKS-04 | Documentación Consola + CLI |

---

## 7. Referencias

- [IMPLEMENTACION-DESPLIEGUE-EKS.md](./IMPLEMENTACION-DESPLIEGUE-EKS.md)
- [despliegue/kubernetes/](../kubernetes/)
- [despliegue/aws/](../aws/)
