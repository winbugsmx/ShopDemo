# 07 — Contenedores y Docker

## Objetivo de este capítulo

Comprender **qué es un contenedor**, cómo **Docker** empaqueta aplicaciones .NET en imágenes inmutables, cómo ejecutarlas en local con `docker run` y `docker compose`, y cómo publicarlas en un **registro** (ACR, ECR, Docker Hub) antes de orquestarlas con Kubernetes (capítulo 08).

Asumimos que sabes C#, HTTP, SQL y has leído los capítulos de cloud (05–06). Aquí aprendes la capa **inmediatamente debajo** de AKS, EKS, ECS Fargate y Container Apps: el contenedor como unidad de despliegue.

Conceptos que dominarás:

- Contenedor vs máquina virtual: aislamiento, portabilidad y eficiencia.
- Imagen, capas, Dockerfile multi-stage para .NET.
- Comandos esenciales: `build`, `run`, `push`, `compose`.
- Redes, volúmenes, variables de entorno y secretos en contenedores.
- Registros de imágenes y buenas prácticas de seguridad.

> **Cómo leer este capítulo:** cada sección sigue definición → explicación → ejemplo comentado → cuándo usarlo. Practica los comandos en tu máquina; la teoría sin `docker build` no se fija.

---

## 1. ¿Qué problema resuelven los contenedores?

### Definición formal

Un **contenedor** es un proceso aislado que ejecuta una aplicación empaquetada junto con sus dependencias de runtime, usando el kernel del sistema operativo anfitrión y mecanismos de aislamiento (namespaces, cgroups), sin incluir un sistema operativo completo como una máquina virtual.

### Explicación desarrollada

El problema clásico: "en mi máquina funciona". En desarrollo tienes .NET 10, PostgreSQL 16 y variables de entorno concretas; en producción hay otra versión, otro SO o rutas distintas. Los contenedores fijan **qué corre** y **con qué dependencias**, de forma repetible.

Comparación mental:

| Aspecto | Máquina virtual (VM) | Contenedor |
|---|---|---|
| Aislamiento | SO completo por VM | Proceso aislado, kernel compartido |
| Arranque | Minutos | Segundos |
| Tamaño | GB (disco + SO) | MB (solo app + runtime) |
| Portabilidad | Imagen de disco pesada | Imagen OCI estándar |
| Uso típico | Legacy, control total del SO | Microservicios, APIs, workers |

Para un desarrollador C#: un contenedor es "tu `dotnet Orders.Api.dll` + runtime ASP.NET + librerías del sistema necesarias", ejecutándose igual en laptop, pipeline CI y clúster Kubernetes.

### Cuándo usar contenedores

| Usa contenedores cuando… | Evita contenedores cuando… |
|---|---|
| Despliegas APIs .NET en cloud (AKS, EKS, Fargate, ACA) | App monolítica simple en App Service sin necesidad de empaquetado |
| Quieres paridad dev/prod ("misma imagen en todos lados") | Prototipo de una tarde en local sin despliegue |
| Necesitas escalar réplicas idénticas | Software que no puede containerizarse (drivers kernel raros) |

---

## 2. Imágenes, capas y el estándar OCI

### Definición formal

Una **imagen de contenedor** es un artefacto **inmutable** y **en capas** que describe el sistema de archivos y metadatos (comando de arranque, variables, puertos) necesarios para crear contenedores. El estándar **OCI (Open Container Initiative)** define el formato interoperable entre Docker, containerd, Podman y registros cloud.

### Explicación desarrollada

Piensa en la imagen como una **fotografía congelada** de tu app lista para ejecutar:

- Cada instrucción del `Dockerfile` (`FROM`, `COPY`, `RUN`) suele crear una **capa** reutilizable.
- Si cambias solo tu DLL, Docker reutiliza capas anteriores y reconstruye solo lo necesario (build más rápido).
- Un **contenedor** es una **instancia en ejecución** de una imagen (como un objeto instanciado de una clase).

Vocabulario esencial:

| Término | Significado |
|---|---|
| **Image** | Plantilla inmutable (`orders-api:1.2.0`) |
| **Container** | Proceso vivo creado desde una imagen |
| **Registry** | Almacén remoto de imágenes (ACR, ECR, Docker Hub) |
| **Repository** | Nombre lógico de imagen (`shopdemo/orders-api`) |
| **Tag** | Versión (`latest`, `v1`, `sha-abc123`) |

### Cuándo versionar imágenes con tags

