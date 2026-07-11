# Cheat Sheet — .NET CLI

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

Referencia rápida de comandos `dotnet` para desarrollo de microservicios con .NET. Ejemplos orientados a la solución **ShopDemo**.

---

## Información y entorno

| Comando | Descripción | Ejemplo |
|---|---|---|
| `dotnet --version` | Muestra la versión del SDK instalada | `dotnet --version` |
| `dotnet --info` | Detalle del SDK, runtime y entornos | `dotnet --info` |
| `dotnet --list-sdks` | Lista SDKs instalados | `dotnet --list-sdks` |
| `dotnet --list-runtimes` | Lista runtimes instalados | `dotnet --list-runtimes` |

---

## Soluciones y proyectos

| Comando | Descripción | Ejemplo |
|---|---|---|
| `dotnet new sln` | Crea una solución vacía | `dotnet new sln -n ShopDemo` |
| `dotnet sln add` | Agrega un proyecto a la solución | `dotnet sln Source/ShopDemo.slnx add Catalog/ShopDemo.Catalog.Api/ShopDemo.Catalog.Api.csproj` |
| `dotnet new webapi` | Crea un proyecto API | `dotnet new webapi -n ShopDemo.Orders.Api -o ShopDemo.Orders.Api` |
| `dotnet new classlib` | Crea una biblioteca de clases | `dotnet new classlib -n ShopDemo.Catalog.Domain` |
| `dotnet new list` | Lista plantillas disponibles | `dotnet new list web` |

---

## Restaurar, compilar y ejecutar

| Comando | Descripción | Ejemplo |
|---|---|---|
| `dotnet restore` | Descarga paquetes NuGet | `dotnet restore Source/ShopDemo.slnx` |
| `dotnet build` | Compila la solución o proyecto | `dotnet build Source/ShopDemo.slnx -c Release` |
| `dotnet run` | Compila y ejecuta el proyecto | `dotnet run --project ShopDemo.Catalog.Api` |
| `dotnet watch run` | Ejecuta con recarga en caliente | `dotnet watch run --project ShopDemo.Catalog.Api` |
| `dotnet clean` | Elimina artefactos de compilación | `dotnet clean Source/ShopDemo.slnx` |

**Ejemplo completo — levantar Catalog.Api:**

```bash
cd I:\Curso\ShopDemo
dotnet restore Source/ShopDemo.slnx
dotnet build ShopDemo.Catalog.Api/ShopDemo.Catalog.Api.csproj
dotnet run --project ShopDemo.Catalog.Api
```

---

## Paquetes NuGet

| Comando | Descripción | Ejemplo |
|---|---|---|
| `dotnet add package` | Agrega un paquete NuGet | `dotnet add ShopDemo.Catalog.Application package MediatR` |
| `dotnet remove package` | Quita un paquete | `dotnet remove ShopDemo.Catalog.Application package MediatR` |
| `dotnet list package` | Lista paquetes del proyecto | `dotnet list ShopDemo.Catalog.Api package` |
| `dotnet list package --outdated` | Muestra paquetes desactualizados | `dotnet list package --outdated` |

**Paquetes típicos en microservicios .NET:**

```bash
# CQRS y validación
dotnet add ShopDemo.Catalog.Application package MediatR
dotnet add ShopDemo.Catalog.Application package FluentValidation

# Entity Framework Core + PostgreSQL
dotnet add ShopDemo.Catalog.Infraestructure package Microsoft.EntityFrameworkCore
dotnet add ShopDemo.Catalog.Infraestructure package Npgsql.EntityFrameworkCore.PostgreSQL

# Herramientas de diseño EF (en la API)
dotnet add ShopDemo.Catalog.Api package Microsoft.EntityFrameworkCore.Design
```

---

## Referencias entre proyectos

| Comando | Descripción | Ejemplo |
|---|---|---|
| `dotnet add reference` | Referencia otro proyecto | `dotnet add ShopDemo.Catalog.Api reference ShopDemo.Catalog.Application` |
| `dotnet remove reference` | Elimina una referencia | `dotnet remove ShopDemo.Catalog.Api reference ShopDemo.Catalog.Application` |
| `dotnet list reference` | Lista referencias del proyecto | `dotnet list ShopDemo.Catalog.Api reference` |

**Dependencias típicas en Clean Architecture:**

