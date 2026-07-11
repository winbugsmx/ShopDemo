# Anexo — Historias técnicas: Spec-driven (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | B — Tareas de implementación |

---

## HT-SDD-01 — Crear y mantener specs por módulo

**Como** desarrollador del curso, **quiero** 13 archivos `SPEC.md` en `spec-driven/specs/`, **para** que agentes lean alcance antes de codificar.

### Criterios (CA-T)

- [ ] **CA-T-SDD-01:** Enlaces a `Documentación del Proyecto/*/REQUERIMIENTOS-*.md` y anexos técnicos.

---

## HT-SDD-02 — Activar plantillas Cursor

**Como** alumno, **quiero** copiar `cursor/templates/` a `.cursor/` y `AGENTS.md` a raíz, **para** usar rules y commands del curso.

### Modelo

- `cursor/templates/.cursor/rules/`
- `cursor/templates/skills/spec-workflow/`

### Criterios (CA-T)

- [ ] **CA-N-SDD-02:** Sin errores según [IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md](./IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md).

---

## HT-SDD-03 — Activar plantillas Claude Code

**Como** alumno, **quiero** copiar `claude-code/templates/` a raíz, **para** usar commands y skills.

### Criterios (CA-T)

- [ ] **CA-N-SDD-03:** `CLAUDE.md` + `.claude/` operativos.

---

## HT-SDD-04 — Commands deploy Azure/AWS

**Como** alumno, **quiero** commands `deploy-azure` y `deploy-aws` separados, **para** no mezclar ACA y ECS.

---

## HT-SDD-05 — Plantilla MCP multientorno

**Como** alumno, **quiero** `.mcp.json` template con perfiles local / Azure / AWS.

### Criterios (CA-T)

- [ ] **CA-N-SDD-04:** Tres perfiles documentados.

---

## HT-SDD-06 — Excluir secretos locales de git

**Como** desarrollador, **quiero** `*.local.*` en `.gitignore`, **para** no commitear credenciales.

### Criterios (CA-T)

- [ ] **CA-N-SDD-05:** Patrones en `.gitignore` verificados.