| Práctica | Por qué |
|---|---|
| Tag `latest` solo en dev | Producción debe usar tag inmutable (`v1.4.2`, digest SHA) |
| Tag por commit Git | Trazabilidad: saber qué código corre en prod |
| No reutilizar tag sobre imagen distinta | Evita despliegues impredecibles |

---

## 3. Dockerfile para ASP.NET Core

### Definición formal

Un **Dockerfile** es un archivo declarativo de instrucciones que describe cómo construir una imagen de contenedor, típicamente en fases (**multi-stage**) que separan compilación de ejecución.

### Explicación desarrollada

El patrón **multi-stage** es estándar en .NET:

1. **Stage `build`:** SDK completo, `dotnet restore` + `dotnet publish`.
2. **Stage final:** solo runtime ASP.NET, copia del artefacto publicado — imagen más pequeña y sin compilador en producción.

**Ejemplo en C# / Dockerfile (comentado):**

```dockerfile
# Stage 1: compilar con el SDK (imagen grande, solo para build)
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
# Copiar csproj primero aprovecha cache de capas en restore
COPY ["Orders.Api/Orders.Api.csproj", "Orders.Api/"]
RUN dotnet restore "Orders.Api/Orders.Api.csproj"
COPY . .
WORKDIR /src/Orders.Api
RUN dotnet publish -c Release -o /app/publish /p:UseAppHost=false

# Stage 2: runtime mínimo para ejecutar la API
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
# Usuario no-root reduce superficie de ataque si el contenedor se compromete
USER $APP_UID
COPY --from=build /app/publish .
# Puerto que escucha Kestrel dentro del contenedor
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "Orders.Api.dll"]
```

Qué hace cada bloque:

- `FROM ... AS build` — define etapa temporal de compilación.
- `COPY csproj` + `restore` — capa cacheable; acelera rebuilds si solo cambia código.
- `publish` — genera carpeta autocontenida lista para runtime.
- `FROM aspnet` — imagen final sin SDK (~200 MB menos que incluir compilador).
- `USER` — evita ejecutar como root en producción.
- `ENTRYPOINT` — comando fijo al arrancar el contenedor.

### Cuándo usar multi-stage

Siempre en APIs .NET de producción. Evita imágenes de un solo stage con SDK completo salvo en entornos de depuración temporal.

---

## 4. Comandos esenciales de Docker

### Definición formal

La **CLI de Docker** construye imágenes, crea contenedores, gestiona redes y volúmenes, y publica o descarga imágenes desde registros remotos.

### Explicación desarrollada

Flujo mínimo de un desarrollador backend:

```bash
# 1. Construir imagen desde Dockerfile en el directorio actual
docker build -t orders-api:local .

# 2. Ejecutar contenedor: mapea puerto host 5080 → 8080 del contenedor
docker run --rm -p 5080:8080 \
  -e ConnectionStrings__Default="Host=host.docker.internal;..." \
  --name orders orders-api:local

# 3. Ver contenedores activos y logs
docker ps
docker logs -f orders

# 4. Publicar en registro (tras login)
docker tag orders-api:local myacr.azurecr.io/orders-api:v1
docker push myacr.azurecr.io/orders-api:v1
```

Comandos útiles adicionales:

| Comando | Función |
|---|---|
| `docker images` | Lista imágenes locales |
| `docker stop <id>` | Detiene contenedor |
| `docker exec -it <id> /bin/sh` | Shell dentro del contenedor (diagnóstico) |
| `docker inspect <id>` | Metadatos JSON (red, env, mounts) |
| `docker system prune` | Limpia imágenes/contenedores huérfanos (cuidado en CI) |

### Cuándo usar `docker run` vs `docker compose`

| `docker run` | `docker compose` |
|---|---|
| Probar una imagen aislada | Levantar API + PostgreSQL + Redis juntos |
| Scripts rápidos de demo | Entorno dev reproducible en equipo |
| CI que ejecuta un solo servicio | Paridad con `docker-compose.yml` del repo |

---

## 5. Docker Compose: varios servicios en local

### Definición formal

**Docker Compose** es una herramienta para definir y ejecutar aplicaciones **multi-contenedor** mediante un archivo YAML (`compose.yaml`), declarando servicios, redes, volúmenes y variables de entorno.

### Explicación desarrollada

Un microservicio rara vez vive solo en local: necesita base de datos, cache o un bus de mensajes. Compose orquesta ese conjunto **sin Kubernetes**.

**Ejemplo comentado (`compose.yaml`):**

