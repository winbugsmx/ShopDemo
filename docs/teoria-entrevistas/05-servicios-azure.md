# 05 — Servicios de Microsoft Azure

## Objetivo de este capítulo

Al terminar este capítulo podrás **nombrar, definir y relacionar** los servicios más importantes de Microsoft Azure. No se trata de memorizar nombres comerciales, sino de entender **qué problema resuelve cada servicio**, en qué capa de la nube vive y **cuándo elegirlo** frente a alternativas.

Asumimos que ya sabes programar en C#, crear APIs REST con HTTP y trabajar con bases de datos SQL. Si has desplegado una aplicación en tu propio PC o en un servidor IIS, ya tienes la base para entender por qué existen estos servicios.

Conceptos que dominarás:

- Modelos de cloud: IaaS, PaaS y SaaS.
- Compute: App Service, Functions, AKS, Container Apps, VMs.
- Datos: SQL, Cosmos DB, Redis, Blob Storage.
- Mensajería: Service Bus, Event Hubs, Event Grid.
- Identidad, red, observabilidad y DevOps en Azure.

> **Cómo leer este capítulo:** cada servicio sigue la misma estructura: definición formal → explicación con analogías → diagrama (cuando aplica) → cuándo usarlo. No te saltes las definiciones; son la base del vocabulario que usarás en equipos reales.

---

## 1. ¿Qué es Microsoft Azure?

### Definición formal

**Microsoft Azure** es una plataforma de computación en la nube pública que ofrece servicios gestionados para ejecutar aplicaciones, almacenar datos, conectar sistemas y proteger recursos, facturados por consumo (pay-as-you-go) o por reservas.

### Explicación desarrollada

Imagina que en lugar de comprar un servidor físico, instalar Windows, configurar IIS, abrir puertos en el router y hacer backups manualmente, **contratas a un proveedor** que ya tiene centros de datos, electricidad, refrigeración y personal de operaciones. Tú solo defines qué quieres ejecutar y pagas por lo que usas.

Azure organiza miles de servicios en **regiones geográficas** (por ejemplo, *West Europe*, *East US*). Una región contiene uno o más **datacenters** independientes llamados **Availability Zones** (zonas de disponibilidad). Desplegar en varias zonas protege contra fallos de un solo edificio físico.

Desde la perspectiva de un desarrollador junior, Azure responde a preguntas como:

- ¿Dónde hospedo mi API .NET sin administrar un servidor?
- ¿Dónde guardo archivos, imágenes o backups?
- ¿Cómo envío mensajes entre microservicios?
- ¿Cómo autentico usuarios sin escribir todo el sistema de login yo solo?

```mermaid
flowchart TB
  subgraph TU["Tu responsabilidad"]
    APP[Código de la aplicación]
    DAT[Modelo de datos y reglas de negocio]
  end
  subgraph AZURE["Azure gestiona"]
    HW[Servidores físicos]
    RED[Red y conmutación]
    SO[Sistema operativo en IaaS/PaaS]
    PATCH[Parches de seguridad]
    BACK[Backups automáticos en PaaS]
  end
  APP --> AZURE
  DAT --> AZURE
```

### Cuándo usar Azure (y cuándo no)

| Situación | ¿Azure? |
|---|---|
| Quieres desplegar una API sin comprar hardware | Sí |
| Necesitas cumplir normativas en regiones concretas (GDPR, etc.) | Sí — eliges región europea |
| Prototipo local que nunca saldrá de tu laptop | No necesariamente — `dotnet run` basta |
| Requisito estricto de on-premise sin internet | No — evalúa Azure Stack o infra local |

---

## 2. Modelos de servicio: IaaS, PaaS y SaaS

### Definición formal

Los **modelos de servicio cloud** describen qué capas de la pila tecnológica gestiona el proveedor (Azure) y cuáles gestiona el cliente (tú o tu equipo).

| Modelo | Nombre completo | Proveedor gestiona | Cliente gestiona |
|---|---|---|---|
| **IaaS** | Infrastructure as a Service | Hardware, virtualización, red física | SO, runtime, aplicación, datos |
| **PaaS** | Platform as a Service | Infraestructura + runtime + middleware | Aplicación y datos |
| **SaaS** | Software as a Service | Aplicación completa | Configuración, usuarios, datos propios |

### Explicación desarrollada

Piensa en **pizza**:

- **On-premise (tu casa):** compras ingredientes, amasas, horneas y sirves. Control total, trabajo total.
- **IaaS:** te entregan la cocina equipada con horno y mesa; tú haces la pizza.
- **PaaS:** te dan la cocina y un chef que prepara la base; tú solo añades ingredientes (tu código).
- **SaaS:** pides pizza a domicilio; comes, no cocinas.