```bash
dotnet add ShopDemo.Catalog.Application reference ShopDemo.Catalog.Domain
dotnet add ShopDemo.Catalog.Infraestructure reference ShopDemo.Catalog.Application
dotnet add ShopDemo.Catalog.Api reference ShopDemo.Catalog.Infraestructure
```

---

## Publicar (deploy)

| Comando | Descripción | Ejemplo |
|---|---|---|
| `dotnet publish` | Genera artefactos listos para despliegue | `dotnet publish ShopDemo.Catalog.Api -c Release -o ./publish` |
| `dotnet publish --no-build` | Publica sin recompilar | `dotnet publish ShopDemo.Catalog.Api -c Release --no-build` |

**Publicar para contenedor Linux:**

```bash
dotnet publish ShopDemo.Catalog.Api/ShopDemo.Catalog.Api.csproj \
  -c Release \
  -o ./publish \
  --os linux \
  --arch x64
```

---

## Entity Framework Core

> Requiere la herramienta global `dotnet-ef`.

| Comando | Descripción | Ejemplo |
|---|---|---|
| `dotnet tool install` | Instala herramienta global | `dotnet tool install --global dotnet-ef` |
| `dotnet ef migrations add` | Crea una migración | `dotnet ef migrations add InitialCreate --project ShopDemo.Catalog.Infraestructure --startup-project ShopDemo.Catalog.Api --output-dir Persistence/Migrations` |
| `dotnet ef database update` | Aplica migraciones a la BD | `dotnet ef database update --project ShopDemo.Catalog.Infraestructure --startup-project ShopDemo.Catalog.Api` |
| `dotnet ef migrations remove` | Elimina la última migración | `dotnet ef migrations remove --project ShopDemo.Catalog.Infraestructure --startup-project ShopDemo.Catalog.Api` |
| `dotnet ef migrations list` | Lista migraciones | `dotnet ef migrations list --project ShopDemo.Catalog.Infraestructure --startup-project ShopDemo.Catalog.Api` |

**Instalar EF tools (una sola vez):**

```bash
dotnet tool install --global dotnet-ef
dotnet ef --version
```

---

## Pruebas

| Comando | Descripción | Ejemplo |
|---|---|---|
| `dotnet new xunit` | Crea proyecto de pruebas | `dotnet new xunit -n ShopDemo.Catalog.Tests` |
| `dotnet test` | Ejecuta pruebas | `dotnet test Source/ShopDemo.slnx` |
| `dotnet test --filter` | Filtra pruebas por nombre | `dotnet test --filter "FullyQualifiedName~CreateProduct"` |
| `dotnet test --collect` | Recopila cobertura de código | `dotnet test --collect:"XPlat Code Coverage"` |

---

## Usuarios y secretos (desarrollo local)

| Comando | Descripción | Ejemplo |
|---|---|---|
| `dotnet user-secrets init` | Habilita secretos de usuario | `dotnet user-secrets init --project ShopDemo.Catalog.Api` |
| `dotnet user-secrets set` | Guarda un secreto local | `dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Host=localhost;..." --project ShopDemo.Catalog.Api` |
| `dotnet user-secrets list` | Lista secretos configurados | `dotnet user-secrets list --project ShopDemo.Catalog.Api` |

---

## Comandos útiles en el día a día

```bash
# Verificar que todo compila antes de un commit
dotnet build Source/ShopDemo.slnx

# Ejecutar un microservicio específico
dotnet run --project ShopDemo.Catalog.Api --urls "http://localhost:8001"

# Ver dependencias de un proyecto
dotnet list ShopDemo.Catalog.Api package --include-transitive

# Formato de código (si se usa dotnet format)
dotnet format Source/ShopDemo.slnx
```

---

## Atajos por capa (ShopDemo)

| Capa | Proyecto | Comando típico |
|---|---|---|
| API | `ShopDemo.Catalog.Api` | `dotnet run --project ShopDemo.Catalog.Api` |
| Application | `ShopDemo.Catalog.Application` | `dotnet build ShopDemo.Catalog.Application` |
| Domain | `ShopDemo.Catalog.Domain` | `dotnet build ShopDemo.Catalog.Domain` |
| Infrastructure | `ShopDemo.Catalog.Infraestructure` | `dotnet ef database update --project ... --startup-project ...` |

---

## Recursos

- [Documentación oficial .NET CLI](https://learn.microsoft.com/dotnet/core/tools/)
- [Entity Framework Core CLI](https://learn.microsoft.com/ef/core/cli/dotnet)
