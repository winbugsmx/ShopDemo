# 06 — Servicios de Amazon Web Services (AWS)

## Objetivo de este capítulo

Comprender los **servicios fundamentales de AWS**, qué problema resuelve cada uno y cómo se **comparan con Azure** (capítulo anterior). Al final podrás leer un diagrama de arquitectura AWS, identificar cada componente y explicar por qué está ahí.

Asumimos conocimientos de C#, HTTP, SQL y haber leído el capítulo 05 (Azure). Muchos conceptos son **paralelos** entre nubes; aquí aprenderás los nombres y matices de AWS.

Conceptos que dominarás:

- Modelo de AWS y vocabulario (región, AZ, IAM).
- Compute: EC2, ECS, Fargate, EKS, Lambda.
- Almacenamiento y datos: S3, RDS, Aurora, DynamoDB, ElastiCache.
- Mensajería: SQS, SNS, EventBridge, Kinesis.
- Identidad, red, observabilidad, DevOps y conceptos de coste/resiliencia.

> **Nota del instructor:** AWS fue pionera en cloud y tiene **más servicios** que cualquier otro proveedor. No intentes aprenderlos todos de una vez. Enfócate en los de este capítulo; son los que aparecen en el 80 % de arquitecturas reales.

---

## 1. ¿Qué es Amazon Web Services (AWS)?

### Definición formal

**Amazon Web Services (AWS)** es una plataforma de computación en la nube pública que ofrece servicios de infraestructura, plataforma y software bajo demanda, facturados por consumo, organizados en **regiones** y **Availability Zones**.

### Explicación desarrollada

AWS y Azure resuelven los mismos problemas con nombres distintos. La diferencia cultural:

- **AWS** enfatiza **composabilidad**: arquitecturas construidas combinando servicios pequeños y especializados (S3 + Lambda + DynamoDB + SQS).
- **Azure** suele integrar más el ecosistema Microsoft (.NET, Entra ID, SQL Server).

Vocabulario esencial:

| Término | Significado |
|---|---|
| **Región** | Área geográfica (ej. `eu-west-1` Irlanda) |
| **Availability Zone (AZ)** | Datacenter independiente dentro de una región |
| **Account** | Contenedor de facturación y recursos (como una "suscripción" Azure) |
| **IAM** | Identity and Access Management — permisos en todo AWS |

![Diagrama](./assets/images/diagrams/embedded-45b9b1cef572.png)

![Mapa conceptual de servicios equivalentes Azure y AWS](./assets/images/azure-vs-aws-servicios.png)

### Cuándo elegir AWS

| Elige AWS cuando… | Considera Azure cuando… |
|---|---|
| Tu organización ya estandarizó AWS | Ecosistema Microsoft predominante |
| Necesitas servicio específico líder (S3, Lambda madurez) | Integración profunda con Active Directory / M365 |
| Equipo con certificaciones AWS | Contrato enterprise Microsoft existente |

Las equivalencias son **aproximadas**; capacidades, precios y operación difieren.

---

## 2. Modelo de servicio en AWS

### Definición formal

Al igual que Azure, AWS opera en capas **IaaS, PaaS y SaaS**. La mayoría de servicios que verás como desarrollador backend son **IaaS** (EC2) o **PaaS** (RDS, Lambda, ECS Fargate).

### Explicación desarrollada

En C# / .NET en AWS desplegarías típicamente:

| Escenario | Servicio AWS |
|---|---|
| API en contenedor sin gestionar servidores | ECS Fargate o EKS |
| API serverless por eventos | Lambda + API Gateway |
| SQL managed | RDS PostgreSQL o Aurora |
| Cola entre servicios | SQS |

![Diagrama](./assets/images/diagrams/embedded-c7c13de92f37.png)

---

## 3. Compute

### 3.1 Amazon EC2 (Elastic Compute Cloud)

#### Definición formal

**Amazon EC2** proporciona **máquinas virtuales IaaS** con control completo del sistema operativo, almacenamiento conectado (EBS), red (VPC, security groups) y tipo de instancia seleccionable.

#### Explicación desarrollada

EC2 es el equivalente AWS de **Azure Virtual Machines**. Conceptos clave:

- **Instance type:** familia + tamaño (`t3.micro`, `m6i.large`, `c7g.xlarge`). Familias optimizadas para compute (C), memoria (R), general (M), GPU (P/G).
- **AMI (Amazon Machine Image):** plantilla de disco con SO preinstalado (Amazon Linux, Windows Server).
- **Security Group:** firewall a nivel de instancia (solo reglas allow; tráfico implícitamente denegado).
- **Elastic IP:** IP pública estática opcional.
- **EBS (Elastic Block Store):** disco persistente asociado a la VM.

Para un junior: EC2 es "un servidor remoto al que te conectas por RDP/SSH e instalas .NET Runtime".

![Diagrama](./assets/images/diagrams/embedded-ff28aa1168c0.png)

#### Cuándo usar EC2

| Usa EC2 cuando… | Prefiere Fargate/Lambda cuando… |
|---|---|
| Software legacy, licencias por servidor | Puedes containerizar o usar functions |
| Control total del SO y kernel | Quieres cero parches de SO |
| GPU, bare metal, instancias especiales | Carga variable serverless |

---

### 3.2 Amazon ECS y AWS Fargate

#### Definición formal

**Amazon ECS (Elastic Container Service)** es el **orquestador de contenedores nativo** de AWS. **AWS Fargate** es un modo **serverless** de ECS (y EKS) donde AWS gestiona la infraestructura de nodos; el cliente define CPU/memoria del **task**.