En C# y ASP.NET:

- **IaaS** = Virtual Machine con Windows Server donde instalas .NET manualmente.
- **PaaS** = App Service donde subes tu DLL o contenedor y Azure configura el runtime.
- **SaaS** = Microsoft 365, Dynamics — usas la app, no despliegas código.

![Comparativa conceptual de categorías Azure vs AWS](./assets/images/azure-vs-aws-servicios.png)

La imagen anterior muestra categorías equivalentes entre Azure y AWS. No son copias exactas, pero ayudan a ubicar servicios por función.

```mermaid
flowchart TB
  subgraph CAPAS["Pila tecnológica"]
    L1[Aplicación]
    L2[Datos]
    L3[Runtime .NET / contenedor]
    L4[Sistema operativo]
    L5[Virtualización]
    L6[Servidores físicos]
  end
  IaaS[IaaS - VM] --> L4
  PaaS[PaaS - App Service] --> L3
  SaaS[SaaS - M365] --> L1
```

### Cuándo elegir cada modelo

| Modelo | Elige cuando… | Evita cuando… |
|---|---|---|
| **IaaS** | Necesitas control total del SO, software legacy, drivers especiales | Quieres minimizar tareas de operaciones |
| **PaaS** | Quieres desplegar APIs .NET rápido sin parchear Windows | Necesitas configuraciones de kernel muy específicas |
| **SaaS** | El producto comercial cubre tu necesidad (email, CRM) | Necesitas lógica de negocio custom extensa |

**Trade-off fundamental:** más control (IaaS) implica más responsabilidad operativa. Más abstracción (PaaS/SaaS) implica menos flexibilidad en la capa inferior.

---

## 3. Compute y contenedores

Esta sección responde: **¿dónde corre mi código en Azure?**

### 3.1 Azure App Service

#### Definición formal

**Azure App Service** es una plataforma **PaaS** para hospedar aplicaciones web, APIs REST, backends móviles y funciones web sin administrar servidores, balanceadores ni parches del sistema operativo.

#### Explicación desarrollada

Si ya has publicado una API ASP.NET Core en IIS o con `dotnet run`, App Service es el equivalente **gestionado en la nube**. Subes tu código (Git, GitHub Actions, ZIP, contenedor) y Azure:

- Asigna una URL pública (`https://mi-api.azurewebsites.net`).
- Proporciona HTTPS con certificado gestionado.
- Permite **escalar** horizontalmente (más instancias) o verticalmente (más CPU/RAM).
- Ofrece **deployment slots** (ranuras): entornos `staging` y `production` en el mismo servicio para probar antes de intercambiar tráfico.

Conceptos clave para juniors:

- **Plan de App Service:** define CPU, RAM y límites. Planes compartidos (Free/Shared) sirven para pruebas; Standard/Premium para producción.
- **Always On:** evita que la app se "duerma" por inactividad (importante para WebJobs y tareas en background).
- **Integración con Entra ID:** autenticación de usuarios sin implementar OAuth desde cero.

```mermaid
flowchart LR
  DEV[Desarrollador] -->|git push / CI| AS[App Service]
  USR[Cliente HTTP] -->|HTTPS| AS
  AS --> DB[(Azure SQL)]
  AS --> KV[Key Vault - secretos]
```

#### Cuándo usar App Service

| Usa App Service cuando… | Considera otra opción cuando… |
|---|---|
| API REST CRUD estándar en .NET | Necesitas Kubernetes, operators o Helm |
| Equipo pequeño sin experiencia en contenedores | Carga muy esporádica (evalúa Functions) |
| Quieres slots de staging integrados | Necesitas control del SO (usa VM) |

---

### 3.2 Azure Functions

#### Definición formal

**Azure Functions** es un servicio de **computación serverless** orientado a eventos: ejecuta fragmentos de código (funciones) en respuesta a **triggers** (HTTP, cola, timer, blob, etc.) sin aprovisionar servidores visibles.

#### Explicación desarrollada

**Serverless** no significa "sin servidores", sino que **no gestionas servidores**. Azure escala automáticamente y, en el plan Consumption, **puede escalar a cero** (no pagas cuando no hay ejecuciones).

Una función típica en C#:

- Se dispara cuando llega un mensaje a una cola.
- Procesa el mensaje (por ejemplo, redimensiona una imagen).
- Termina.

Conceptos importantes:

