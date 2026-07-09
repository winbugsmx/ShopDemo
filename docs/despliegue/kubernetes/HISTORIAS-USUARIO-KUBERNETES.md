# Historias de Usuario — Kubernetes local (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-KUBERNETES.md](./REQUERIMIENTOS-KUBERNETES.md) |
| **Especificación** | [ANEXO-ESPECIFICACION-TECNICA-KUBERNETES.md](./ANEXO-ESPECIFICACION-TECNICA-KUBERNETES.md) |
| **Historias técnicas** | [ANEXO-HISTORIAS-TECNICAS-KUBERNETES.md](./ANEXO-HISTORIAS-TECNICAS-KUBERNETES.md) |

---

## HU-K8-01 — Operar tienda vía Ingress local

| **Requerimiento** | RF-K8-01 |

**Como** operador de la tienda, **quiero** acceder a catálogo, pedidos y analítica por `shopdemo.local`, **para** probar el e-commerce en Kubernetes sin URLs dispersas.

### Criterios (CA-N)

- [ ] **CA-N-K8-01:** Rutas `/catalog`, `/orders`, `/analytics`, `/mcp` responden.

---

## HU-K8-02 — Completar flujo E2E en cluster local

| **Requerimiento** | RF-K8-02 |

**Como** operador, **quiero** crear producto, pedido y confirmación en Minikube, **para** validar integración completa.

### Criterios (CA-N)

- [ ] **CA-N-K8-02:** Flujo producto → pedido → confirmar exitoso.

---

## HU-K8-03 — Confiar en salud de servicios

| **Requerimiento** | RF-K8-04 |

**Como** equipo de soporte, **quiero** que solo instancias saludables reciban tráfico, **para** evitar errores durante despliegues o reinicios.

### Criterios (CA-N)

- [ ] **CA-N-K8-03:** Probes de salud configurados y en estado Success.

---

## HU-K8-04 — Preparar release multicloud

| **Requerimiento** | RF-K8-05, OBJ-K8-05 |

**Como** responsable de TI, **quiero** manifiestos validados en local, **para** reutilizarlos en AKS y EKS.

### Criterios (CA-N)

- [ ] **CA-N-K8-04:** Mismos YAML aplicables cambiando carpeta `local/` → `azure/` o `aws/`.

---

Implementación: [ANEXO-HISTORIAS-TECNICAS-KUBERNETES.md](./ANEXO-HISTORIAS-TECNICAS-KUBERNETES.md).