#### Explicación desarrollada

ECS introduce vocabulario propio:

| Concepto ECS | Equivalente mental K8s |
|---|---|
| **Cluster** | Agrupación lógica |
| **Task Definition** | Plantilla del contenedor (imagen, CPU, env vars) |
| **Task** | Instancia en ejecución de una task definition |
| **Service** | Mantiene N tasks corriendo con balanceo |

**Fargate** elimina la gestión de instancias EC2 como nodos. Defines: "quiero 0.5 vCPU y 1 GB RAM" y AWS coloca el contenedor.

![Diagrama](./assets/images/diagrams/embedded-0c7cedcde2e0.png)

#### Cuándo usar ECS/Fargate

| Usa ECS Fargate cuando… | Usa EKS cuando… |
|---|---|
| Contenedores sin administrar K8s | Equipo ya domina Kubernetes |
| Integración nativa AWS (ALB, IAM) | Portabilidad de manifiestos K8s multicloud |
| Cargas moderadas de microservicios | Ecosistema Helm/operators |

---

### 3.3 Amazon EKS (Elastic Kubernetes Service)

#### Definición formal

**Amazon EKS** es un servicio de **Kubernetes gestionado** compatible con Kubernetes upstream; AWS opera el control plane y el cliente gestiona nodos (EC2 o Fargate).

#### Explicación desarrollada

EKS es el equivalente directo de **AKS**. Integraciones importantes:

- **ECR:** registro de imágenes (como ACR).
- **IRSA (IAM Roles for Service Accounts):** pods que asumen roles IAM via OIDC — equivalente a Workload Identity en Azure.
- **VPC CNI:** cada pod puede tener IP de VPC.
- **CloudWatch Container Insights:** métricas del clúster.

![Diagrama](./assets/images/diagrams/embedded-66fe7b49c76b.png)

![Diagrama: 06-aws-stack](./assets/images/diagrams/06-aws-stack.png)

> *Fuente editable (Mermaid):* [06-aws-stack.mermaid](./assets/diagrams/06-aws-stack.mermaid)

#### Cuándo usar EKS

| Usa EKS cuando… | Usa ECS Fargate cuando… |
|---|---|
| Manifiestos K8s reutilizables en otra nube | Quieres simplicidad sin API de K8s |
| GitOps con Argo CD / Flux | Equipo pequeño sin experiencia K8s |

---

### 3.4 AWS Lambda

#### Definición formal

**AWS Lambda** es computación **serverless** que ejecuta código en respuesta a **eventos** (API Gateway, S3, SQS, DynamoDB Streams, EventBridge) facturando por invocación y duración.

#### Explicación desarrollada

Equivalente a **Azure Functions**. Limitaciones importantes para juniors:

- **Timeout máximo:** 15 minutos por invocación.
- **Cold start:** primera invocación tras idle puede tardar (especialmente .NET sin Native AOT).
- **Deployment package:** límite de tamaño comprimido.
- **Estado:** Lambda es stateless; persistencia en S3, DynamoDB o ElastiCache.

Triggers comunes:

| Trigger | Ejemplo |
|---|---|
| API Gateway | REST API serverless |
| S3 | Procesar imagen al subir archivo |
| SQS | Consumir cola de mensajes |
| EventBridge | Reaccionar a evento de negocio |

![Diagrama](./assets/images/diagrams/embedded-6c9402550f64.png)

#### Cuándo usar Lambda

| Usa Lambda cuando… | Evita Lambda cuando… |
|---|---|
| Procesamiento event-driven corto | Latencia ultra-baja sin cold starts |
| Tráfico muy variable | Proceso continuo de horas |
| Integración con servicios AWS | Necesitas sockets persistentes o estado en memoria |

---

## 4. Almacenamiento y datos

### 4.1 Amazon S3 (Simple Storage Service)

#### Definición formal

**Amazon S3** es almacenamiento de **objetos** escalable con durabilidad diseñada del 99.999999999% (11 nines), accesible via API HTTP y organizado en **buckets** y **keys** (rutas de objeto).

#### Explicación desarrollada

S3 es el servicio más usado de AWS. Equivalente a **Azure Blob Storage**.

- **Bucket:** contenedor globalmente único por nombre (`mi-empresa-facturas-2024`).
- **Object key:** ruta lógica (`invoices/2024/enero/factura-001.pdf`).
- **Clases de almacenamiento:** Standard, Intelligent-Tiering, Glacier Instant Retrieval, Glacier Flexible, Deep Archive.

Usos típicos:

- Backups y archivos estáticos.
- Data lake (análisis con Athena).
- Hosting estático de SPA.
- Artefactos de build y logs archivados.

![Diagrama](./assets/images/diagrams/embedded-d8a63998d1ef.png)

#### Cuándo usar S3

| Usa S3 cuando… | Usa EBS cuando… |
|---|---|
| Archivos, imágenes, backups, data lake | Disco de sistema de una EC2 |
| Acceso via HTTP/API | Block storage attachado a VM |

---

### 4.2 Amazon RDS (Relational Database Service)

#### Definición formal

**Amazon RDS** es un servicio **PaaS** de bases de datos **relacionales** que soporta PostgreSQL, MySQL, MariaDB, Oracle y SQL Server, con backups automáticos, parches y opciones Multi-AZ.

#### Explicación desarrollada

RDS es el equivalente general de **Azure Database for PostgreSQL/MySQL** o SQL managed.

Conceptos:

