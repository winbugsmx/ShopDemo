# Documento de Requerimientos — Despliegue MCP Gateway (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Módulo** | Despliegue MCP — agentes en nube |
| **Componente** | `Source/AI/ShopDemo.Mcp.Api` |
| **Versión** | 2.0 (enfoque negocio) |
| **Fecha** | Julio 2026 |

**Documentos relacionados:**

| Capa | Documento |
|---|---|
| Historias | [HISTORIAS-USUARIO-DESPLIEGUE-MCP.md](./HISTORIAS-USUARIO-DESPLIEGUE-MCP.md) |
| Especificación técnica | [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-MCP.md](./ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-MCP.md) |
| Historias técnicas | [ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-MCP.md](./ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-MCP.md) |
| Pedagogía | [ANEXO-PEDAGOGIA-DESPLIEGUE-MCP.md](./ANEXO-PEDAGOGIA-DESPLIEGUE-MCP.md) |
| Integración IA | [REQUERIMIENTOS-INTEGRACION-IA.md](./REQUERIMIENTOS-INTEGRACION-IA.md) |

---

## Resumen en lenguaje llano

Los **agentes de IA** deben poder consultar ShopDemo **en la nube**, no solo en la máquina del desarrollador. El gateway MCP expone herramientas que delegan en catálogo, pedidos, inventario y analítica, con la misma disponibilidad que el resto de la tienda desplegada.

---

## 1. Propósito

Definir qué debe lograr el despliegue del MCP Gateway en Azure (ACA, AKS) y AWS (ECS, EKS): acceso remoto a herramientas IA alineado con el release de las APIs de negocio.

---

## 2. Actores

| Actor | Rol |
|---|---|
| **Responsable de operaciones** | Consulta estado de tienda vía agente en nube |
| **Equipo de soporte** | Verifica salud del gateway y conectividad a APIs |
| **Responsable de TI** | Despliega y actualiza imagen MCP en cada plataforma |

---

## 3. Objetivos operativos

| ID | Objetivo |
|---|---|
| OBJ-MCP-01 | El gateway MCP está **disponible en nube** con URL `/mcp` accesible |
| OBJ-MCP-02 | Las **herramientas** reportan estado coherente de las APIs de negocio |
| OBJ-MCP-03 | El gateway se **actualiza** junto con el resto del release (CI/CD) |
| OBJ-MCP-04 | Documentación **Portal/Consola y CLI** en cada plataforma |

---

## 4. Requerimientos de negocio

| ID | Requerimiento |
|---|---|
| RF-MCP-01 | Agente en nube puede **listar herramientas** MCP |
| RF-MCP-02 | Herramienta de **estado** confirma APIs de negocio operativas |
| RF-MCP-03 | Gateway **accesible** tras despliegue en ACA, AKS, ECS y EKS |
| RF-MCP-04 | Actualización de gateway **sin romper** consultas existentes |
| RF-MCP-05 | Prerequisito: **4 APIs de negocio** ya desplegadas y alcanzables |

---

## 5. Reglas

| ID | Regla |
|---|---|
| RN-MCP-01 | MCP no sustituye APIs; solo delega por HTTP |
| RN-MCP-02 | Health check obligatorio antes de exponer tráfico |
| RN-MCP-03 | URLs de APIs inyectadas por entorno (no hardcode localhost) |

---

## 6. Criterios de aceptación (CA-N)

| ID | Criterio |
|---|---|
| CA-N-MCP-01 | Dado gateway desplegado, cuando se consulta salud, entonces responde exitosamente |
| CA-N-MCP-02 | Dado agente conectado, cuando lista herramientas, entonces ve las 4 tools |
| CA-N-MCP-03 | Dado herramienta de estado, cuando se invoca, entonces reporta APIs OK |
| CA-N-MCP-04 | Dado cada plataforma lab, cuando se despliega MCP, entonces `/mcp` accesible |

---

## 7. Referencias

- [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](./IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md)
- [IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md](./IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md)