- **Trigger:** qué inicia la función (HTTP request, mensaje en Service Bus, cron con Timer).
- **Binding:** conexión declarada a otros servicios (entrada/salida de datos sin boilerplate).
- **Cold start:** la primera invocación tras inactividad puede tardar más porque Azure "despierta" el runtime.
- **Facturación Consumption:** por número de ejecuciones + GB-segundos de memoria.

```mermaid
flowchart LR
  T1[Timer - cada hora] --> F[Azure Function]
  T2[HTTP POST] --> F
  T3[Mensaje en cola] --> F
  F --> B[Blob Storage]
  F --> SB[Service Bus]
```

#### Cuándo usar Functions

| Usa Functions cuando… | Evita Functions cuando… |
|---|---|
| Tareas cortas (< minutos), event-driven | Proceso largo de horas (límite de timeout) |
| Webhooks, ETL ligero, procesamiento de archivos | API con tráfico constante 24/7 muy predecible (App Service puede ser más económico) |
| Escala impredecible con picos | Necesitas estado en memoria entre invocaciones (anti-patrón) |

---

### 3.3 Azure Kubernetes Service (AKS)

#### Definición formal

**Azure Kubernetes Service (AKS)** es un servicio **Kubernetes gestionado** donde Microsoft opera el **control plane** (API server, etcd, scheduler, controllers) y el cliente gestiona los **nodos worker** donde corren los contenedores.

#### Explicación desarrollada

**Kubernetes (K8s)** es un orquestador de contenedores: decide en qué máquina corre cada contenedor, los reinicia si fallan, escala réplicas y expone servicios de red. AKS elimina la parte más compleja: instalar y mantener el control plane.

Para un junior que viene de `docker run`:

- Empaquetas tu API en una **imagen Docker**.
- Defines un **Deployment** con 3 réplicas.
- Kubernetes mantiene 3 pods vivos aunque uno falle.

Integraciones típicas en Azure:

- **ACR (Azure Container Registry):** almacén privado de imágenes.
- **Azure CNI:** red de pods integrada con Virtual Network.
- **Workload Identity:** pods que obtienen tokens de Entra ID sin secretos en código.
- **Azure Monitor / Application Insights:** métricas y trazas del clúster.

```mermaid
flowchart TB
  subgraph AKS["Clúster AKS"]
    CP[Control Plane - gestionado por Azure]
    W1[Nodo worker 1]
    W2[Nodo worker 2]
    P1[Pod API]
    P2[Pod API]
    W1 --> P1
    W2 --> P2
  end
  ACR[Container Registry] -->|pull imagen| AKS
  DEV[Pipeline CI/CD] --> ACR
```

Fuente editable del stack completo: [assets/diagrams/05-azure-stack.mermaid](./assets/diagrams/05-azure-stack.mermaid)

#### Cuándo usar AKS

| Usa AKS cuando… | Considera Container Apps o App Service cuando… |
|---|---|
| Microservicios con muchos servicios e interdependencias | Tienes 1–2 APIs simples |
| Necesitas Helm, operators, GitOps (Argo CD) | El equipo no tiene capacidad de operar K8s |
| Portabilidad multicloud del manifiesto K8s es importante | Quieres escala a cero sin configurar K8s |

---

### 3.4 Azure Container Apps

#### Definición formal

**Azure Container Apps** es una plataforma **serverless para contenedores** construida sobre Kubernetes, que abstrae la complejidad del clúster y ofrece escalado automático (incluido a cero), revisiones y entrada HTTP integrada.

#### Explicación desarrollada

Container Apps ocupa el espacio intermedio entre App Service (PaaS simple) y AKS (K8s completo). Ejecutas contenedores Docker, pero no gestionas nodos, ni etcd, ni upgrades del control plane.

Características distintivas:

- **Escalado a cero:** si no hay tráfico, no pagas compute activo.
- **Revisiones:** cada despliegue crea una revisión; puedes dividir tráfico entre revisiones (similar a canary).
- **Dapr opcional:** sidecar para invocación entre servicios, pub/sub, state store (útil en microservicios).
- **Entorno (Environment):** agrupa apps que comparten red y logs.

```mermaid
flowchart LR
  INT[Internet] --> ING[Ingress integrado]
  ING --> CA1[Container App - API v1]
  ING --> CA2[Container App - API v2]
  CA1 --> SB[Service Bus]
  CA2 --> SB
```

#### Cuándo usar Container Apps

| Usa Container Apps cuando… | Usa AKS cuando… |
|---|---|
| Contenedores con tráfico variable o escala a cero | Necesitas control fino de red, DaemonSets, CRDs |
| Equipo sin operadores K8s dedicados | Ya tienes ecosistema Helm/operators maduro |
| Microservicios moderados con Dapr | Cargas con requisitos de GPU, Windows nodes, etc. |