- **Multi-AZ:** réplica sincrónica en otra AZ para failover automático (alta disponibilidad).
- **Read Replica:** réplica asíncrona para lecturas (escala lectura).
- **Parameter Group:** configuración del motor (max_connections, etc.).
- **Subnet Group:** subnets donde puede vivir la BD (siempre privadas en producción).

![Diagrama](./assets/images/diagrams/embedded-88dcaed156f2.png)

#### Cuándo usar RDS

| Usa RDS cuando… | Considera Aurora cuando… |
|---|---|
| PostgreSQL/MySQL estándar suficiente | Necesitas failover más rápido y más read replicas |
| Carga predecible moderada | Escrituras muy intensivas con storage autoescalable |

---

### 4.3 Amazon Aurora

#### Definición formal

**Amazon Aurora** es un motor de base de datos **compatible con MySQL o PostgreSQL** con almacenamiento distribuido autoescalable en AWS, replicación rápida y failover típico en segundos.

#### Explicación desarrollada

Aurora separa **compute** (instancias) de **storage** (capa distribuida en 6 copias en 3 AZ). Ventajas sobre RDS clásico:

- Hasta **15 read replicas** con lag mínimo.
- Failover automático rápido.
- Storage crece automáticamente hasta 128 TB.

Para juniors: si el equipo ya usa PostgreSQL en RDS y necesita más rendimiento HA, evalúa Aurora PostgreSQL.

Arquitectura mental:

```
Writer instance (primary) ──► Storage layer distribuido (6 copias, 3 AZ)
        │
        ├── Read replica 1 (reporting)
        ├── Read replica 2 (analytics)
        └── Failover automático en ~30 s si primary cae
```

**Ejemplo de uso con EF Core:** mismo connection string que RDS; Aurora expone endpoint `cluster-xxx.cluster-xxx.us-east-1.rds.amazonaws.com` para escritura y `cluster-xxx.cluster-ro-xxx` para lecturas (con read replica routing en la app o RDS Proxy).

#### Cuándo usar Aurora

| Usa Aurora cuando… | RDS estándar basta cuando… |
|---|---|
| SaaS con muchas lecturas y failover rápido | Carga moderada, presupuesto ajustado |
| Necesitas hasta 15 read replicas con lag bajo | 1–2 read replicas ocasionales |
| Storage que crece sin planificar capacidad | Tamaño de BD predecible y estable |

**Recursos:** [Aurora overview](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_AuroraOverview.html)

---

### 4.4 Amazon DynamoDB

#### Definición formal

**Amazon DynamoDB** es una base de datos **NoSQL serverless** de tipo clave-valor y documento con escalado automático, latencia de un dígito de milisegundos y opción de **Global Tables** multi-región.

#### Explicación desarrollada

Equivalente conceptual a **Azure Cosmos DB** (aunque modelos y APIs difieren).

Conceptos:

- **Partition key** (+ optional sort key): identifica item; diseño crítico para rendimiento.
- **On-demand vs provisioned capacity:** pago por request vs RCU/WCU reservadas.
- **DynamoDB Streams:** cambio de datos capturado (CDC) para Lambda.
- **Global Tables:** réplicas multi-región activo-activo.

![Diagrama](./assets/images/diagrams/embedded-21358fa9eb4e.png)

#### Cuándo usar DynamoDB

| Usa DynamoDB cuando… | Usa RDS cuando… |
|---|---|
| Acceso por clave simple, escala masiva | Joins SQL, reportes ad hoc complejos |
| Patrones serverless (Lambda + DynamoDB) | Modelo relacional normalizado |
| Latencia ms predecible a escala | ACID multi-tabla frecuente |

---

### 4.5 Amazon ElastiCache

#### Definición formal

**Amazon ElastiCache** es un servicio **managed** de cache en memoria compatible con **Redis** o **Memcached**.

#### Explicación desarrollada

Equivalente a **Azure Cache for Redis**. Casos típicos en APIs .NET:

| Caso | Patrón |
|---|---|
| Cache de catálogo | `GET /products` → Redis 60 s TTL |
| Sesión distribuida | `IDistributedCache` con StackExchange.Redis |
| Rate limiting | INCR por IP + EXPIRE |
| Leaderboard | Redis Sorted Sets |

Modos de despliegue:

- **Cluster mode disabled:** un shard, más simple.
- **Cluster mode enabled:** partición horizontal para alto throughput.
- **Memcached:** alternativa más simple sin persistencia ni estructuras ricas.

**Ejemplo C# (conceptual):**

```csharp
// Registro en Program.cs
builder.Services.AddStackExchangeRedisCache(o =>
    o.Configuration = builder.Configuration["Redis:Connection"]);

// Uso en handler
await cache.SetStringAsync($"product:{id}", json, new DistributedCacheEntryOptions {
    AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5)
});
```

#### Cuándo usar ElastiCache

| Usa ElastiCache cuando… | No uses ElastiCache como… |
|---|---|
| Lecturas repetidas que alivian RDS | Única fuente de verdad persistente |
| Latencia sub-ms en hot paths | Cola de mensajes (usa SQS) |
| Sesiones en farm de APIs | Base de datos principal |

**Recursos:** [ElastiCache for Redis](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/WhatIs.html)

---

## 5. Mensajería y eventos

### 5.1 Amazon SQS (Simple Queue Service)

#### Definición formal

**Amazon SQS** es una **cola de mensajes fully managed** con entrega **at-least-once**, visibilidad configurable y soporte para colas **Standard** (máximo throughput) y **FIFO** (orden e exactly-once processing).

