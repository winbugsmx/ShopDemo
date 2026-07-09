# Anexo — Pedagogía: Resiliencia (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | C — Objetivos del curso |

---

## 1. Objetivos de aprendizaje

1. Configurar **health checks** en ACA, ECS, AKS, EKS.
2. Demostrar **auto-recuperación** tras fallo de instancia.
3. Usar **HPA** o réplicas múltiples como resiliencia ante carga.
4. Diferenciar fallos **síncronos** y **asíncronos** en ShopDemo.
5. Ejecutar **rolling updates** sin downtime total.

---

## 2. Tiempo estimado

| Actividad | Duración |
|---|---|
| Health probes (1 plataforma) | 45 min |
| Simulación fallo + recuperación | 45 min |
| HPA / escalado | 30 min |
| Documento síncrono vs asíncrono | 30 min |
| Segunda plataforma cloud | 1–1.5 h |
| **Total** | **3–4 h** |

---

## 3. Entregables

| # | Entregable |
|---|---|
| 1 | Evidencia recuperación tras delete pod/restart task |
| 2 | Captura probes Success |
| 3 | `kubectl get hpa` o réplicas ACA |
| 4 | Párrafo síncrono vs asíncrono |
| 5 | Guías Azure y AWS completadas |

---

## 4. Referencias

- [TEORIA-RESILIENCIA.md](./TEORIA-RESILIENCIA.md)
