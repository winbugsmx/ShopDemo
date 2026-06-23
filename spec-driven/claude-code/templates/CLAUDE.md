# ShopDemo — Claude Code project instructions

## Overview

Lite Thinking course lab: .NET 10 microservices (Catalog, Orders, Inventory, Analytics) + MCP Gateway.  
Deploy targets: **Azure** (ACA, AKS) and **AWS** (ECS, EKS). Messaging: Azure Event Hubs.

## Spec-driven development

Before any implementation:

1. Open `spec-driven/specs/<module>/SPEC.md`
2. Read linked documents under `docs/`
3. Satisfy acceptance criteria listed in the SPEC

Specs index: `spec-driven/specs/README.md`

## Commands available

| Command | Purpose |
|---|---|
| `/implement-spec` | Work from a named SPEC path |
| `/deploy-azure` | Azure ACA/AKS deployment guidance |
| `/deploy-aws` | AWS ECS/EKS deployment guidance |
| `/review` | Code review against ShopDemo rules |
| `/run-e2e` | Postman E2E checklist |

## Build

```bash
dotnet build ShopDemo.slnx
```

## MCP

Template: `spec-driven/claude-code/templates/mcp.template.json` → copy to `.mcp.json`  
Local server: `http://localhost:8005/mcp` (requires `AI/ShopDemo.Mcp.Api`)

## Language

- Reply to the user in **Spanish**
- Code, rules, and commit messages in **English**

## Rules

Modular rules in `.claude/rules/` — code style, testing, API conventions, .NET ShopDemo patterns.

## Do not

- Commit secrets or `.env` files
- Mix Azure and AWS deploy steps in one run unless user requests
- Modify legacy API `Program.cs` without explicit SPEC scope