#### Explicación desarrollada

Equivalente principal de **Azure Service Bus Queue**.

Conceptos esenciales para juniors:

- **Visibility timeout:** cuando un consumidor recibe un mensaje, queda invisible para otros. Si no lo elimina antes de expirar el timeout, **reaparece** en la cola (reintento).
- **Dead-Letter Queue (DLQ):** cola destino para mensajes que fallaron `maxReceiveCount` veces.
- **Long polling:** reduce requests vacíos y coste.

![Diagrama](./assets/images/diagrams/embedded-d32bfabd56b1.png)

#### Cuándo usar SQS

| Usa SQS cuando… | Usa SNS cuando… |
|---|---|
| Un consumidor procesa cada tarea | Un evento notifica a muchos suscriptores |
| Desacoplar servicios async | Fan-out a múltiples colas o Lambdas |

---

### 5.2 Amazon SNS (Simple Notification Service)

#### Definición formal

**Amazon SNS** es un servicio **pub/sub** que envía mensajes a múltiples **suscriptores** (SQS, Lambda, HTTP, email, SMS) — patrón **fan-out**.

#### Explicación desarrollada

Un publicador envía a un **topic**; SNS entrega copias a todos los suscriptores. Patrón típico: SNS → varias colas SQS (una por microservicio).

Equivalente parcial: **Service Bus Topic** o combinación **Event Grid + handlers** en Azure.

![Diagrama](./assets/images/diagrams/embedded-ac009e015c0c.png)

#### Cuándo usar SNS

Notificar múltiples sistemas del mismo evento ("pedido creado" → inventario + email + analytics).

---

### 5.3 Amazon EventBridge

#### Definición formal

**Amazon EventBridge** es un **bus de eventos serverless** que enruta eventos entre aplicaciones AWS, software SaaS y fuentes custom mediante **reglas** declarativas.

#### Explicación desarrollada

Equivalente cercano a **Azure Event Grid**. EventBridge conecta:

- Eventos de servicios AWS (EC2 state change, S3, etc.).
- Eventos custom de tu aplicación (`OrderCreated`).
- SaaS partners (Zendesk, Datadog, etc.).

Las **reglas** filtran por patrón JSON y envían a targets (Lambda, SQS, Step Functions).

![Diagrama](./assets/images/diagrams/embedded-0e04ed53e321.png)

#### Cuándo usar EventBridge

Arquitecturas event-driven, integración entre servicios, automatización sin acoplar productores a consumidores concretos.

---

### 5.4 Amazon Kinesis

#### Definición formal

**Amazon Kinesis** es una plataforma de **streaming de datos** en tiempo real que incluye **Data Streams** (ingesta custom), **Firehose** (entrega a S3/Redshift) y **Analytics** (SQL sobre streams).

#### Explicación desarrollada

Equivalente a **Azure Event Hubs**. Modelo de **log particionado** para alto throughput: telemetría, logs, clickstreams, IoT.

| Componente | Función |
|---|---|
| **Kinesis Data Streams** | Productores/consumidores custom, shards |
| **Kinesis Firehose** | ETL managed hacia S3, OpenSearch, etc. |
| **Kinesis Analytics** | Consultas SQL en streaming (Managed Service for Apache Flink) |

![Diagrama](./assets/images/diagrams/embedded-94c1cd717adc.png)

#### Cuándo usar Kinesis

| Usa Kinesis cuando… | Usa SQS cuando… |
|---|---|
| Millones de eventos/segundo | Mensajes de negocio individuales con DLQ |
| Múltiples consumidores leen mismo stream | Un worker por mensaje |

---

## 6. Identidad y seguridad

### 6.1 AWS IAM (Identity and Access Management)

#### Definición formal

**AWS IAM** es el servicio de **control de acceso** basado en **políticas JSON** que definen qué **principal** puede ejecutar qué **acción** sobre qué **recurso** bajo qué **condición**.

#### Explicación desarrollada

IAM es **transversal a todo AWS**. Elementos:

| Elemento | Descripción |
|---|---|
| **User** | Identidad humana con credenciales (evitar en prod para apps) |
| **Group** | Colección de users |
| **Role** | Identidad asumible (por EC2, Lambda, pod EKS) |
| **Policy** | Documento JSON de permisos |

Principio **least privilege:** concede solo permisos mínimos necesarios.

Ejemplo mental de policy: "Lambda role X puede `sqs:ReceiveMessage` en cola Y y `dynamodb:PutItem` en tabla Z".

![Diagrama](./assets/images/diagrams/embedded-85db5ca4cc7a.png)

#### Cuándo aplicar IAM correctamente

Siempre. Errores comunes de juniors: access keys en código, policies `*` demasiado amplias, usar root account para tareas diarias.

---

### 6.2 IRSA (IAM Roles for Service Accounts)

#### Definición formal

**IRSA** es el mecanismo en **EKS** que permite a un **pod** asumir un **rol IAM** mediante el proveedor OIDC del clúster, sin almacenar access keys en el contenedor.

#### Explicación desarrollada

Equivalente a **Managed Identity / Workload Identity** en Azure AKS.

Flujo:

1. Service Account del pod anotado con ARN del rol IAM.
2. Pod solicita token OIDC al metadata del clúster.
3. STS de AWS intercambia token por credenciales temporales del rol.
4. SDK AWS en .NET usa esas credenciales para S3, SQS, etc.

**Anotación en ServiceAccount (conceptual):**

```yaml
metadata:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/orders-api-s3-reader
```

