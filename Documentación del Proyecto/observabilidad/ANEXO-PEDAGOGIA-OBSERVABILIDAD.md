# Anexo — Pedagogía: Observabilidad (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | C — Objetivos del curso |

---

## 1. Objetivos de aprendizaje

1. Centralizar logs en **Log Analytics** y **CloudWatch**.
2. Consultar con **KQL** y **Logs Insights**.
3. Correlacionar errores con **traceId**.
4. Configurar **alertas** básicas por umbral.
5. Documentar **investigación E2E** de incidentes.

---

## 2. Tiempo estimado

| Actividad | Duración |
|---|---|
| Logs Azure (ACA o AKS) | 1–1.5 h |
| Logs AWS (ECS o EKS) | 1–1.5 h |
| Alertas + investigación E2E | 1–2 h |
| **Total** | **3–5 h** |

---

## 3. Entregables

| # | Entregable |
|---|---|
| 1 | Captura panel logs con 4 APIs |
| 2 | Consulta KQL/Logs Insights con traceId |
| 3 | Alerta configurada y probada |
| 4 | Informe corto investigación E2E |

---

## 4. Prerequisitos

APIs desplegadas en al menos un entorno Azure y uno AWS.

---

## 5. Referencias

- [TEORIA-OBSERVABILIDAD.md](./TEORIA-OBSERVABILIDAD.md)
- [IMPLEMENTACION-OBSERVABILIDAD-AZURE.md](./azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md)
- [IMPLEMENTACION-OBSERVABILIDAD-AWS.md](./aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md)
