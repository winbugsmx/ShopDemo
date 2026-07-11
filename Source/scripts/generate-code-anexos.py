"""Genera anexos markdown con código completo para el curso ShopDemo."""
from __future__ import annotations

import os
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SOURCE_ROOT = REPO_ROOT / "Source"
DOCS_ROOT = REPO_ROOT / "Documentación_Del_Proyecto"
FENCE = "```"


def collect_cs_files(base: Path, exclude_dirs: set[str] | None = None) -> list[tuple[str, Path]]:
    exclude_dirs = exclude_dirs or {"Migrations", "obj", "bin"}
    files: list[tuple[str, Path]] = []
    for dirpath, dirnames, filenames in os.walk(base):
        dirnames[:] = [d for d in dirnames if d not in exclude_dirs]
        for fn in sorted(filenames):
            if fn.endswith(".cs"):
                p = Path(dirpath) / fn
                rel = p.relative_to(REPO_ROOT).as_posix()
                files.append((rel, p))
    files.sort(key=lambda x: x[0])
    return files


def write_anexo(
    out_path: Path,
    title: str,
    intro: str,
    files: list[tuple[str, Path]],
    purpose: dict[str, str] | None = None,
) -> int:
    purpose = purpose or {}
    lines = [f"# {title}", "", intro, ""]
    for rel, p in files:
        content = p.read_text(encoding="utf-8")
        desc = purpose.get(rel, f"Archivo de referencia — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).")
        lines.extend(
            [
                "---",
                f"## `{rel}`",
                "",
                f"**Para qué sirve:** {desc}",
                "",
                f"{FENCE}csharp",
                content.rstrip(),
                FENCE,
                "",
            ]
        )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines), encoding="utf-8")
    return len(files)


