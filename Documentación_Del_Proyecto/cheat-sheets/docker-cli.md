# Cheat Sheet — Docker CLI

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

Referencia rápida de comandos `docker` y `docker compose` para containerizar microservicios .NET. Ejemplos basados en **ShopDemo.Catalog.Api**.

---

## Información del entorno

| Comando | Descripción | Ejemplo |
|---|---|---|
| `docker --version` | Versión de Docker | `docker --version` |
| `docker info` | Información del daemon | `docker info` |
| `docker compose version` | Versión de Docker Compose | `docker compose version` |

---

## Imágenes

| Comando | Descripción | Ejemplo |
|---|---|---|
| `docker build` | Construye una imagen desde Dockerfile | `docker build -t shopdemo-catalog:1.0 -f Source/Catalog/ShopDemo.Catalog.Api/Dockerfile Source` |
| `docker images` | Lista imágenes locales | `docker images` |
| `docker rmi` | Elimina una imagen | `docker rmi shopdemo-catalog:1.0` |
| `docker pull` | Descarga imagen del registry | `docker pull postgres:16-alpine` |
| `docker tag` | Etiqueta una imagen | `docker tag shopdemo-catalog:1.0 myregistry/shopdemo-catalog:1.0` |
| `docker push` | Sube imagen a un registry | `docker push myregistry/shopdemo-catalog:1.0` |

**Construir imagen del microservicio Catalog (desde la raíz del repo):**

```bash
cd I:\Curso\ShopDemo
docker build -t shopdemo-catalog:1.0 -f Source/Catalog/ShopDemo.Catalog.Api/Dockerfile Source
```

---

## Contenedores

| Comando | Descripción | Ejemplo |
|---|---|---|
| `docker run` | Crea y ejecuta un contenedor | `docker run -d -p 8001:8080 --name catalog-api shopdemo-catalog:1.0` |
| `docker ps` | Contenedores en ejecución | `docker ps` |
| `docker ps -a` | Todos los contenedores | `docker ps -a` |
| `docker stop` | Detiene un contenedor | `docker stop catalog-api` |
| `docker start` | Inicia un contenedor detenido | `docker start catalog-api` |
| `docker restart` | Reinicia un contenedor | `docker restart catalog-api` |
| `docker rm` | Elimina un contenedor | `docker rm catalog-api` |
| `docker logs` | Muestra logs del contenedor | `docker logs -f catalog-api` |
| `docker exec` | Ejecuta comando dentro del contenedor | `docker exec -it catalog-api /bin/sh` |

**Ejecutar Catalog.Api con variables de entorno:**

```bash
docker run -d \
  --name catalog-api \
  -p 8001:8080 \
  -e ASPNETCORE_ENVIRONMENT=Development \
  -e ConnectionStrings__DefaultConnection="Host=host.docker.internal;Port=5432;Database=ShopDemoCatalog;Username=ShopDemo;Password=ShopDemo123" \
  shopdemo-catalog:1.0
```

---

## Docker Compose (orquestación local)

| Comando | Descripción | Ejemplo |
|---|---|---|
| `docker compose up` | Levanta servicios definidos en compose | `docker compose up` |
| `docker compose up -d` | Levanta en segundo plano (detached) | `docker compose up -d` |
| `docker compose down` | Detiene y elimina contenedores/redes | `docker compose down` |
| `docker compose ps` | Estado de los servicios | `docker compose ps` |
| `docker compose logs` | Logs de todos los servicios | `docker compose logs -f catalog-service` |
| `docker compose build` | Construye imágenes del compose | `docker compose build` |
| `docker compose restart` | Reinicia un servicio | `docker compose restart catalog-service` |

**Levantar Catalog + PostgreSQL (ShopDemo):**

```bash
cd I:\Curso\ShopDemo\Source\Catalog\ShopDemo.Catalog.Api
docker compose up -d
```

Esto levanta:
- `catalog-db` — PostgreSQL 16 en puerto `5432`
- `catalog-service` — API en puerto `8001`

**Probar el endpoint:**

```bash
curl -X POST http://localhost:8001/api/products \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Laptop Pro\",\"description\":\"15 inch\",\"price\":1299.99,\"currency\":\"MXN\",\"stock\":50,\"category\":\"Electronics\"}"
```

---

## Redes y volúmenes