---

### 3.5 Virtual Machines y Scale Sets

#### Definición formal

**Azure Virtual Machines (VMs)** son máquinas virtuales **IaaS** con control completo del sistema operativo. **Virtual Machine Scale Sets (VMSS)** son conjuntos de VMs idénticas con autoescalado y balanceo de carga integrado.

#### Explicación desarrollada

Una VM es lo más parecido a un servidor tradicional en la nube: eliges tamaño (vCPU, RAM), SO (Windows Server, Linux), discos y abres puertos con Network Security Groups.

VMSS añade:

- **Autoescalado:** más VMs cuando sube la CPU; menos cuando baja.
- **Modelo idéntico:** misma imagen en todas las instancias (patrón cattle, no pets).

#### Cuándo usar VMs / VMSS

| Usa VMs cuando… | Prefiere PaaS cuando… |
|---|---|
| Software legacy que no containeriza fácilmente | Puedes desplegar en App Service o contenedores |
| Requisitos de SO muy específicos | Quieres parches automáticos del runtime |
| Licencias per-core que ya tienes | Minimizar tareas de sysadmin |

---

## 4. Servicios de datos

### 4.1 Azure SQL Database

#### Definición formal

**Azure SQL Database** es un motor **relacional SQL Server** ofrecido como servicio **PaaS**, compatible con T-SQL, con backups automáticos, alta disponibilidad y escalado de compute y almacenamiento independientes.

#### Explicación desarrollada

Si ya usas SQL Server o Entity Framework con SQL, Azure SQL es el camino natural a la nube. No instalas SQL Server en una VM: Azure gestiona:

- **Backups automáticos** con retención configurable.
- **Patching** de seguridad del motor.
- **Tier de servicio:** Basic, Standard, Premium, Hyperscale (para cargas muy grandes).

Conceptos para juniors:

- **DTU vs vCore:** modelos de capacidad; vCore da más control y transparencia.
- **Connection string:** igual que local, pero con firewall de Azure (debes permitir tu IP o usar Private Link).
- **Elastic Pool:** varias bases comparten recursos — útil para muchas BD pequeñas.

```mermaid
flowchart LR
  API[API .NET + EF Core] -->|T-SQL| SQL[(Azure SQL Database)]
  SQL --> BAK[Backups automáticos]
  SQL --> HA[Réplica secundaria - tier Premium]
```

#### Cuándo usar Azure SQL

| Usa Azure SQL cuando… | Considera PostgreSQL/MySQL managed cuando… |
|---|---|
| Ecosistema Microsoft, T-SQL, EF Core | Equipo prefiere PostgreSQL open source |
| Transacciones ACID, joins complejos | — |
| Migración desde SQL Server on-premise | — |

---

### 4.2 Azure Cosmos DB

#### Definición formal

**Azure Cosmos DB** es una base de datos **NoSQL multi-modelo** (documento, clave-valor, grafo, columna) distribuida globalmente, con SLAs de latencia y niveles de consistencia configurables.

#### Explicación desarrollada

Cosmos DB no es "SQL en la nube". Está diseñada para:

- **Escala masiva** de lecturas/escrituras horizontales.
- **Distribución multi-región** con réplicas de lectura en varios continentes.
- **Latencia predecible** (p99 en single-digit ms en muchos escenarios).

Conceptos clave:

- **Partición (partition key):** decide cómo se distribuyen los datos; mala elección = cuellos de botella.
- **APIs:** puedes usar la API de MongoDB, Cassandra, Gremlin, Table o SQL (Core) según el modelo.
- **Niveles de consistencia:** desde *Strong* (como SQL single-node) hasta *Eventual* (más rendimiento, menos garantía instantánea).

```mermaid
flowchart TB
  subgraph REG1["Región Europa"]
    W1[Escrituras]
  end
  subgraph REG2["Región USA"]
    R1[Réplica lectura]
  end
  subgraph REG3["Región Asia"]
    R2[Réplica lectura]
  end
  W1 --> R1
  W1 --> R2
```

#### Cuándo usar Cosmos DB

| Usa Cosmos DB cuando… | Usa Azure SQL cuando… |
|---|---|
| App global con usuarios en varios continentes | Datos relacionales con joins complejos |
| Escala de millones de operaciones/segundo | Modelo relacional clásico basta |
| Puedes modelar datos por clave de partición | Necesitas transacciones multi-tabla ACID simples |

---

### 4.3 Azure Database for PostgreSQL / MySQL

#### Definición formal