En .NET con AWS SDK, no configuras access keys: el SDK detecta el rol vía variables de entorno inyectadas por el agente EKS.

#### Cuándo usar IRSA

| Usa IRSA cuando… | Evita access keys cuando… |
|---|---|
| Pods en EKS acceden a S3, SQS, DynamoDB | Siempre — keys en Secret son riesgo de fuga |
| Necesitas permisos distintos por microservicio | Un solo rol amplio para todo el clúster |

**Recursos:** [IAM Roles for Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)

---

### 6.3 AWS Secrets Manager y SSM Parameter Store

#### Definición formal

**AWS Secrets Manager** almacena secretos con **rotación automática** opcional e integración con RDS. **Systems Manager Parameter Store** almacena configuración y secretos (Standard sin coste, Advanced con cifrado KMS).

#### Explicación desarrollada

Equivalentes a **Azure Key Vault**. Diferencias prácticas:

| Servicio | Fortaleza |
|---|---|
| **Secrets Manager** | Rotación automática de credenciales RDS, versionado, auditoría |
| **Parameter Store** | Config no sensible (`/app/prod/FeatureFlags`) y secretos simples (Standard gratis, Advanced cifrado con KMS) |

**Ejemplo** — Lambda o ECS leyendo secreto:

```csharp
// AWS SDK for .NET — GetSecretValueAsync
var client = new AmazonSecretsManagerClient();
var response = await client.GetSecretValueAsync(new GetSecretValueRequest {
    SecretId = "prod/orders/db-connection"
});
var connectionString = response.SecretString;
```

En producción, inyecta secretos como variables de entorno en task definition o usa sidecar/init container; no los commitees en imágenes Docker.

#### Cuándo usar cada uno

| Secrets Manager | Parameter Store |
|---|---|
| Rotación automática de password RDS | Parámetros de configuración por entorno |
| Secretos con ciclo de vida formal | Alto volumen de parámetros con coste mínimo |

