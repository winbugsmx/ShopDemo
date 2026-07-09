# Historias de Usuario — Despliegue AKS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-DESPLIEGUE-AKS.md](./REQUERIMIENTOS-DESPLIEGUE-AKS.md) |

---

## HU-AKS-01 — Operar tienda en AKS

| **RF** | RF-AKS-01, RF-AKS-03 |

**Como** operador, **quiero** acceder a las APIs por Ingress en AKS, **para** ejecutar el e-commerce en Kubernetes gestionado.

### Criterios (CA-N)

- [ ] **CA-N-AKS-01:** Rutas Ingress responden correctamente.

---

## HU-AKS-02 — Completar flujo de pedidos

| **RF** | RF-AKS-02 |

**Como** operador, **quiero** confirmar pedidos en AKS, **para** validar integración pedidos-inventario en cluster.

### Criterios (CA-N)

- [ ] **CA-N-AKS-02:** Confirmación exitosa con reserva de stock.

---

## HU-AKS-03 — Mantener disponibilidad del servicio

| **RF** | RF-AKS-04 |

**Como** equipo de soporte, **quiero** que el cluster reemplace instancias fallidas, **para** minimizar tiempo de indisponibilidad.

### Criterios (CA-N)

- [ ] **CA-N-AKS-03:** Servicio recuperado tras fallo de pod.

---

## HU-AKS-04 — Gestionar release en AKS

| **RF** | RF-AKS-05 |

**Como** responsable de TI, **quiero** actualizar imágenes y manifiestos, **para** desplegar nuevas versiones con documentación reproducible.

### Criterios (CA-N)

- [ ] **CA-N-AKS-04:** Pasos Portal y CLI documentados.

---

Implementación: [ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AKS.md](./ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AKS.md).
