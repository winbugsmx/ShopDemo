# Documento de Requerimientos — Integración de IA (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Módulo** | Integración IA — operar, observar y actuar |
| **Versión** | 2.0 (enfoque negocio) |
| **Fecha** | Julio 2026 |

**Documentos relacionados:**

| Capa | Documento |
|---|---|
| Historias | [HISTORIAS-USUARIO-INTEGRACION-IA.md](./HISTORIAS-USUARIO-INTEGRACION-IA.md) |
| Especificación técnica | [ANEXO-ESPECIFICACION-TECNICA-INTEGRACION-IA.md](./ANEXO-ESPECIFICACION-TECNICA-INTEGRACION-IA.md) |
| Historias técnicas | [ANEXO-HISTORIAS-TECNICAS-INTEGRACION-IA.md](./ANEXO-HISTORIAS-TECNICAS-INTEGRACION-IA.md) |
| Pedagogía | [ANEXO-PEDAGOGIA-INTEGRACION-IA.md](./ANEXO-PEDAGOGIA-INTEGRACION-IA.md) |
| Despliegue MCP (negocio) | [REQUERIMIENTOS-DESPLIEGUE-MCP.md](./REQUERIMIENTOS-DESPLIEGUE-MCP.md) |

---

## Resumen en lenguaje llano

El equipo debe poder **detectar anomalías** en la operación de la tienda, **consultar el sistema con ayuda de agentes de IA** y entender cómo **enriquecer eventos de negocio** con modelos de lenguaje. La integración cierra el ciclo: desplegar → observar → actuar con IA, sin sustituir las APIs de negocio.

---

## 1. Propósito

Definir qué debe lograr la integración de IA en ShopDemo: alertas operativas, gateway MCP para agentes y diseño de enriquecimiento con Semantic Kernel.

---

## 2. Actores

| Actor | Rol |
|---|---|
| **Equipo de soporte** | Recibe alertas y consulta estado vía agente |
| **Responsable de TI** | Configura alertas y despliega gateway MCP |
| **Responsable de operaciones** | Usa herramientas IA para consultas sobre la tienda |

---

## 3. Objetivos operativos

| ID | Objetivo |
|---|---|
| OBJ-IA-01 | **Detectar anomalías** básicas en logs y métricas (umbrales, no ML custom) |
| OBJ-IA-02 | Permitir que **agentes consulten** ShopDemo vía gateway MCP |
| OBJ-IA-03 | Documentar **enriquecimiento de eventos** con Semantic Kernel y Event Hubs |
| OBJ-IA-04 | Cubrir integración IA en **Azure y AWS** por separado |
| OBJ-IA-05 | Usar **un proveedor LLM común** (OpenAI API) en el lab multicloud |

---

## 4. Requerimientos de negocio

| ID | Requerimiento |
|---|---|
| RF-IA-01 | Al menos una **alerta activa** notifica degradación o errores repetidos |
| RF-IA-02 | Un **agente** puede listar e invocar herramientas sobre la tienda |
| RF-IA-03 | Documentación describe flujo **evento → LLM → publicación enriquecida** |
| RF-IA-04 | Guías de alertas y MCP completas para Azure y AWS |
| RF-IA-05 | API keys y secretos **no** expuestos en repositorio |

---

## 5. Reglas

| ID | Regla |
|---|---|
| RN-IA-01 | MCP delega en APIs existentes; no reemplaza catálogo/pedidos |
| RN-IA-02 | Alertas por umbral; sin modelos ML entrenados en el lab |
| RN-IA-03 | Worker Semantic Kernel es diseño documentado; no obligatorio en repo |

---

## 6. Fuera de alcance

- Predicción de fallos con ML custom
- Fine-tuning de modelos
- Azure OpenAI / Bedrock nativos (lab unificado OpenAI API)

---

## 7. Criterios de aceptación (CA-N)

| ID | Criterio |
|---|---|
| CA-N-IA-01 | Dado umbral configurado, cuando se supera o simula, entonces la alerta se dispara o queda probada |
| CA-N-IA-02 | Dado agente conectado al gateway, cuando invoca herramienta de estado, entonces recibe respuesta coherente |
| CA-N-IA-03 | Dado documento SK, cuando se revisa, entonces describe flujo Event Hubs → LLM |
| CA-N-IA-04 | Dado cada cloud del lab, cuando se completan guías, entonces Azure y AWS documentados |

---

## 8. Referencias

- [REQUERIMIENTOS-DESPLIEGUE-MCP.md](./REQUERIMIENTOS-DESPLIEGUE-MCP.md)
- [observabilidad/](../observabilidad/)
- [TEORIA-INTEGRACION-IA.md](./TEORIA-INTEGRACION-IA.md)
