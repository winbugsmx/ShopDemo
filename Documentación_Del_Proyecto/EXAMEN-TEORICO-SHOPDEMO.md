# Examen teórico — ShopDemo

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Modalidad** | Teórico · opción múltiple · escenarios · nivel básico |

**Material de estudio:** [README.md](../README.md) · [GUIA-ENDPOINTS.md](./GUIA-ENDPOINTS.md) · [RETO-TECNICO-SHOPDEMO.md](./RETO-TECNICO-SHOPDEMO.md)

---

## Instrucciones

- El examen tiene **10 escenarios** en orden progresivo: desde la creación de microservicios hasta el despliegue en la nube.
- Lee cada situación y elige la **mejor acción o conclusión** (A, B, C o D).
- Solo una opción es correcta por pregunta.
- Las respuestas correctas están al final (sección para el instructor).

---

## Escenarios

### Escenario 1 — Primer microservicio

María empieza el ejercicio y debe implementar el servicio que **da de alta productos** en la tienda. Su compañero le dice que en Inventory ya usaron puertos, adaptadores y casos de uso en lugar de MediatR. María debe entregar Catalog.

**¿Qué enfoque corresponde al microservicio que está construyendo María?**

- A) Arquitectura hexagonal, igual que Inventory  
- B) Clean Architecture + CQRS con MediatR  
- C) Solo un script SQL sin API  
- D) MCP Gateway en el puerto 8005  

---

### Escenario 2 — Alta de producto y venta

Un alumno creó un teclado mecánico con `POST /api/products` en Catalog y obtuvo un `productId`. Quiere probar de inmediato un pedido con 2 unidades, pero **Event Hubs está desactivado** y aún no tocó Inventory.

**¿Qué le falta hacer antes de confirmar el pedido?**

- A) Registrar stock en Inventory con `POST /api/inventory/stock`  
- B) Desplegar primero en Azure Container Apps  
- C) Ejecutar `kubectl apply -f k8s/` en Minikube  
- D) Nada; Orders crea el stock solo  

---

### Escenario 3 — Arranque en local

Pedro levantó Orders con Docker Compose, pero al crear un pedido recibe error porque no alcanza Inventory. Catalog aún no lo ha iniciado.

**¿Qué orden de arranque debería haber seguido en local?**

- A) Orders → Analytics → Catalog → Inventory  
- B) Catalog → Inventory → Orders (Analytics opcional después)  
- C) Solo MCP Gateway en el puerto 8005  
- D) Cualquier orden sirve si Docker Desktop está abierto  

---

### Escenario 4 — Confirmación de pedido

Laura confirma un pedido en Orders con `POST /api/orders/{id}/confirm`. El pedido pasa a estado **Confirmed** y el producto tenía stock suficiente.

**¿Qué ocurre detrás sin que Laura llame manualmente a Inventory?**

- A) Catalog descuenta el stock del catálogo y cancela el pedido  
- B) Orders llama por HTTP a Inventory para reservar las unidades  
- C) Analytics reserva el stock consumiendo Event Hubs  
- D) El MCP Gateway ejecuta la reserva automáticamente  

---

### Escenario 5 — Event Hubs activo

El equipo activó Azure Event Hubs. Jorge crea un producto en Catalog y, unos segundos después, consulta `GET /api/inventory/{productId}` **sin** llamar a `POST /api/inventory/stock`.

**¿Qué es lo más probable que observe si la integración está bien configurada?**

- A) Error 404 porque Inventory no escucha eventos  
- B) Ya existe stock registrado para ese productId  
- C) El pedido se confirma solo en Orders  
- D) Aspire despliega el MCP Gateway en AWS  

---

### Escenario 6 — Desarrollo integrado en la PC

Ana no quiere abrir cuatro terminales con Docker Compose. Necesita Catalog, Orders, Inventory y Analytics en local, con PostgreSQL y la configuración de Event Hubs centralizada para probar `GET /api/analytics/events`.

**¿Qué opción del curso le conviene usar?**

- A) `dotnet run --project Source/Aspire/ShopDemo.AppHost`  
- B) Publicar directo en Amazon EKS  
- C) Editar solo el archivo `.gitignore`  
- D) Importar Postman sin levantar ningún servicio  

