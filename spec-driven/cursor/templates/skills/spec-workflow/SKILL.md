---
name: spec-workflow
description: Implement features using spec-driven/specs. Use when the user references a SPEC, module number, or asks for spec-driven development.
---

# Spec-driven workflow

1. Identify spec path: `spec-driven/specs/<folder>/SPEC.md`
2. Read SPEC acceptance criteria and linked `docs/` files
3. Plan minimal changes; state plan briefly in Spanish to user
4. Implement
5. Run `dotnet build ShopDemo.slnx` when C# changes
6. Report which acceptance criteria are satisfied

If no spec is named, ask which module (00-vision through 12-mcp-gateway).