**Azure Database for PostgreSQL** y **Azure Database for MySQL** son servicios **PaaS** que ejecutan motores open source relacionales gestionados por Azure (backups, parches, alta disponibilidad).

#### Explicación desarrollada

Equivalente managed a "PostgreSQL/MySQL sin administrar el servidor". Muy usados cuando el equipo prefiere PostgreSQL por extensiones (PostGIS), licenciamiento o coste.

#### Cuándo usar

Elige PostgreSQL/MySQL managed cuando tu stack ya usa esos motores y no necesitas SQL Server específicamente.

---

### 4.4 Azure Cache for Redis

#### Definición formal

**Azure Cache for Redis** es un servicio **managed** de cache en memoria compatible con el protocolo **Redis**, usado para almacenar datos temporales de acceso rápido.

#### Explicación desarrollada

Redis guarda datos en **RAM**, mucho más rápido que disco. Casos típicos:

- **Cache de consultas:** guardar resultado de `GET /products` 60 segundos.
- **Sesiones de usuario:** estado de login entre requests.
- **Rate limiting:** contador de requests por IP.
- **Pub/Sub ligero:** notificaciones en tiempo real simples.

En C# usarías `StackExchange.Redis` o `IDistributedCache`.

```mermaid
flowchart LR
  API[API] -->|1. consulta cache| R[(Redis)]
  R -->|miss| API
  API -->|2. consulta BD| DB[(SQL)]
  API -->|3. guarda en cache| R
```

#### Cuándo usar Redis

| Usa Redis cuando… | No uses Redis como… |
|---|---|
| Lecturas repetidas de datos que cambian poco | Única base de datos persistente |
| Necesitas latencia sub-milisegundo | Almacén de archivos grandes |

---

### 4.5 Azure Blob Storage

#### Definición formal

**Azure Blob Storage** es un servicio de **almacenamiento de objetos** para archivos binarios (blobs) escalable, con tiers de coste según frecuencia de acceso.

#### Explicación desarrollada

Un **blob** es un archivo: PDF, imagen, video, backup ZIP. Se organiza en **contenedores** (como carpetas de primer nivel). Cada blob tiene una URL única.

**Tiers (niveles):**

| Tier | Uso |
|---|---|
| **Hot** | Acceso frecuente (imágenes de web activa) |
| **Cool** | Acceso ocasional (backups recientes) |
| **Archive** | Retención larga, acceso raro (cumplimiento legal) |

```mermaid
flowchart TB
  APP[Aplicación] -->|upload| BLOB[Blob Storage]
  CDN[Azure CDN / Front Door] -->|serve estáticos| BLOB
  EH[Event Hubs Capture] -->|archivo eventos| BLOB
```

#### Cuándo usar Blob Storage

| Usa Blob cuando… | Usa SQL cuando… |
|---|---|
| Archivos, imágenes, videos, logs archivados | Datos estructurados con consultas SQL |
| Data lake, backups, artefactos de build | Relaciones entre entidades |

---

## 5. Mensajería e integración

### 5.1 Azure Service Bus

#### Definición formal

**Azure Service Bus** es un **broker de mensajes enterprise** que soporta **colas** (un consumidor por mensaje) y **topics con suscripciones** (pub/sub), con garantías de entrega, dead-lettering y opciones de orden y transacciones.

#### Explicación desarrollada

Cuando un microservicio debe **enviar un trabajo** a otro sin esperar respuesta HTTP, usa una cola. Service Bus:

- **Almacena** el mensaje hasta que un consumidor lo procese.
- **Reintenta** si el consumidor falla (visibility timeout similar a SQS).
- **Dead-letter queue (DLQ):** mensajes que fallaron repetidamente van a una cola especial para análisis.

Conceptos:

- **Cola vs Topic:** cola = un consumidor procesa cada mensaje; topic = varios suscriptores reciben copia.
- **Sesiones:** mensajes con mismo `SessionId` se procesan en orden.
- **Duplicate detection:** evita procesar el mismo mensaje dos veces (idempotencia a nivel broker).

```mermaid
flowchart LR
  P[Productor - API Pedidos] --> Q[Cola orders-processing]
  Q --> C1[Consumidor Inventario]
  Q -->|fallo N veces| DLQ[Dead Letter Queue]
```

#### Cuándo usar Service Bus

| Usa Service Bus cuando… | Usa Event Hubs cuando… |
|---|---|
| Mensajes de negocio con confirmación de procesamiento | Millones de eventos/segundo (telemetría, IoT) |
| Necesitas orden parcial, transacciones, DLQ enterprise | Varios consumidores leen el mismo flujo como log |
| Integración entre microservicios con garantías | Analytics en streaming masivo |