def main() -> None:
    guia = "[GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md)"

    # --- Orders ---
    orders_purpose = {
        "Source/Orders/ShopDemo.Orders.Domain/Aggregates/Order.cs": "Agregado raíz de pedidos y transiciones de estado.",
        "Source/Orders/ShopDemo.Orders.Application/Commands/ConfirmOrder/ConfirmOrderHandler.cs": "Confirma pedido y reserva stock vía HTTP a Inventory.",
        "Source/Orders/ShopDemo.Orders.Infraestructure/Integrations/InventoryHttpClient.cs": "Cliente HTTP hacia Inventory (etapa 3).",
        "Source/Orders/ShopDemo.Orders.Infraestructure/Messaging/EventHubsDomainEventPublisher.cs": "Publica domain events a Event Hubs (etapa 5).",
        "Source/Orders/ShopDemo.Orders.Api/Controllers/OrdersController.cs": "REST: crear, confirmar, cancelar pedidos.",
    }
    n = write_anexo(
        DOCS_ROOT / "orders/ANEXO-CODIGO-ORDERS.md",
        "Anexo — Código completo Orders (copiar/integrar)",
        f"> Copia cada bloque en la ruta indicada. Elimina placeholders.\n\n"
        f"**Guía de desarrollo:** {guia} (etapa 2)\n"
        f"**Explicación arquitectónica:** [IMPLEMENTACION-ORDERS.md](./IMPLEMENTACION-ORDERS.md)",
        collect_cs_files(SOURCE_ROOT / "Orders"),
        orders_purpose,
    )
    print(f"Orders: {n} files")

    # --- Event Hubs (archivos específicos + config) ---
    eh_files: list[tuple[str, Path]] = []
    eh_paths = [
        "Source/Catalog/ShopDemo.Catalog.Infraestructure/Messaging/EventHubsDomainEventPublisher.cs",
        "Source/Catalog/ShopDemo.Catalog.Infraestructure/Messaging/LoggingDomainEventPublisher.cs",
        "Source/Catalog/ShopDemo.Catalog.Infraestructure/DependencyInjection.cs",
        "Source/Orders/ShopDemo.Orders.Infraestructure/Messaging/EventHubsDomainEventPublisher.cs",
        "Source/Orders/ShopDemo.Orders.Infraestructure/Messaging/LoggingDomainEventPublisher.cs",
        "Source/Orders/ShopDemo.Orders.Infraestructure/DependencyInjection.cs",
        "Source/Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Messaging/EventHubsIntegrationEventPublisher.cs",
        "Source/Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Messaging/CatalogEventsProcessor.cs",
        "Source/Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Messaging/LoggingIntegrationEventPublisher.cs",
        "Source/Inventory/ShopDemo.Inventory.Infrastructure/DependencyInjection.cs",
        "Source/ShopDemo.Shared/Messaging/IntegrationEventEnvelope.cs",
    ]
    eh_purpose = {
        "Source/Catalog/ShopDemo.Catalog.Infraestructure/Messaging/EventHubsDomainEventPublisher.cs": "Productor: serializa domain events de Catalog al hub `catalog-events`.",
        "Source/Orders/ShopDemo.Orders.Infraestructure/Messaging/EventHubsDomainEventPublisher.cs": "Productor: publica eventos de pedidos al hub `orders-events`.",
        "Source/Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Messaging/EventHubsIntegrationEventPublisher.cs": "Productor: publica eventos de inventario al hub `inventory-events`.",
        "Source/Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Messaging/CatalogEventsProcessor.cs": "Consumidor: crea stock automático al recibir `ProductCreated` de Catalog.",
        "Source/ShopDemo.Shared/Messaging/IntegrationEventEnvelope.cs": "Contrato JSON compartido entre productores y consumidores.",
        "Source/Catalog/ShopDemo.Catalog.Infraestructure/DependencyInjection.cs": "Registra publisher según `EventHubs:Enabled` (logging vs Event Hubs).",
        "Source/Orders/ShopDemo.Orders.Infraestructure/DependencyInjection.cs": "Igual que Catalog para Orders.",
        "Source/Inventory/ShopDemo.Inventory.Infrastructure/DependencyInjection.cs": "Publisher + `CatalogEventsProcessor` como hosted service.",
    }
    for rel in eh_paths:
        p = REPO_ROOT / rel.replace("/", os.sep)
        if p.exists():
            eh_files.append((rel, p))

    config_files = [
        ("Source/Catalog/ShopDemo.Catalog.Api/appsettings.json", "Configuración Event Hubs de Catalog (Enabled false por defecto)."),
        ("Source/Orders/ShopDemo.Orders.Api/appsettings.json", "Configuración Event Hubs de Orders."),
        ("Source/Inventory/ShopDemo.Inventory.Api/appsettings.json", "Configuración Event Hubs + consumer group de Inventory."),
        ("Source/Catalog/ShopDemo.Catalog.Api/.env.example", "Plantilla Docker: variables `EventHubs__*` para Catalog."),
        ("Source/Orders/ShopDemo.Orders.Api/.env.example", "Plantilla Docker: variables Event Hubs para Orders."),
        ("Source/Inventory/ShopDemo.Inventory.Api/.env.example", "Plantilla Docker: variables Event Hubs para Inventory."),
        ("Source/Catalog/ShopDemo.Catalog.Api/docker-compose.yml", "Compose Catalog: inyecta `EventHubs__*` al contenedor API."),
        ("Source/Orders/ShopDemo.Orders.Api/docker-compose.yml", "Compose Orders: variables Event Hubs + InventoryApi."),
        ("Source/Inventory/ShopDemo.Inventory.Api/docker-compose.yml", "Compose Inventory: Event Hubs + Azurite para checkpoints."),
    ]
    lines = [
        "# Anexo — Código completo Event Hubs (copiar/integrar)",
        "",
        "> Etapa 5. Requiere namespace y hubs creados en Azure (ver INTEGRACION-AZURE-EVENT-HUBS.md).",
        "",
        f"**Guía de desarrollo:** {guia} (etapa 5)\n"
        f"**Portal/CLI Azure:** [INTEGRACION-AZURE-EVENT-HUBS.md](./INTEGRACION-AZURE-EVENT-HUBS.md)\n",
    ]
    for rel, p in eh_files:
        content = p.read_text(encoding="utf-8")
        desc = eh_purpose.get(rel, "Código de integración Event Hubs.")
        lines.extend(["---", f"## `{rel}`", "", f"**Para qué sirve:** {desc}", "", f"{FENCE}csharp", content.rstrip(), FENCE, ""])
    for rel, desc in config_files:
        p = REPO_ROOT / rel.replace("/", os.sep)
        if not p.exists():
            continue
        ext = p.suffix.lstrip(".")
        content = p.read_text(encoding="utf-8")
        lines.extend(["---", f"## `{rel}`", "", f"**Para qué sirve:** {desc}", "", f"{FENCE}{ext}", content.rstrip(), FENCE, ""])
    (DOCS_ROOT / "ANEXO-CODIGO-EVENT-HUBS.md").write_text("\n".join(lines), encoding="utf-8")
    print(f"Event Hubs: {len(eh_files)} cs + config")

    # --- Analytics + Aspire ---
    aspire_purpose = {
        "Source/Aspire/ShopDemo.ServiceDefaults/Extensions.cs": "Health checks, OpenTelemetry y resiliencia HTTP compartida.",
        "Source/Aspire/ShopDemo.Analytics.Api/Messaging/EventHubAnalyticsProcessor.cs": "Consumidor read-only: persiste eventos en memoria para consulta.",
        "Source/Aspire/ShopDemo.Analytics.Api/Controllers/AnalyticsController.cs": "GET /api/analytics/events — lista eventos capturados.",
        "Source/Aspire/ShopDemo.AppHost/Program.cs": "Orquesta 4 APIs + PostgreSQL + Azurite + config Event Hubs.",
    }
    aspire_files = collect_cs_files(SOURCE_ROOT / "Aspire")
    n = write_anexo(
        DOCS_ROOT / "analytics/ANEXO-CODIGO-ANALYTICS-ASPIRE.md",
        "Anexo — Código completo Analytics + Aspire (copiar/integrar)",
        f"> Etapa 6. Copia en `Source/Aspire/`. AppHost solo para desarrollo local.\n\n"
        f"**Guía de desarrollo:** {guia} (etapa 6)\n"
        f"**Explicación:** [IMPLEMENTACION-ANALYTICS-ASPIRE.md](./IMPLEMENTACION-ANALYTICS-ASPIRE.md)",
        aspire_files,
        aspire_purpose,
    )
    aspire_config = [
        ("Source/Aspire/ShopDemo.Analytics.Api/appsettings.json", "Configuración del consumidor Analytics (Event Hubs + store en memoria)."),
        ("Source/Aspire/ShopDemo.Analytics.Api/.env.example", "Plantilla Docker para Analytics con variables Event Hubs."),
        ("Source/Aspire/ShopDemo.Analytics.Api/docker-compose.yml", "Compose Analytics: puerto 8004 y variables del bus."),
    ]
    out = DOCS_ROOT / "analytics/ANEXO-CODIGO-ANALYTICS-ASPIRE.md"
    extra = []
    for rel, desc in aspire_config:
        p = REPO_ROOT / rel.replace("/", os.sep)
        if not p.exists():
            continue
        ext = p.suffix.lstrip(".")
        extra.extend(["---", f"## `{rel}`", "", f"**Para qué sirve:** {desc}", "", f"{FENCE}{ext}", p.read_text(encoding="utf-8").rstrip(), FENCE, ""])
    if extra:
        out.write_text(out.read_text(encoding="utf-8") + "\n" + "\n".join(extra), encoding="utf-8")
    print(f"Source/Aspire/Analytics: {n} files + config")


if __name__ == "__main__":
    main()
