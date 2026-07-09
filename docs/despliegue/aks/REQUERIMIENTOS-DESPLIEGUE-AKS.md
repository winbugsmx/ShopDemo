# Documento de Requerimientos — Despliegue AKS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Módulo** | Despliegue Azure Kubernetes Service |
| **Versión** | 2.0 (enfoque negocio) |
| **Fecha** | Julio 2026 |

**Documentos relacionados:**

| Capa | Documento |
|---|---|
| Historias | [HISTORIAS-USUARIO-DESPLIEGUE-AKS.md](./HISTORIAS-USUARIO-DESPLIEGUE-AKS.md) |
| Especificación técnica | [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AKS.md](./ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AKS.md) |
| Historias técnicas | [ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AKS.md](./ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AKS.md) |
| Pedagogía | [ANEXO-PEDAGOGIA-DESPLIEGUE-AKS.md](./ANEXO-PEDAGOGIA-DESPLIEGUE-AKS.md) |

---

## Resumen en lenguaje llano

ShopDemo debe **funcionar en Azure Kubernetes Service (AKS)** con el mismo flujo de tienda que en Minikube y Container Apps: productos, pedidos, inventario, analítica y MCP accesibles por un punto de entrada en la nube. El responsable de TI gestiona el cluster y garantiza que la operación del e-commerce no dependa de máquinas locales.

---

## 1. Propósito

Definir qué debe lograr el despliegue en AKS: disponibilidad del flujo E2E en Kubernetes gestionado en Azure, reutilizando manifiestos validados en local.

---

## 2. Actores

| Actor | Rol |
|---|---|
| **Operador de la tienda** | Ejecuta flujos E2E vía Ingress en AKS |
| **Responsable de TI** | Crea cluster, publica imágenes y aplica manifiestos |
| **Equipo de soporte** | Monitorea pods y responde incidentes |

---

## 3. Objetivos operativos

| ID | Objetivo |
|---|---|
| OBJ-AKS-01 | La tienda ShopDemo está **disponible en AKS** con Ingress público |
| OBJ-AKS-02 | El **flujo E2E** se completa en el cluster de producción-lab |
| OBJ-AKS-03 | Los servicios se **recuperan automáticamente** tras fallos de instancia |
| OBJ-AKS-04 | Las **imágenes** provienen de ACR vinculado al cluster |
| OBJ-AKS-05 | Existe documentación operativa **Portal y CLI** |

---

## 4. Alcance — Requerimientos de negocio

| ID | Requerimiento |
|---|---|
| RF-AKS-01 | Operar catálogo, pedidos y analítica vía Ingress AKS |
| RF-AKS-02 | Confirmar pedidos con reserva de stock |
| RF-AKS-03 | Consultar MCP Gateway en ruta `/mcp` |
| RF-AKS-04 | Verificar salud de servicios antes de tráfico |
| RF-AKS-05 | Actualizar release con nuevas imágenes ACR |

---

## 5. Reglas de operación

| ID | Regla |
|---|---|
| RN-AKS-01 | Deployments solo desde `k8s/azure/`; nunca aplicar `k8s/aws/` en AKS |
| RN-AKS-02 | Recursos compartidos (postgres, services, ingress) desde `k8s/` |
| RN-AKS-03 | Secretos en `shopdemo-secrets`; no commitear valores reales |

---

## 6. Criterios de aceptación (CA-N)

| ID | Criterio |
|---|---|
| CA-N-AKS-01 | Ingress AKS responde rutas de la tienda |
| CA-N-AKS-02 | Flujo producto → pedido → confirmación exitoso |
| CA-N-AKS-03 | Tras eliminar un pod, el servicio vuelve a operar |
| CA-N-AKS-04 | Documentación Portal + CLI completada |

---

## 7. Referencias

- [IMPLEMENTACION-DESPLIEGUE-AKS.md](./IMPLEMENTACION-DESPLIEGUE-AKS.md)
- [despliegue/kubernetes/](../kubernetes/)
- [despliegue/azure/](../azure/)