---

### Escenario 7 — Empaquetar para la nube

El equipo terminó la API de Inventory y el instructor pide prepararla para subirla a un registro de contenedores antes del release.

**¿Qué artefactos del repositorio ShopDemo usa normalmente este microservicio?**

- A) Un `Dockerfile` y su `docker-compose.yml` en la carpeta de la API  
- B) Solo el Explorador de soluciones de Visual Studio, sin Docker  
- C) Un único PostgreSQL compartido sin contenedor para todas las APIs  
- D) El AppHost Aspire desplegado en producción  

---

### Escenario 8 — Release en Azure

Carlos hizo `docker build` de las cinco imágenes (Catalog, Orders, Inventory, Analytics y MCP). Su objetivo es publicarlas en **Azure** y luego crear Container Apps.

**¿Dónde debe subir las imágenes primero?**

- A) Azure Container Registry (ACR)  
- B) Amazon ECR  
- C) La colección Postman del curso  
- D) GitHub Issues del repositorio  

---

### Escenario 9 — Release en AWS con mensajería

El mismo sistema se despliega en **AWS ECS Fargate**, pero el bus de eventos sigue siendo **Azure Event Hubs**, como en el código del curso.

**¿Qué condición debe cumplir la red o la configuración del entorno AWS?**

- A) Bloquear todo acceso HTTPS a internet  
- B) Permitir que los contenedores salgan por HTTPS hacia Azure (Event Hubs)  
- C) Eliminar Analytics porque no funciona en AWS  
- D) Reemplazar PostgreSQL por archivos `.env` en el repositorio  

---

### Escenario 10 — Validar en Kubernetes y nube

Diana desplegó ShopDemo en Minikube usando la carpeta `k8s/`. Más adelante el mismo equipo quiere repetir el despliegue en AKS y EKS, y validar que las APIs responden antes de ejecutar el flujo de compra en Postman.

**¿Qué combinación de acciones es la más adecuada según el ejercicio?**

- A) Usar recursos compartidos `k8s/` + deployments en `k8s/azure/` o `k8s/aws/`; verificar `/health` y luego la carpeta **Flujo integrado (E2E)** en Postman  
- B) Crear manifiestos nuevos desde cero; no usar Postman en nube  
- C) Desplegar solo MCP y omitir Catalog, Orders e Inventory  
- D) Probar únicamente Swagger; Ingress y health no aplican  

---

## Hoja de respuestas (para el alumno)

| Escenario | Tu respuesta (A/B/C/D) |
|---|---|
| 1 | |
| 2 | |
| 3 | |
| 4 | |
| 5 | |
| 6 | |
| 7 | |
| 8 | |
| 9 | |
| 10 | |

---

## Clave de respuestas (para el instructor)

| # | Correcta | Tema del escenario |
|---|---|---|
| 1 | **B** | Catalog: Clean + CQRS |
| 2 | **A** | Flujo E2E sin Event Hubs |
| 3 | **B** | Orden de arranque local |
| 4 | **B** | Orders → Inventory por HTTP |
| 5 | **B** | Auto-stock con Event Hubs |
| 6 | **A** | Aspire AppHost en local |
| 7 | **A** | Docker por microservicio |
| 8 | **A** | ACR en Azure |
| 9 | **B** | Event Hubs cross-cloud desde AWS |
| 10 | **A** | `k8s/` multientorno + health + Postman E2E |

**Puntuación sugerida:** 1 punto por escenario · **Aprobatorio:** 7/10 (70 %) · **Excelente:** 9/10 (90 %)

---

## Notas para el instructor

- Los escenarios recorren el arco del curso: microservicios → integración → Event Hubs → Aspire → Docker → Azure → AWS → Kubernetes/validación.
- Si el grupo no ha visto Kubernetes, el escenario 10 sigue siendo válido como cierre de validación (health + Postman); puedes aclarar que `k8s/` se ve en etapa 9+.
- Repaso recomendado: [GUIA-ENDPOINTS.md](./GUIA-ENDPOINTS.md) (flujo E2E) y [README.md](../README.md) (tabla de arranque y release).
