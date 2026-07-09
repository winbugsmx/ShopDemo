"""Genera anexos markdown con código completo para el curso ShopDemo."""
from __future__ import annotations

import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FENCE = "```"


def collect_cs_files(base: Path, exclude_dirs: set[str] | None = None) -> list[tuple[str, Path]]:
    exclude_dirs = exclude_dirs or {"Migrations", "obj", "bin"}
    files: list[tuple[str, Path]] = []
    for dirpath, dirnames, filenames in os.walk(base):
        dirnames[:] = [d for d in dirnames if d not in exclude_dirs]
        for fn in sorted(filenames):
            if fn.endswith(".cs"):
                p = Path(dirpath) / fn
                rel = p.relative_to(ROOT).as_posix()
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
        "Orders/ShopDemo.Orders.Domain/Aggregates/Order.cs": "Agregado raíz de pedidos y transiciones de estado.",
        "Orders/ShopDemo.Orders.Application/Commands/ConfirmOrder/ConfirmOrderHandler.cs": "Confirma pedido y reserva stock vía HTTP a Inventory.",
        "Orders/ShopDemo.Orders.Infraestructure/Integrations/InventoryHttpClient.cs": "Cliente HTTP hacia Inventory (etapa 3).",
        "Orders/ShopDemo.Orders.Infraestructure/Messaging/EventHubsDomainEventPublisher.cs": "Publica domain events a Event Hubs (etapa 5).",
        "Orders/ShopDemo.Orders.Api/Controllers/OrdersController.cs": "REST: crear, confirmar, cancelar pedidos.",
    }
    n = write_anexo(
        ROOT / "docs/orders/ANEXO-CODIGO-ORDERS.md",
        "Anexo — Código completo Orders (copiar/integrar)",
        f"> Copia cada bloque en la ruta indicada. Elimina placeholders.\n\n"
        f"**Guía de desarrollo:** {guia} (etapa 2)\n"
        f"**Explicación arquitectónica:** [IMPLEMENTACION-ORDERS.md](./IMPLEMENTACION-ORDERS.md)",
        collect_cs_files(ROOT / "Orders"),
        orders_purpose,
    )
    print(f"Orders: {n} files")

    # --- Event Hubs (archivos específicos + config) ---
    eh_files: list[tuple[str, Path]] = []
    eh_paths = [
        "Catalog/ShopDemo.Catalog.Infraestructure/Messaging/EventHubsDomainEventPublisher.cs",
        "Catalog/ShopDemo.Catalog.Infraestructure/Messaging/LoggingDomainEventPublisher.cs",
        "Catalog/ShopDemo.Catalog.Infraestructure/DependencyInjection.cs",
        "Orders/ShopDemo.Orders.Infraestructure/Messaging/EventHubsDomainEventPublisher.cs",
        "Orders/ShopDemo.Orders.Infraestructure/Messaging/LoggingDomainEventPublisher.cs",
        "Orders/ShopDemo.Orders.Infraestructure/DependencyInjection.cs",
        "Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Messaging/EventHubsIntegrationEventPublisher.cs",
        "Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Messaging/CatalogEventsProcessor.cs",
        "Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Messaging/LoggingIntegrationEventPublisher.cs",
        "Inventory/ShopDemo.Inventory.Infrastructure/DependencyInjection.cs",
        "ShopDemo.Shared/Messaging/IntegrationEventEnvelope.cs",
    ]
    eh_purpose = {
        "Catalog/ShopDemo.Catalog.Infraestructure/Messaging/EventHubsDomainEventPublisher.cs": "Productor: serializa domain events de Catalog al hub `catalog-events`.",
        "Orders/ShopDemo.Orders.Infraestructure/Messaging/EventHubsDomainEventPublisher.cs": "Productor: publica eventos de pedidos al hub `orders-events`.",
        "Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Messaging/EventHubsIntegrationEventPublisher.cs": "Productor: publica eventos de inventario al hub `inventory-events`.",
        "Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Messaging/CatalogEventsProcessor.cs": "Consumidor: crea stock automático al recibir `ProductCreated` de Catalog.",
        "ShopDemo.Shared/Messaging/IntegrationEventEnvelope.cs": "Contrato JSON compartido entre productores y consumidores.",
        "Catalog/ShopDemo.Catalog.Infraestructure/DependencyInjection.cs": "Registra publisher según `EventHubs:Enabled` (logging vs Event Hubs).",
        "Orders/ShopDemo.Orders.Infraestructure/DependencyInjection.cs": "Igual que Catalog para Orders.",
        "Inventory/ShopDemo.Inventory.Infrastructure/DependencyInjection.cs": "Publisher + `CatalogEventsProcessor` como hosted service.",
    }
    for rel in eh_paths:
        p = ROOT / rel.replace("/", os.sep)
        if p.exists():
            eh_files.append((rel, p))

    config_files = [
        ("Catalog/ShopDemo.Catalog.Api/appsettings.json", "Configuración Event Hubs de Catalog (Enabled false por defecto)."),
        ("Orders/ShopDemo.Orders.Api/appsettings.json", "Configuración Event Hubs de Orders."),
        ("Inventory/ShopDemo.Inventory.Api/appsettings.json", "Configuración Event Hubs + consumer group de Inventory."),
        ("Catalog/ShopDemo.Catalog.Api/.env.example", "Plantilla Docker: variables `EventHubs__*` para Catalog."),
        ("Orders/ShopDemo.Orders.Api/.env.example", "Plantilla Docker: variables Event Hubs para Orders."),
        ("Inventory/ShopDemo.Inventory.Api/.env.example", "Plantilla Docker: variables Event Hubs para Inventory."),
        ("Catalog/ShopDemo.Catalog.Api/docker-compose.yml", "Compose Catalog: inyecta `EventHubs__*` al contenedor API."),
        ("Orders/ShopDemo.Orders.Api/docker-compose.yml", "Compose Orders: variables Event Hubs + InventoryApi."),
        ("Inventory/ShopDemo.Inventory.Api/docker-compose.yml", "Compose Inventory: Event Hubs + Azurite para checkpoints."),
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
        p = ROOT / rel.replace("/", os.sep)
        if not p.exists():
            continue
        ext = p.suffix.lstrip(".")
        content = p.read_text(encoding="utf-8")
        lines.extend(["---", f"## `{rel}`", "", f"**Para qué sirve:** {desc}", "", f"{FENCE}{ext}", content.rstrip(), FENCE, ""])
    (ROOT / "docs/ANEXO-CODIGO-EVENT-HUBS.md").write_text("\n".join(lines), encoding="utf-8")
    print(f"Event Hubs: {len(eh_files)} cs + config")

    # --- Analytics + Aspire ---
    aspire_purpose = {
        "Aspire/ShopDemo.ServiceDefaults/Extensions.cs": "Health checks, OpenTelemetry y resiliencia HTTP compartida.",
        "Aspire/ShopDemo.Analytics.Api/Messaging/EventHubAnalyticsProcessor.cs": "Consumidor read-only: persiste eventos en memoria para consulta.",
        "Aspire/ShopDemo.Analytics.Api/Controllers/AnalyticsController.cs": "GET /api/analytics/events — lista eventos capturados.",
        "Aspire/ShopDemo.AppHost/Program.cs": "Orquesta 4 APIs + PostgreSQL + Azurite + config Event Hubs.",
    }
    aspire_files = collect_cs_files(ROOT / "Aspire")
    n = write_anexo(
        ROOT / "docs/analytics/ANEXO-CODIGO-ANALYTICS-ASPIRE.md",
        "Anexo — Código completo Analytics + Aspire (copiar/integrar)",
        f"> Etapa 6. Copia en `Aspire/`. AppHost solo para desarrollo local.\n\n"
        f"**Guía de desarrollo:** {guia} (etapa 6)\n"
        f"**Explicación:** [IMPLEMENTACION-ANALYTICS-ASPIRE.md](./IMPLEMENTACION-ANALYTICS-ASPIRE.md)",
        aspire_files,
        aspire_purpose,
    )
    aspire_config = [
        ("Aspire/ShopDemo.Analytics.Api/appsettings.json", "Configuración del consumidor Analytics (Event Hubs + store en memoria)."),
        ("Aspire/ShopDemo.Analytics.Api/.env.example", "Plantilla Docker para Analytics con variables Event Hubs."),
        ("Aspire/ShopDemo.Analytics.Api/docker-compose.yml", "Compose Analytics: puerto 8004 y variables del bus."),
    ]
    out = ROOT / "docs/analytics/ANEXO-CODIGO-ANALYTICS-ASPIRE.md"
    extra = []
    for rel, desc in aspire_config:
        p = ROOT / rel.replace("/", os.sep)
        if not p.exists():
            continue
        ext = p.suffix.lstrip(".")
        extra.extend(["---", f"## `{rel}`", "", f"**Para qué sirve:** {desc}", "", f"{FENCE}{ext}", p.read_text(encoding="utf-8").rstrip(), FENCE, ""])
    if extra:
        out.write_text(out.read_text(encoding="utf-8") + "\n" + "\n".join(extra), encoding="utf-8")
    print(f"Aspire/Analytics: {n} files + config")


if __name__ == "__main__":
    main()