```yaml
services:
  orders-api:
    build: ./Orders.Api          # Construye desde Dockerfile local
    ports:
      - "5080:8080"              # Expone API al host
    environment:
      ASPNETCORE_ENVIRONMENT: Development
      ConnectionStrings__Default: Host=postgres;Database=orders;Username=app;Password=secret
    depends_on:
      - postgres                 # Orden de arranque (no garantiza "listo")
    networks:
      - backend

  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: orders
    volumes:
      - pgdata:/var/lib/postgresql/data   # Persistencia entre reinicios
    networks:
      - backend

volumes:
  pgdata:                            # Volumen nombrado gestionado por Docker

networks:
  backend:                           # Red privada entre servicios
```

Qué hace cada bloque:

- `services` — define cada contenedor (API, BD).
- `build` vs `image` — construir localmente o usar imagen pública.
- `depends_on` — arranca postgres antes que orders (para readiness real, usa healthcheck).
- `volumes` — datos de BD sobreviven a `docker compose down`.
- `networks` — DNS interno: `postgres` resuelve al contenedor de BD.

Comandos:

```bash
docker compose up --build -d    # Levanta en segundo plano
docker compose logs -f orders-api
docker compose down             # Detiene y elimina contenedores (volumen pgdata persiste)
```

### Cuándo usar Compose

| Usa Compose cuando… | Pasa a Kubernetes cuando… |
|---|---|
| Desarrollo local del equipo | Necesitas réplicas, rollouts, autoscaling en prod |
| Integración manual pre-CI | Despliegue multi-nodo con self-healing |
| Prototipo de 2–5 servicios | Operación formal con Helm/GitOps |

---

## 6. Redes y conectividad

### Definición formal

Las **redes Docker** permiten que contenedores se comuniquen por DNS interno; el **mapeo de puertos** (`-p`) expone servicios del contenedor al host o a internet.

### Explicación desarrollada

Modos relevantes:

| Modo | Comportamiento |
|---|---|
| **bridge** (default) | Red privada Docker; contenedores se ven por nombre |
| **host** | Contenedor usa red del host directamente (menos aislamiento) |
| **none** | Sin red (procesos aislados) |

Patrones para .NET:

- **API → BD en Compose:** hostname = nombre del servicio (`postgres`, no `localhost`).
- **API → servicio en el host:** `host.docker.internal` (Windows/Mac; en Linux puede requerir flag extra).
- **Producción en K8s:** Compose no aplica; Kubernetes Service + Ingress reemplazan este modelo (capítulo 08).

### Cuándo exponer puertos

Solo expone al host (`ports:`) lo que necesitas probar desde el navegador o Postman. Bases de datos y colas suelen quedarse **solo en red interna**.

---

## 7. Volúmenes y persistencia

### Definición formal

Un **volumen Docker** es almacenamiento gestionado por Docker **fuera** del sistema de archivos efímero del contenedor, usado para persistir datos (bases de datos, archivos subidos) o montar configuración.

### Explicación desarrollada

Sin volumen, al eliminar el contenedor de PostgreSQL **se pierden los datos**. Tipos:

| Tipo | Uso |
|---|---|
| **Named volume** | Datos de BD, uploads persistentes |
| **Bind mount** | Montar carpeta del host (`./appsettings.Development.json`) — útil en dev |
| **tmpfs** | Datos volátiles en RAM (secretos efímeros) |

En producción cloud, los volúmenes del orquestador (Azure Disk, EBS, PVC en K8s) cumplen el mismo rol a mayor escala.

### Cuándo usar bind mount

Solo desarrollo local para hot-reload o config local. En producción, preferir variables de entorno, secret stores (Key Vault, Secrets Manager) e imágenes inmutables.

---

## 8. Variables de entorno y secretos

### Definición formal

Las **variables de entorno** inyectan configuración en el contenedor en tiempo de ejecución; en ASP.NET Core se mapean a `IConfiguration` con doble guion bajo (`ConnectionStrings__Default`).

### Explicación desarrollada

Jerarquía de configuración en contenedores .NET:

1. `appsettings.json` (dentro de la imagen — valores no secretos).
2. Variables de entorno (sobrescriben JSON).
3. Secretos montados como archivos o variables (Key Vault, Docker secrets).

**Ejemplo:**

```bash
docker run -e ASPNETCORE_ENVIRONMENT=Production \
  -e ConnectionStrings__Default="Server=sql;..." \
  -e ApplicationInsights__ConnectionString="..." \
  orders-api:v1
```

Reglas de seguridad:

- **Nunca** bakear passwords en la imagen (`ENV DB_PASSWORD=...` en Dockerfile).
- En CI/CD, inyectar secretos desde el pipeline (GitHub Secrets, OIDC a Key Vault).
- `.dockerignore` excluye `bin/`, `obj/`, `.git`, archivos locales con credenciales.

