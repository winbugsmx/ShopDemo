---
name: spec-driven
description: Work from ShopDemo SPEC files before coding. Use when implementing features, modules, or course stages.
---

# Spec-driven workflow

1. User names a module or SPEC path
2. Read `spec-driven/specs/<module>/SPEC.md`
3. Open every linked doc under `docs/`
4. Copy acceptance criteria into a checklist
5. Implement minimal diff; build `dotnet build ShopDemo.slnx`
6. Point to Postman or k8s verification

Specs index: `spec-driven/specs/README.md`

Cloud: if deployment is in scope, use **deploy-azure** or **deploy-aws** skill — never both in one flow unless user asks.
