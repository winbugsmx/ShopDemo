# Cheat Sheet — Git CLI

Referencia rápida de comandos `git` para trabajo colaborativo en proyectos de microservicios. Ejemplos aplicables al repositorio **ShopDemo**.

---

## Configuración inicial

| Comando | Descripción | Ejemplo |
|---|---|---|
| `git init` | Inicializa un repositorio local | `git init` |
| `git clone` | Clona un repositorio remoto | `git clone https://github.com/org/ShopDemo.git` |
| `git config user.name` | Define nombre del autor | `git config user.name "Tu Nombre"` |
| `git config user.email` | Define email del autor | `git config user.email "tu@email.com"` |
| `git remote -v` | Muestra remotos configurados | `git remote -v` |

---

## Estado y exploración

| Comando | Descripción | Ejemplo |
|---|---|---|
| `git status` | Estado del working tree | `git status` |
| `git log` | Historial de commits | `git log --oneline -10` |
| `git log --graph` | Historial con ramificación visual | `git log --oneline --graph --all` |
| `git diff` | Cambios no staged | `git diff` |
| `git diff --staged` | Cambios en staging | `git diff --staged` |
| `git show` | Detalle de un commit | `git show abc1234` |
| `git branch` | Lista ramas locales | `git branch` |
| `git branch -a` | Lista ramas locales y remotas | `git branch -a` |

**Ver qué cambió en un microservicio específico:**

```bash
git status ShopDemo.Catalog.Api/
git diff ShopDemo.Catalog.Application/
git log --oneline -- ShopDemo.Catalog.Domain/
```

---

## Ramas (flujo de trabajo)

| Comando | Descripción | Ejemplo |
|---|---|---|
| `git branch` | Crea una rama | `git branch feature/catalog-create-product` |
| `git checkout` | Cambia de rama | `git checkout feature/catalog-create-product` |
| `git switch` | Cambia de rama (moderno) | `git switch -c feature/orders-api` |
| `git merge` | Fusiona una rama en la actual | `git merge feature/catalog-create-product` |
| `git branch -d` | Elimina rama fusionada | `git branch -d feature/catalog-create-product` |

**Flujo típico por feature de microservicio:**

```bash
git switch main
git pull origin main
git switch -c feature/catalog-infrastructure
# ... desarrollar ...
git add .
git commit -m "Add EF Core persistence for Catalog service"
git push -u origin feature/catalog-infrastructure
```

---

## Staging y commits

| Comando | Descripción | Ejemplo |
|---|---|---|
| `git add` | Agrega archivos al staging | `git add ShopDemo.Catalog.Api/Program.cs` |
| `git add .` | Agrega todos los cambios | `git add .` |
| `git add -p` | Agrega cambios interactivamente | `git add -p` |
| `git commit` | Crea un commit | `git commit -m "Wire up CreateProduct endpoint"` |
| `git commit -am` | Add + commit (solo archivos tracked) | `git commit -am "Fix domain event OccurredOn type"` |
| `git restore` | Descarta cambios locales | `git restore ShopDemo.Catalog.Api/Program.cs` |
| `git restore --staged` | Quita del staging | `git restore --staged .` |

**Buenas prácticas de commit en microservicios:**

```bash
# Un commit por contexto o capa cuando sea posible
git add ShopDemo.Catalog.Domain/
git commit -m "Add Product aggregate with domain events"

git add ShopDemo.Catalog.Infraestructure/
git commit -m "Implement ProductRepository with EF Core"

git add ShopDemo.Catalog.Api/
git commit -m "Expose POST /api/products endpoint"
```

---

## Remotos (push / pull)

| Comando | Descripción | Ejemplo |
|---|---|---|
| `git remote add` | Agrega un remoto | `git remote add origin https://github.com/org/ShopDemo.git` |
| `git fetch` | Descarga cambios sin fusionar | `git fetch origin` |
| `git pull` | Fetch + merge | `git pull origin main` |
| `git push` | Sube commits al remoto | `git push origin feature/catalog-api` |
| `git push -u` | Push y establece upstream | `git push -u origin feature/catalog-api` |

---

## Deshacer cambios

| Comando | Descripción | Ejemplo |
|---|---|---|
| `git restore` | Descarta cambios en archivo | `git restore archivo.cs` |
| `git reset --soft` | Deshace commit, mantiene cambios staged | `git reset --soft HEAD~1` |
| `git reset --mixed` | Deshace commit y unstage | `git reset HEAD~1` |
| `git reset --hard` | Deshace commit y descarta cambios | `git reset --hard HEAD~1` |
| `git revert` | Crea commit que revierte otro | `git revert abc1234` |
| `git stash` | Guarda cambios temporalmente | `git stash push -m "WIP orders service"` |
| `git stash pop` | Recupera cambios guardados | `git stash pop` |

> **Precaución:** `git reset --hard` elimina cambios permanentemente. Úsalo solo cuando estés seguro.

---

## Tags y releases

| Comando | Descripción | Ejemplo |
|---|---|---|
| `git tag` | Lista tags | `git tag` |
| `git tag -a` | Crea tag anotado | `git tag -a v1.0.0 -m "Catalog service MVP"` |
| `git push --tags` | Sube tags al remoto | `git push origin --tags` |

**Versionar releases de microservicios:**

```bash
git tag -a catalog-v1.0.0 -m "Catalog API: CreateProduct flow"
git push origin catalog-v1.0.0
```

---

## .gitignore en proyectos .NET

Archivos que **no** deben versionarse en ShopDemo:

```
bin/
obj/
.vs/
*.user
appsettings.*.local.json
```

**Verificar si un archivo está siendo rastreado:**

```bash
git check-ignore -v ShopDemo.Catalog.Api/bin/
git status --ignored
```

---

## Flujos comunes del curso

### Sincronizar antes de trabajar

```bash
git switch main
git pull origin main
git switch -c feature/mi-cambio
```

### Preparar un Pull Request

```bash
git status
git diff
git add .
git commit -m "Implement Catalog infrastructure layer"
git push -u origin feature/mi-cambio
# Crear PR en GitHub/GitLab
```

### Resolver conflictos tras pull

```bash
git pull origin main
# Editar archivos con conflictos
git add .
git commit -m "Resolve merge conflicts in Catalog.Api"
```

### Ver historial de un archivo

```bash
git log --oneline -- ShopDemo.Catalog.Api/Program.cs
git blame ShopDemo.Catalog.Api/Program.cs
```

---

## Comandos avanzados útiles

| Comando | Descripción | Ejemplo |
|---|---|---|
| `git cherry-pick` | Aplica un commit específico | `git cherry-pick abc1234` |
| `git rebase` | Reaplica commits sobre otra rama | `git rebase main` |
| `git reflog` | Historial de movimientos de HEAD | `git reflog` |
| `git clean -fd` | Elimina archivos/directorios no rastreados | `git clean -fd` |

---

## Convenciones recomendadas

| Tipo de commit | Prefijo | Ejemplo |
|---|---|---|
| Nueva funcionalidad | `feat:` | `feat: add CreateProduct command handler` |
| Corrección | `fix:` | `fix: correct IDomainEvent OccurredOn type` |
| Refactor | `refactor:` | `refactor: extract ProductConfiguration` |
| Infraestructura | `chore:` | `chore: add docker-compose for catalog-db` |
| Documentación | `docs:` | `docs: add dotnet CLI cheat sheet` |

---

## Recursos

- [Documentación oficial Git](https://git-scm.com/doc)
- [Pro Git Book (español)](https://git-scm.com/book/es/v2)