---

### 5.2 Azure Event Hubs

#### Definición formal

**Azure Event Hubs** es un servicio de **ingesta de eventos** a gran escala que implementa un modelo de **log particionado** optimizado para millones de eventos por segundo.

#### Explicación desarrollada

Event Hubs es un "tubo" de eventos: productores escriben; múltiples **consumer groups** leen el mismo stream a ritmo independiente (como Kafka o un log de commits).

Analogía: Service Bus es una **cola de tareas** ("procesa este pedido"); Event Hubs es un **río de telemetría** ("registra cada clic, cada sensor, cada log").

Características:

- **Particiones:** paralelismo de lectura/escritura.
- **Retención:** días de eventos almacenados (no solo en tránsito).
- **Capture:** exportación automática a Blob Storage para análisis batch.

```mermaid
flowchart LR
  PROD1[App Web] --> EH[Event Hub]
  PROD2[App Móvil] --> EH
  PROD3[IoT Devices] --> EH
  EH --> CG1[Consumer Group - Analytics]
  EH --> CG2[Consumer Group - Alertas]
```

#### Cuándo usar Event Hubs

| Usa Event Hubs cuando… | Usa Service Bus cuando… |
|---|---|
| Telemetría, logs, IoT, clickstreams | Comandos de negocio ("crear factura") |
| Throughput masivo | Mensajes grandes con transacciones complejas |

---

### 5.3 Azure Event Grid

#### Definición formal

**Azure Event Grid** es un servicio de **enrutamiento de eventos** basado en **pub/sub** que conecta fuentes de eventos (recursos Azure, aplicaciones custom) con handlers (Functions, Logic Apps, webhooks).

#### Explicación desarrollada

Event Grid reacciona a **hechos** ("se creó un blob", "se eliminó una VM") y dispara acciones automáticas. Es ideal para automatización reactiva de infraestructura, no para colas de trabajo pesadas.

```mermaid
flowchart LR
  BLOB[Blob Storage] -->|BlobCreated| EG[Event Grid]
  EG --> FN[Azure Function]
  EG --> LA[Logic App]
  EG --> WH[Webhook HTTP]
```

#### Cuándo usar Event Grid

| Usa Event Grid cuando… | Usa Service Bus cuando… |
|---|---|
| Reaccionar a cambios en recursos Azure | Procesamiento de negocio con reintentos y DLQ |
| Arquitectura event-driven ligera | Orden, sesiones, mensajes grandes |

---

### 5.4 Azure Logic Apps

#### Definición formal

**Azure Logic Apps** es un servicio de **orquestación de workflows** low-code con conectores predefinidos a cientos de sistemas (Office 365, Salesforce, SQL, HTTP, etc.).

#### Explicación desarrollada

Logic Apps permite integrar sistemas **sin escribir mucho código**: arrastras pasos ("cuando llegue email → guardar adjunto en Blob → crear fila en SQL").

#### Cuándo usar Logic Apps

| Usa Logic Apps cuando… | Escribe código custom cuando… |
|---|---|
| Integraciones B2B, flujos administrativos | Lógica compleja, tests unitarios extensos |
| Equipo mixto negocio + IT | Performance crítica en microsegundos |

---

## 6. Identidad y seguridad

### 6.1 Microsoft Entra ID (antes Azure AD)

#### Definición formal

**Microsoft Entra ID** es el servicio de **identidad y acceso** en la nube de Microsoft. Gestiona usuarios, grupos, autenticación (OAuth 2.0, OpenID Connect, SAML) y autorización de aplicaciones.

#### Explicación desarrollada

En lugar de guardar usuarios y contraseñas en tu propia tabla `Users`, delegas en Entra ID:

- **SSO (Single Sign-On):** un login para muchas apps.
- **Registro de aplicaciones:** tu API declara qué permisos expone; clientes obtienen tokens JWT.
- **Managed Identities:** identidades para recursos Azure (ver siguiente sección).

Flujo típico OAuth para API:

1. Usuario inicia sesión en portal.
2. Obtiene **access token** JWT.
3. Llama a tu API con `Authorization: Bearer <token>`.
4. API valida firma y claims del token.

```mermaid
sequenceDiagram
  participant U as Usuario
  participant E as Entra ID
  participant A as API .NET
  U->>E: Login
  E-->>U: Access Token JWT
  U->>A: GET /orders + Bearer token
  A->>A: Validar token
  A-->>U: 200 OK
```

#### Cuándo usar Entra ID