| Comando | Descripción | Ejemplo |
|---|---|---|
| `docker network ls` | Lista redes | `docker network ls` |
| `docker network inspect` | Detalle de una red | `docker network inspect shopdemocatalogapi_default` |
| `docker volume ls` | Lista volúmenes | `docker volume ls` |
| `docker volume inspect` | Detalle de un volumen | `docker volume inspect catalog-db-data` |
| `docker volume prune` | Elimina volúmenes no usados | `docker volume prune` |

> En `docker-compose.yml` de ShopDemo, el volumen `catalog-db-data` persiste los datos de PostgreSQL entre reinicios.

---

## Limpieza

| Comando | Descripción | Ejemplo |
|---|---|---|
| `docker system df` | Espacio usado por Docker | `docker system df` |
| `docker container prune` | Elimina contenedores detenidos | `docker container prune` |
| `docker image prune` | Elimina imágenes sin usar | `docker image prune` |
| `docker system prune` | Limpieza general | `docker system prune -a` |

> **Precaución:** `docker system prune -a` elimina todas las imágenes no usadas.

---

## Inspección y depuración

| Comando | Descripción | Ejemplo |
|---|---|---|
| `docker inspect` | Metadata JSON del contenedor/imagen | `docker inspect catalog-api` |
| `docker stats` | Uso de CPU/RAM en tiempo real | `docker stats` |
| `docker top` | Procesos dentro del contenedor | `docker top catalog-api` |
| `docker cp` | Copia archivos hacia/desde contenedor | `docker cp catalog-api:/app/appsettings.json ./` |

**Ver logs de la API y la base de datos:**

```bash
docker compose logs -f catalog-service
docker compose logs -f catalog-db
```

**Conectarse a PostgreSQL dentro del contenedor:**

```bash
docker exec -it shopdemocatalogapi-catalog-db-1 psql -U ShopDemo -d ShopDemoCatalog
```

---

## Multi-stage builds (.NET)

El `Dockerfile` de ShopDemo usa build multi-etapa:

```dockerfile
# Etapas: base → build → publish → final
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
# ... restore, build, publish ...
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
# ... solo el artefacto publicado ...
```

**Ventajas:**
- Imagen final pequeña (solo runtime, sin SDK)
- Mejor cache de capas al copiar `.csproj` primero
- Usuario no-root (`USER app`) por seguridad

---

## Variables de entorno en .NET + Docker

ASP.NET Core mapea variables con doble guion bajo (`__`):

| appsettings.json | Variable de entorno Docker |
|---|---|
| `ConnectionStrings:DefaultConnection` | `ConnectionStrings__DefaultConnection` |
| `Logging:LogLevel:Default` | `Logging__LogLevel__Default` |

**En docker-compose.yml:**

```yaml
environment:
  - ASPNETCORE_ENVIRONMENT=Development
  - ConnectionStrings__DefaultConnection=Host=catalog-db;Port=5432;Database=ShopDemoCatalog;Username=ShopDemo;Password=ShopDemo123
```

---

## Flujos comunes del curso

### Desarrollo local con contenedores

```bash
# 1. Solo la base de datos
docker compose up -d catalog-db

# 2. API en local con dotnet run (más rápido para debug)
dotnet run --project ShopDemo.Catalog.Api

# 3. Todo containerizado
docker compose up -d --build
```

### Reconstruir tras cambios en código

```bash
docker compose down
docker compose up -d --build
```

### Publicar imagen para Kubernetes

```bash
docker build -t myregistry.azurecr.io/shopdemo-catalog:1.0 -f Source/Catalog/ShopDemo.Catalog.Api/Dockerfile Source
docker push myregistry.azurecr.io/shopdemo-catalog:1.0
```

---

## Dockerfile vs docker-compose — responsabilidades

| Archivo | Responsabilidad |
|---|---|
| `Dockerfile` | Cómo construir la imagen de **un** servicio |
| `docker-compose.yml` | Cómo orquestar **varios** servicios (API + BD + red + volúmenes) |

---

## Recursos

- [Docker CLI reference](https://docs.docker.com/reference/cli/docker/)
- [Docker Compose reference](https://docs.docker.com/reference/compose-file/)
- [Containerizar apps ASP.NET Core](https://learn.microsoft.com/aspnet/core/host-and-deploy/docker/)
