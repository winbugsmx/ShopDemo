---
name: spec-workflow
description: Implement features using spec-driven/specs. Use when the user references a SPEC, module number, or asks for spec-driven development.
---

# Spec-driven workflow

## Workflow

1. Identify spec path: `spec-driven/specs/<folder>/SPEC.md`
2. Read **Documentación (3 capas)** section in SPEC — order:
   - `REQUERIMIENTOS-*.md` + `HISTORIAS-USUARIO-*.md` (business)
   - `ANEXO-ESPECIFICACION-TECNICA-*.md` + `ANEXO-HISTORIAS-TECNICAS-*.md` (technical)
   - `IMPLEMENTACION-*.md` (step-by-step)
   - `ANEXO-PEDAGOGIA-*.md` (course context, if student task)
3. Plan minimal changes; state plan briefly in Spanish to user
4. Implement
5. Run `dotnet build Source/ShopDemo.slnx` when C# changes
6. Validate **CA-N** (business) and **CA-T** (technical) checkboxes in SPEC
7. Report which acceptance criteria are satisfied

If no spec is named, ask which module (00-vision through 12-mcp-gateway).