| Usa Entra ID cuando… | Auth propia cuando… |
|---|---|
| Empresa ya usa Microsoft 365 / Azure | Prototipo muy aislado (aún así, considera Auth0/OIDC) |
| Necesitas SSO corporativo | — |

---

### 6.2 Azure Key Vault

#### Definición formal

**Azure Key Vault** es un servicio centralizado para almacenar de forma segura **secretos** (connection strings, API keys), **claves criptográficas** y **certificados TLS**, con control de acceso y auditoría.

#### Explicación desarrollada

**Nunca** pongas connection strings en `appsettings.json` commiteado a Git. Key Vault:

- Cifra secretos en reposo.
- Registra quién accedió.
- Permite rotación de secretos y certificados.
- Se integra con App Service, Functions, AKS via referencias o CSI driver.

```mermaid
flowchart LR
  APP[App Service / AKS Pod] -->|Managed Identity| KV[Key Vault]
  KV --> SEC[Connection String SQL]
  KV --> CERT[Certificado TLS]
```

#### Cuándo usar Key Vault

Siempre en producción para secretos. En desarrollo local, `User Secrets` o variables de entorno, nunca en el repositorio.

---

### 6.3 Managed Identity

#### Definición formal

**Managed Identity** es una identidad de Entra ID **asignada automáticamente** a un recurso Azure (App Service, VM, AKS pod) que obtiene tokens de acceso **sin credenciales embebidas** en código o configuración.

#### Explicación desarrollada

Tipos:

| Tipo | Vida útil | Uso |
|---|---|---|
| **System-assigned** | Ligada al recurso; se elimina con el recurso | Un recurso, una identidad |
| **User-assigned** | Independiente; reutilizable | Varios recursos comparten identidad |

Tu código en Azure solo pregunta al metadata endpoint por un token; Azure AD valida y Key Vault entrega el secreto.

#### Cuándo usar Managed Identity

Siempre que un recurso Azure acceda a otro servicio Azure (SQL, Storage, Service Bus). Elimina el riesgo de client secrets filtrados.

---

### 6.4 Azure Private Link

#### Definición formal

**Azure Private Link** expone servicios PaaS de Azure mediante **endpoints privados** dentro de tu Virtual Network, de modo que el tráfico **no atraviese internet público**.

#### Explicación desarrollada

Por defecto, Azure SQL tiene un endpoint público (con firewall). Con Private Link, tu API en una VNet accede a SQL por IP privada interna — mayor seguridad y cumplimiento.

#### Cuándo usar Private Link

Entornos enterprise, datos sensibles, requisitos de red privada o compliance estricto.

---

## 7. Red y edge

### 7.1 Virtual Network (VNet)

#### Definición formal

**Azure Virtual Network** es una red privada aislada en Azure con rangos IP propios, **subnets**, peering entre VNets, y conectividad híbrida via VPN o ExpressRoute.

#### Explicación desarrollada

Piensa en la VNet como tu "red de oficina" en la nube. Subnets segmentan recursos (subnet `frontend`, subnet `data`). Network Security Groups (NSG) filtran tráfico como un firewall.

---

### 7.2 Network Security Groups (NSG)

#### Definición formal

**NSG** es un firewall con reglas de permitir/denegar tráfico por puerto, protocolo y dirección, aplicable a subnets o interfaces de red (NIC).

---

### 7.3 Application Gateway

#### Definición formal

**Application Gateway** es un balanceador de carga **Layer 7 (HTTP/HTTPS)** con enrutamiento por URL, terminación SSL, afinidad de sesión y **WAF (Web Application Firewall)** opcional.

---

### 7.4 Azure Front Door

#### Definición formal

**Azure Front Door** es un servicio global de **CDN + balanceo anycast + WAF** que enruta usuarios al endpoint más cercano o saludable en múltiples regiones.

```mermaid
flowchart TB
  U1[Usuario Europa] --> FD[Azure Front Door]
  U2[Usuario USA] --> FD
  FD --> R1[App - Europa]
  FD --> R2[App - USA]
```

#### Cuándo usar Front Door vs Application Gateway

| Front Door | Application Gateway |
|---|---|
| Tráfico global, multi-región | Tráfico regional dentro de una VNet |
| CDN y WAF global | WAF regional, integración VNet profunda |

---

### 7.5 Azure DNS

#### Definición formal

**Azure DNS** hospeda zonas DNS y registra registros A, CNAME, MX, etc., integrado con otros servicios Azure.

---

## 8. Observabilidad

### 8.1 Azure Monitor

#### Definición formal

**Azure Monitor** es la plataforma unificada de **métricas, logs y alertas** para recursos Azure y aplicaciones.

Recopila:

