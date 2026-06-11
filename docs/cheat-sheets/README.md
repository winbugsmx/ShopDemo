# Cheat Sheets — Curso de Microservicios con .NET

Material de referencia rápida para complementar el curso de microservicios usando **.NET**, **Docker** y **Kubernetes**, basado en la solución **ShopDemo**.

---

## Documentos disponibles

| Documento | Herramienta | Contenido principal |
|---|---|---|
| [dotnet-cli.md](./dotnet-cli.md) | `dotnet` CLI | Compilar, ejecutar, paquetes NuGet, EF Core, publicar |
| [git-cli.md](./git-cli.md) | `git` CLI | Ramas, commits, remotos, flujo de PR, convenciones |
| [docker-cli.md](./docker-cli.md) | `docker` / `docker compose` | Imágenes, contenedores, compose, variables de entorno |
| [kubernetes-cli.md](./kubernetes-cli.md) | `kubectl` | Deployments, Services, Secrets, Ingress, depuración |

---

## Flujo de trabajo del curso

```
1. Desarrollo local     → dotnet CLI
2. Control de versiones → git CLI
3. Containerización     → docker CLI
4. Orquestación cloud   → kubernetes CLI
```

### Ejemplo: ciclo completo de un microservicio

```bash
# 1. Desarrollar y probar localmente
dotnet run --project ShopDemo.Catalog.Api

# 2. Versionar cambios
git add .
git commit -m "feat: add Catalog API endpoint"
git push -u origin feature/catalog-api

# 3. Containerizar
docker build -t shopdemo-catalog:1.0 -f ShopDemo.Catalog.Api/Dockerfile .
docker compose up -d

# 4. Desplegar en Kubernetes
kubectl apply -f k8s/catalog/
kubectl rollout status deployment/catalog-api
```

---

## Documentación relacionada

- [Arquitectura de ShopDemo](../ARQUITECTURA.md)

---

## Entorno recomendado

| Herramienta | Versión mínima sugerida |
|---|---|
| .NET SDK | 10.0 |
| Git | 2.40+ |
| Docker Desktop | 4.x |
| Kubernetes (kubectl) | 1.28+ |
| Entity Framework Tools | `dotnet-ef` 10.x |
