# Source — Código y scripts ShopDemo

Código fuente .NET, contenedores Docker y scripts de automatización del laboratorio.

## Estructura

```
Source/
├── ShopDemo.slnx      # Solución .NET (17 proyectos)
├── Catalog/           # Microservicio catálogo (Clean + CQRS)
├── Orders/            # Microservicio pedidos (Clean + CQRS)
├── Inventory/         # Microservicio inventario (Hexagonal)
├── Aspire/            # AppHost, ServiceDefaults, Analytics.Api
├── AI/                # MCP Gateway (ShopDemo.Mcp.Api)
├── ShopDemo.Shared/   # Kernel compartido (DDD, mensajería)
└── scripts/           # PowerShell (Azure/AWS), docs tooling, anexos
```

## Compilar

Desde la **raíz del repositorio**:

```bash
dotnet build Source/ShopDemo.slnx
```

La solución (`Source/ShopDemo.slnx`) vive en `Source/`; los paths del `.slnx` son relativos a esa carpeta (`Catalog/`, `Orders/`, etc.).

Desde `Source/`:

```bash
dotnet build ShopDemo.slnx
```

## Docker

Contexto de build: carpeta `Source/` (los Dockerfiles usan rutas relativas `Catalog/`, `Orders/`, etc.).

```bash
docker build -f Source/Catalog/ShopDemo.Catalog.Api/Dockerfile -t shopdemo-catalog:local Source
```

## Scripts de release

| Cloud | Carpeta |
|---|---|
| Azure | [scripts/azure/](scripts/azure/) |
| AWS | [scripts/aws/](scripts/aws/) |

Documentación: [Documentación_Del_Proyecto/despliegue/](../Documentación_Del_Proyecto/despliegue/README.md)

## Qué permanece fuera de Source/

| Carpeta | Contenido |
|---|---|
| `Documentación_Del_Proyecto/` | Requerimientos, implementación, Tópicos de Estudio |
| `k8s/` | Manifiestos Kubernetes |
| `spec-driven/` | SPECs para agentes IA |
| `.github/` | Workflows CI/CD |