- **Métricas:** series temporales numéricas (CPU, requests/seg).
- **Logs:** texto estructurado (KQL queries).
- **Alertas:** reglas que disparan acciones (email, webhook, autoscale).

---

### 8.2 Application Insights

#### Definición formal

**Application Insights** es el componente de **APM (Application Performance Monitoring)** dentro de Azure Monitor: requests HTTP, dependencias (SQL, HTTP externos), excepciones, trazas distribuidas y mapa de servicios.

#### Explicación desarrollada

En ASP.NET Core añades el SDK NuGet; automáticamente registras cada request, llamadas a SQL y errores. Con **correlation ID** (capítulo 04) puedes seguir una petición entre microservicios.

```mermaid
flowchart LR
  API1[API Pedidos] -->|trace| AI[Application Insights]
  API2[API Inventario] -->|trace| AI
  AI --> LA[Log Analytics Workspace]
  LA --> AL[Alertas]
```

---

### 8.3 Log Analytics Workspace

#### Definición formal

**Log Analytics Workspace** es el repositorio central donde se almacenan logs de múltiples fuentes; consultas con **KQL (Kusto Query Language)**.

---

## 9. DevOps e infraestructura en Azure

### 9.1 Azure Container Registry (ACR)

#### Definición formal

**ACR** es un **registro privado** de imágenes Docker/OCI con integración a AKS, App Service y pipelines CI/CD.

---

### 9.2 Azure DevOps

#### Definición formal

**Azure DevOps** es la suite de colaboración: repos Git, **pipelines YAML**, boards (Kanban), test plans y artifacts. Alternativa a GitHub Actions dentro del ecosistema Microsoft.

---

### 9.3 Bicep y ARM Templates

#### Definición formal

**ARM (Azure Resource Manager)** es la capa de despliegue de recursos Azure. **Bicep** es un lenguaje declarativo que compila a ARM, más legible que JSON puro — **Infraestructura como Código (IaC)** nativa Azure.

---

### 9.4 GitHub Actions con OIDC federado

#### Definición formal

**OIDC federation** permite que un pipeline de GitHub Actions **asuma un rol** en Entra ID y despliegue en Azure **sin almacenar client secrets permanentes** en GitHub Secrets.

```mermaid
flowchart LR
  GH[GitHub Actions] -->|OIDC token| EID[Entra ID]
  EID -->|token Azure| ARM[Azure Resource Manager]
  ARM --> AKS[AKS / App Service]
```

---

## 10. Diagrama: stack típico con AKS

Este diagrama resume cómo encajan servicios en un despliegue microservicios típico en Azure:

```mermaid
flowchart LR
  DEV[Developer] --> GH[GitHub Actions]
  GH --> ACR[Azure Container Registry]
  GH --> AKS[Azure Kubernetes Service]
  AKS --> KV[Key Vault]
  AKS --> SB[Service Bus]
  AKS --> SQL[Azure SQL]
  AKS --> AI[Application Insights]
```

Fuente editable: [assets/diagrams/05-azure-stack.mermaid](./assets/diagrams/05-azure-stack.mermaid)

**Lectura del flujo:**

1. Desarrollador hace commit; GitHub Actions compila y construye imagen Docker.
2. Imagen se publica en ACR.
3. Pipeline despliega en AKS (kubectl, Helm o GitOps).
4. Pods usan Managed Identity para leer secretos de Key Vault.
5. Microservicios se comunican via Service Bus.
6. Datos transaccionales en Azure SQL.
7. Trazas y métricas en Application Insights.

---

## 11. Resumen del capítulo

- **Azure** es una plataforma cloud con servicios por capas **IaaS, PaaS y SaaS**; más abstracción = menos operaciones, menos control fino.
- **Compute:** App Service para APIs simples; Functions para eventos cortos; AKS para orquestación completa; Container Apps como punto medio serverless.
- **Datos:** Azure SQL para relacional ACID; Cosmos DB para escala global NoSQL; Redis para cache; Blob para archivos.
- **Mensajería:** Service Bus para colas de negocio; Event Hubs para streaming masivo; Event Grid para reaccionar a eventos de infraestructura.
- **Seguridad:** Entra ID para identidad; Key Vault para secretos; Managed Identity para eliminar credenciales en código; Private Link para red privada.
- **Observabilidad:** Application Insights + Log Analytics + alertas forman la base para operar en producción.
- **DevOps:** ACR + pipelines (GitHub Actions / Azure DevOps) + Bicep para reproducibilidad.

**Siguiente paso:** capítulo 06 — los servicios equivalentes en **Amazon Web Services (AWS)** y cómo compararlos con lo que acabas de aprender en Azure.