**Ejemplo `.dockerignore`:**

```
**/bin/
**/obj/
**/.vs/
.git/
*.user
appsettings.Development.json
```

---

## 9. Registros de imágenes (ACR, ECR, Docker Hub)

### Definición formal

Un **registro de contenedores** es un repositorio remoto que almacena, versiona y distribuye imágenes OCI, con control de acceso y escaneo de vulnerabilidades opcional.

### Explicación desarrollada

Flujo típico hacia cloud (capítulos 05–06):

```
Código → docker build → docker push → ACR/ECR → AKS/EKS/Fargate/ACA pull → ejecuta
```

| Registro | Contexto |
|---|---|
| **Docker Hub** | Público; imágenes base (`postgres`, `redis`); rate limits en free |
| **Azure Container Registry (ACR)** | Privado en Azure; integración AKS, ACA, GitHub Actions |
| **Amazon ECR** | Privado en AWS; integración EKS, ECS, CodePipeline |

Autenticación habitual:

```bash
# Azure
az acr login --name myacr
docker push myacr.azurecr.io/orders-api:v1

# AWS
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/orders-api:v1
```

### Cuándo usar registro privado

Siempre en producción y CI empresarial. Imágenes con código propietario no deben publicarse en Docker Hub público.

---

## 10. Seguridad y buenas prácticas

### Definición formal

**Hardening de contenedores** reduce la superficie de ataque mediante imágenes mínimas, usuario no privilegiado, escaneo de vulnerabilidades y principio de mínimo privilegio en runtime.

### Explicación desarrollada

Checklist para APIs .NET:

| Práctica | Beneficio |
|---|---|
| Imagen `aspnet` (no `sdk`) en runtime | Menor tamaño y menos herramientas expuestas |
| Usuario no-root (`USER $APP_UID`) | Limita daño si hay RCE |
| Actualizar base image regularmente | Parches de seguridad del SO/runtime |
| Escanear con `docker scout` / Trivy / ACR tasks | Detectar CVEs antes de desplegar |
| Read-only filesystem donde sea posible | Evita escritura arbitraria en disco |
| Límites CPU/memoria (`--memory`, en K8s `resources`) | Evita que un contenedor agote el nodo |

### Cuándo escanear imágenes

En cada pipeline CI después de `docker build` y antes de `docker push`. Bloquear despliegue si hay CVEs críticos sin mitigación.

---

## 11. Contenedores vs orquestación (puente al capítulo 08)

### Definición formal

**Orquestación de contenedores** automatiza el despliegue, escalado, red y recuperación de muchos contenedores en un clúster; **Docker solo** gestiona uno o pocos contenedores en un host.

### Explicación desarrollada

Docker resuelve: "ejecuta **esta** imagen aquí". Kubernetes resuelve: "mantén **3 réplicas** de esta imagen, reinicia si fallan, despliega v2 sin downtime, balancea tráfico".

| Capacidad | Docker / Compose | Kubernetes |
|---|---|---|
| Un servicio local | Sí | Overkill |
| Self-healing multi-nodo | No | Sí |
| Rolling update sin downtime | Manual | Nativo (Deployment) |
| Autoscaling por CPU | No | Sí (HPA) |
| Service discovery entre 20 APIs | Limitado | Sí (Service, DNS) |

Los servicios cloud de capítulos 05–06 consumen imágenes Docker pero añaden su capa de orquestación:

- **AKS / EKS** — Kubernetes completo.
- **ECS Fargate / Container Apps** — orquestación gestionada sin administrar clúster.

---

## 12. Resumen del capítulo

- Un **contenedor** empaqueta app + runtime con aislamiento ligero; una **imagen** es la plantilla inmutable.
- **Dockerfile multi-stage** separa compilación (.NET SDK) de ejecución (ASP.NET runtime) — imágenes más pequeñas y seguras.
- **`docker build` / `run` / `push`** cubren el ciclo local → registro; **Compose** levanta stacks multi-servicio en desarrollo.
- **Redes y volúmenes** conectan APIs con BD y persisten datos; **variables de entorno** configuran sin recompilar.
- **ACR y ECR** almacenan imágenes privadas para despliegue en Azure y AWS.
- **Seguridad:** usuario no-root, `.dockerignore`, escaneo de CVEs, sin secretos en la imagen.
- **Kubernetes** (siguiente capítulo) orquesta contenedores a escala; Docker es el prerrequisito práctico.

**Siguiente paso:** capítulo 08 — **Kubernetes**: cómo el orquestador gestiona pods, despliegues, servicios y escalado de las imágenes que construiste aquí.