**Recursos:** [Secrets Manager](https://docs.aws.amazon.com/secretsmanager/) | [Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)

---

### 6.4 AWS KMS (Key Management Service)

#### Definición formal

**AWS KMS** es un servicio **managed** de creación y control de **claves de cifrado** usadas por servicios AWS y aplicaciones para cifrar datos en reposo y firmar digitalmente.

#### Explicación desarrollada

KMS no es un almacén de secretos como Secrets Manager: gestiona **llaves criptográficas** que otros servicios usan para cifrar.

Usos frecuentes:

| Uso | Servicio que lo consume |
|---|---|
| Cifrado de bucket S3 | SSE-KMS (`aws:kms`) |
| Cifrado de disco EBS | Volumen attachado a EC2 |
| Cifrado de secretos | Secrets Manager, Parameter Store Advanced |
| Cifrado de RDS/Aurora | Transparent encryption at rest |

Conceptos:

- **CMK (Customer Master Key):** llave lógica; la material nunca sale de KMS.
- **Envelope encryption:** datos cifrados con data key; data key cifrada con CMK.
- **IAM policies + key policies:** quién puede `kms:Decrypt`, `kms:GenerateDataKey`.

Para juniors: si S3 o RDS dice "encrypted with KMS", significa que sin permiso `kms:Decrypt` en tu rol IAM no podrás leer datos aunque tengas acceso al bucket.

#### Cuándo usar KMS

Siempre que políticas de seguridad exijan cifrado en reposo con llaves controladas por el cliente (no solo las managed keys por defecto de AWS).

**Recursos:** [KMS concepts](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html)

---

## 7. Red

### 7.1 Amazon VPC (Virtual Private Cloud)

#### Definición formal

**Amazon VPC** es una red virtual aislada en AWS con CIDR propio, **subnets** públicas y privadas, **route tables**, **Internet Gateway (IGW)**, **NAT Gateway** y **security groups**.

#### Explicación desarrollada

Equivalente a **Azure VNet**. Patrón típico producción:

- Subnet **pública:** load balancers, NAT Gateway.
- Subnet **privada:** EC2, ECS tasks, RDS (sin IP pública directa).

![Diagrama](./assets/images/diagrams/embedded-8788c7467f39.png)

---

### 7.2 Elastic Load Balancing

#### Definición formal

AWS ofrece tres balanceadores:

| Balanceador | Capa | Uso |
|---|---|---|
| **ALB (Application Load Balancer)** | L7 HTTP/HTTPS | Routing por path/host, APIs REST |
| **NLB (Network Load Balancer)** | L4 TCP/UDP | Ultra baja latencia, millones de conexiones |
| **GLB (Gateway Load Balancer)** | L3/L4 | Appliances de seguridad inline |

#### Explicación desarrollada

ALB es el más común para APIs .NET en ECS/EKS/EC2. Termina TLS, health checks en `/health`, routing `/api/*` vs `/static/*`.

**Ejemplo de listener rules (mental):**

| Condición | Destino |
|---|---|
| Host `api.tienda.com` + path `/orders/*` | Target group Orders (puerto 8080) |
| Host `api.tienda.com` + path `/catalog/*` | Target group Catalog |
| Default | 404 fixed response |

NLB se usa cuando necesitas TCP puro, IPs estáticas por AZ o latencia extremadamente baja (gaming, trading). GLB integra appliances de seguridad de terceros en línea.

Integración con ECS: el **Service** registra tasks en el target group; ALB solo envía tráfico a tasks healthy.

#### Cuándo usar cada balanceador

| ALB | NLB | GLB |
|---|---|---|
| APIs HTTP/HTTPS REST | TCP/UDP, TLS passthrough | Firewalls virtuales inline |
| Path/host routing | Millones de conexiones largas | Inspección de paquetes centralizada |

**Recursos:** [Elastic Load Balancing](https://docs.aws.amazon.com/elasticloadbalancing/)

---

### 7.3 Amazon Route 53

#### Definición formal

**Amazon Route 53** es el servicio DNS escalable de AWS que ofrece **hosted zones**, registro de dominios, **health checks** y **routing policies** avanzadas (weighted, latency, failover, geolocation).

#### Explicación desarrollada

Route 53 resuelve nombres a recursos AWS o externos. Más que un DNS estático, permite **enrutar tráfico de forma inteligente**.

Políticas de routing útiles:

| Política | Uso |
|---|---|
| **Simple** | Un registro A → ALB |
| **Weighted** | 90 % tráfico a región A, 10 % canary región B |
| **Latency** | Usuario va al endpoint con menor RTT |
| **Failover** | Primary ALB; si health check falla → secondary |
| **Geolocation** | EU users → `eu-west-1`, US → `us-east-1` |

Health checks: Route 53 hace HTTP/TCP periódico a tu endpoint; si falla, deja de devolver esa IP en políticas failover/latency.

Ejemplo: `api.miempresa.com` CNAME/alias a ALB en `us-east-1`; registro failover apunta a ALB de `us-west-2` si el primario no responde.

#### Cuándo usar Route 53

| Usa Route 53 cuando… | DNS externo (Cloudflare) cuando… |
|---|---|
| Arquitectura multi-región AWS nativa | Ya usas proxy CDN/WAF del proveedor DNS |
| Failover y weighted routing integrados | Política corporativa fija otro DNS |

**Recursos:** [Route 53 routing policies](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy.html)

---

### 7.4 Amazon CloudFront

#### Definición formal

**Amazon CloudFront** es una **CDN (Content Delivery Network)** global con **edge locations** que cachea contenido cerca del usuario, reduce latencia y se integra con S3, ALB, API Gateway y **AWS WAF**.

#### Explicación desarrollada

Equivalente a **Azure Front Door / CDN**. CloudFront no solo cachea estáticos: puede ser **front door** de tu API con TLS en el edge.

Componentes:

| Componente | Rol |
|---|---|
| **Distribution** | Configuración global CDN |
| **Origin** | S3 bucket, ALB, custom HTTP |
| **Behavior** | Path pattern, TTL cache, métodos HTTP permitidos |
| **WAF Web ACL** | Reglas OWASP en el edge |

Patrones:

- **SPA + API:** `/*` estáticos desde S3 (cache largo); `/api/*` forward a ALB (cache none).
- **Signed URLs:** contenido privado en S3 accesible solo con URL firmada.
- **DDoS:** AWS Shield Standard incluido; CloudFront absorbe mucho tráfico malicioso en edge.

Para APIs .NET dinámicas, normalmente **no cacheas** `POST/PUT`; sí puedes cachear `GET` públicos con TTL corto si son idempotentes.

#### Cuándo usar CloudFront

| Usa CloudFront cuando… | ALB directo basta cuando… |
|---|---|
| Usuarios globales, latencia importa | Todos los usuarios en una región |
| Estáticos + API bajo mismo dominio | API interna solo en VPC |
| WAF y Shield en el perímetro | Tráfico bajo, sin requisito CDN |

**Recursos:** [CloudFront developer guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/)

---

## 8. Observabilidad

### 8.1 Amazon CloudWatch

#### Definición formal

**Amazon CloudWatch** recopila **métricas**, **logs** y **alarmas** de servicios AWS y aplicaciones custom (métricas embebidas, agent en EC2).

#### Explicación desarrollada

Equivalente central a **Azure Monitor**. Componentes:

| Componente | Función | Ejemplo .NET |
|---|---|---|
| **Metrics** | Series temporales (1 min) | `AWS/Lambda` Duration p99 |
| **Logs** | Log Groups / Streams | stdout de contenedor ECS |
| **Alarms** | Umbral → SNS/autoscaling | CPU > 70 % 5 min |
| **Dashboards** | Vista operativa | RPS, errores, latencia |
| **Container Insights** | Métricas pods EKS | CPU/mem por namespace |

**Ejemplo de consulta Logs Insights:**

```sql
fields @timestamp, @message
| filter @message like /Exception/
| sort @timestamp desc
| limit 50
```

En .NET publica métricas custom con `AmazonCloudWatchClient.PutMetricData` o OpenTelemetry exporter. Correlaciona con X-Ray para trazas distribuidas.

#### Cuándo usar CloudWatch

Base obligatoria en AWS. Complementa con X-Ray (trazas) y CloudTrail (auditoría API), no los sustituye.

**Recursos:** [CloudWatch documentation](https://docs.aws.amazon.com/cloudwatch/)

---

### 8.2 AWS X-Ray

#### Definición formal

**AWS X-Ray** proporciona **trazas distribuidas**, mapa de servicios y análisis de latencia para aplicaciones en Lambda, ECS, EKS y EC2.

#### Explicación desarrollada

Equivalente a **Application Insights** para trazas. SDK X-Ray en .NET propaga segmentos entre API → SQS → Lambda → DynamoDB.

![Diagrama](./assets/images/diagrams/embedded-1e5e436bcb30.png)

---

### 8.3 AWS CloudTrail

#### Definición formal

**AWS CloudTrail** registra **llamadas a la API de AWS** (quién, qué acción, cuándo, desde qué IP, éxito/fallo) y entrega un historial auditable para seguridad y compliance.

#### Explicación desarrollada

CloudTrail responde: "¿Quién eliminó el bucket S3 de producción a las 3 AM?". No es log de aplicación (eso es CloudWatch Logs); es **auditoría del plano de control**.

Eventos típicos registrados:

- `RunInstances`, `TerminateInstances` (EC2).
- `CreateCluster`, `DeleteCluster` (EKS).
- `PutBucketPolicy` (S3).
- `AssumeRole` (STS) — crítico para detectar uso indebido de roles.

Configuración recomendada:

- **Trail multi-región** habilitado en la cuenta.
- Logs a bucket S3 cifrado con KMS + retención.
- Integración con CloudWatch Logs para alertas (`ConsoleLogin` sin MFA).

#### Cuándo usar CloudTrail

Siempre en cuentas AWS de producción. Requisito habitual en SOC2, ISO 27001 y revisiones de seguridad.

**Recursos:** [CloudTrail user guide](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/)

---

## 9. DevOps

### 9.1 Amazon ECR (Elastic Container Registry)

#### Definición formal

**Amazon ECR** es un registro **privado** de imágenes Docker/OCI totalmente integrado con IAM, ECS, EKS y pipelines CI/CD, con escaneo de vulnerabilidades y políticas de ciclo de vida.

#### Explicación desarrollada

Equivalente a **ACR** (capítulo 05). URI típico: `123456789012.dkr.ecr.us-east-1.amazonaws.com/orders-api:v1`.

Flujo:

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
docker build -t orders-api:local .
docker tag orders-api:local <account>.dkr.ecr.us-east-1.amazonaws.com/orders-api:v1
docker push <account>.dkr.ecr.us-east-1.amazonaws.com/orders-api:v1
```

ECS/EKS task definitions referencian la imagen por URI; el **task execution role** necesita `ecr:GetDownloadUrlForLayer` y `ecr:BatchGetImage`.

Lifecycle policies eliminan tags antiguos automáticamente (ahorro de coste).

#### Cuándo usar ECR

Siempre que despliegues contenedores .NET en ECS/EKS en AWS. No publiques imágenes propietarias solo en Docker Hub.

**Recursos:** [ECR user guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/)

---

### 9.2 AWS CodePipeline, CodeBuild, CodeDeploy

#### Definición formal

La suite **CI/CD nativa AWS** compuesta por **CodeBuild** (compilación y tests), **CodePipeline** (orquestación de stages) y **CodeDeploy** (despliegue a EC2, ECS, Lambda, on-premise).

#### Explicación desarrollada

Alternativa a GitHub Actions cuando todo vive en AWS. Pipeline típico para API .NET en ECS:

| Stage | Servicio | Acción |
|---|---|---|
| Source | CodeCommit / GitHub | Trigger en push a `main` |
| Build | CodeBuild | `dotnet test`, `docker build`, `docker push` ECR |
| Deploy | CodeDeploy / ECS | Nueva task definition, rolling update |

**buildspec.yml** (fragmento CodeBuild):

```yaml
version: 0.2
phases:
  pre_build:
    commands:
      - aws ecr get-login-password | docker login ...
  build:
    commands:
      - dotnet publish Orders.Api -c Release -o publish
      - docker build -t $IMAGE_URI .
  post_build:
    commands:
      - docker push $IMAGE_URI
artifacts:
  files: imagedefinitions.json
```

Muchos equipos prefieren **GitHub Actions + OIDC → AWS** por ecosistema; CodePipeline brilla en cuentas con compliance que exigen servicios AWS-managed end-to-end.

#### Cuándo usar suite Code*

| Usa CodePipeline cuando… | Usa GitHub Actions cuando… |
|---|---|
| Política "solo servicios AWS" | Repos y PRs ya en GitHub |
| Integración con CodeCommit | Marketplace de actions más amplio |

**Recursos:** [CodePipeline](https://docs.aws.amazon.com/codepipeline/)

---

### 9.3 CloudFormation, CDK, Terraform

#### Definición formal

**AWS CloudFormation** declara infraestructura en YAML/JSON (IaC nativo). **AWS CDK** genera CloudFormation desde lenguajes de programación (TypeScript, Python, **C#**). **Terraform** usa HCL y proveedor AWS para IaC multicloud.

#### Explicación desarrollada

Equivalente a **Bicep/ARM** en Azure. CloudFormation crea **stacks** con rollback automático si un recurso falla.

**Ejemplo CDK C# (conceptual):**

```csharp
var cluster = new Cluster(this, "ShopCluster", new ClusterProps {
    Vpc = vpc,
    Version = KubernetesVersion.Of("1.29")
});
```

Ventajas CDK: loops, condicionales, unit tests con familiaridad .NET. Terraform domina cuando el mismo equipo gestiona AWS + Azure + on-prem con un solo estado.

#### Cuándo usar cada herramienta

| CloudFormation/CDK | Terraform |
|---|---|
| Solo AWS, features día 0 | Multicloud, módulos maduros compartidos |
| CDK si el equipo es .NET/TS | Estado remoto S3 + DynamoDB lock |

**Recursos:** [AWS CDK](https://docs.aws.amazon.com/cdk/) | [CloudFormation](https://docs.aws.amazon.com/cloudformation/)

---

### 9.4 eksctl

#### Definición formal

**eksctl** es la CLI oficial del proyecto **eksctl** (Weaveworks / AWS) para crear, actualizar y gestionar clústeres **Amazon EKS** de forma declarativa mediante archivos YAML o flags.

#### Explicación desarrollada

Crear un clúster EKS manualmente implica IAM, VPC, subnets, security groups, node groups y addons. `eksctl` reduce eso a un comando o archivo `ClusterConfig`.

**Ejemplo:**

```bash
eksctl create cluster \
  --name shopdemo \
  --region us-east-1 \
  --nodegroup-name standard \
  --node-type t3.medium \
  --nodes 3
```

O declarativo (`cluster.yaml`):

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: shopdemo
  region: us-east-1
managedNodeGroups:
  - name: ng-1
    instanceType: t3.medium
    desiredCapacity: 3
```

Complementa (no reemplaza) kubectl y Helm: eksctl provisiona infraestructura; kubectl despliega aplicaciones.

#### Cuándo usar eksctl

| Usa eksctl cuando… | Usa CDK/Terraform cuando… |
|---|---|
| Laboratorio EKS rápido | IaC completo de toda la landing zone |
| Equipo DevOps prefiere CLI + YAML eksctl | Política enterprise unifica Terraform |

**Recursos:** [eksctl documentation](https://eksctl.io/)

---

## 10. Tabla de equivalencias Azure ↔ AWS

| Concepto | Azure | AWS |
|---|---|---|
| Kubernetes gestionado | AKS | EKS |
| Registro de contenedores | ACR | ECR |
| Cola de mensajes | Service Bus | SQS |
| Pub/sub | Service Bus Topic / Event Grid | SNS / EventBridge |
| Streaming | Event Hubs | Kinesis |
| Serverless compute | Azure Functions | Lambda |
| SQL PaaS | Azure SQL | RDS / Aurora |
| NoSQL global | Cosmos DB | DynamoDB |
| Cache | Azure Cache for Redis | ElastiCache |
| Identidad workload | Managed Identity | IAM Role / IRSA |
| Secretos | Key Vault | Secrets Manager |
| APM / trazas | Application Insights | X-Ray |
| Object storage | Blob Storage | S3 |
| CDN + WAF | Front Door | CloudFront + WAF |
| VM IaaS | Virtual Machines | EC2 |
| Contenedores serverless | Container Apps | Fargate |
| API serverless HTTP | Functions + APIM | Lambda + API Gateway |
| DNS | Azure DNS | Route 53 |
| Red privada | VNet | VPC |

**Importante:** equivalencia ≠ intercambiable sin cambios. APIs, pricing, límites y operación difieren.

---

## 11. Resiliencia y costes

### 11.1 Multi-AZ

#### Definición formal

**Multi-AZ** despliega recursos replicados en **Availability Zones distintas** dentro de la misma región para tolerar fallo de un datacenter.

#### Explicación desarrollada

Ejemplo: RDS Multi-AZ mantiene réplica sincrónica en otra AZ; si primary falla, failover automático. Protege contra fallo de edificio, no de región entera.

---

### 11.2 Multi-Region

#### Definición formal

**Multi-Region** replica servicios en **regiones geográficas distintas** para disaster recovery geográfico y baja latencia global.

Complejidad: replicación de datos, conflictos de escritura, coste duplicado.

![Diagrama](./assets/images/diagrams/embedded-70557c91f63e.png)

---

### 11.3 Modelos de precio compute

| Modelo | Descripción | Cuándo |
|---|---|---|
| **On-Demand** | Pago por hora/segundo sin compromiso | Cargas impredecibles, desarrollo |
| **Reserved Instances / Savings Plans** | Compromiso 1–3 años, descuento | Carga estable producción |
| **Spot Instances** | Capacidad sobrante barata; puede interrumpirse | Batch, workers tolerantes a fallos |

---

## 12. Diagrama: stack típico con EKS

![Diagrama: 06-aws-stack](./assets/images/diagrams/06-aws-stack.png)

> *Fuente editable (Mermaid):* [06-aws-stack.mermaid](./assets/diagrams/06-aws-stack.mermaid)

**Lectura del flujo:**

1. Pipeline compila .NET, construye imagen, push a ECR.
2. Despliegue en EKS (kubectl/Helm/GitOps).
3. Pods con IRSA leen Secrets Manager.
4. Comunicación async via SQS (+ DLQ).
5. Datos en RDS/Aurora.
6. Métricas, logs y alarmas en CloudWatch; trazas opcionales en X-Ray.

---

## 13. Resumen del capítulo

- **AWS** organiza servicios por dominio; **IAM** es transversal a todos.
- **Compute:** EC2 (IaaS), Fargate/ECS (contenedores sin K8s), EKS (Kubernetes), Lambda (serverless).
- **Datos:** S3 (objetos), RDS/Aurora (SQL), DynamoDB (NoSQL escalable), ElastiCache (Redis).
- **Mensajería:** SQS (colas), SNS (fan-out), EventBridge (bus eventos), Kinesis (streaming masivo).
- **Seguridad:** IAM roles > access keys; IRSA en EKS; Secrets Manager + KMS.
- **Observabilidad:** CloudWatch (métricas/logs), X-Ray (trazas), CloudTrail (auditoría API).
- **Resiliencia:** Multi-AZ = HA regional; Multi-Region = DR geográfico; Spot/Reserved = optimización coste.
- Las **equivalencias con Azure** ayudan a transferir conocimiento, pero siempre valida detalles operativos.

**Siguiente paso:** capítulo 07 — **contenedores y Docker**: empaquetar tus APIs .NET en imágenes antes de orquestarlas con Kubernetes.
