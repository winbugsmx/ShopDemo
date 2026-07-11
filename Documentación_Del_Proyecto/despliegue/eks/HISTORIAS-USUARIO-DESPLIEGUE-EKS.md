# Historias de Usuario — Despliegue EKS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-DESPLIEGUE-EKS.md](./REQUERIMIENTOS-DESPLIEGUE-EKS.md) |

---

## HU-EKS-01 — Operar tienda en EKS

| **RF** | RF-EKS-01, RF-EKS-04 |

**Como** operador, **quiero** acceder a APIs por Ingress en EKS, **para** ejecutar el e-commerce en AWS Kubernetes.

### Criterios (CA-N)

- [ ] **CA-N-EKS-01:** Ingress responde rutas de la tienda.

---

## HU-EKS-02 — Procesar pedidos y eventos

| **RF** | RF-EKS-02, RF-EKS-03 |

**Como** operador, **quiero** confirmar pedidos y ver eventos en analítica, **para** validar integración completa.

### Criterios (CA-N)

- [ ] **CA-N-EKS-02:** Pedido confirmado; eventos visibles.

---

## HU-EKS-03 — Garantizar disponibilidad

| **RF** | RF-EKS-05 |

**Como** equipo de soporte, **quiero** recuperación automática de pods, **para** mantener servicio operativo.

### Criterios (CA-N)

- [ ] **CA-N-EKS-03:** Servicio Ready tras delete pod.

---

## HU-EKS-04 — Gestionar release EKS

**Como** responsable de TI, **quiero** actualizar imágenes ECR y manifiestos, **para** desplegar versiones con procedimiento documentado.

### Criterios (CA-N)

- [ ] **CA-N-EKS-04:** Consola y CLI documentados.

---

Implementación: [ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-EKS.md](./ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-EKS.md).
