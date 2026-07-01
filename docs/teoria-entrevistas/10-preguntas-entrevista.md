# 10 — Preguntas de entrevista (repaso integrado)

**Objetivo:** Simular entrevista técnica con respuestas modelo basadas en ShopDemo.

Usa este documento **después** de leer los capítulos 01–09. Oculta las respuestas y responde en voz alta o por escrito.

---

## A. Patrones y .NET

**P1.** ¿Qué patrón implementa MediatR en Catalog?

<details>
<summary>Respuesta modelo</summary>

**Mediator.** Desacopla controllers de handlers; cada command/query tiene un handler dedicado (Single Responsibility, Open/Closed).
</details>

**P2.** ¿Repository y Unit of Work cómo colaboran al crear un producto?

<details>
<summary>Respuesta modelo</summary>

El handler usa `IProductRepository` para agregar el agregado y `IUnitOfWork.SaveChangesAsync()` para commit transaccional en una sola unidad de persistencia.
</details>

**P3.** ¿FluentValidation vs validación en el dominio?

<details>
<summary>Respuesta modelo</summary>

FluentValidation valida **entrada** (commands/DTOs). El dominio valida **invariantes** (Value Objects, reglas del agregado). Ambas capas complementarias.
</details>

---

## B. Arquitectura y DDD

**P4.** ¿Por qué Inventory es hexagonal y Catalog Clean?

<details>
<summary>Respuesta modelo</summary>

Decisión pedagógica: comparar estilos en un mismo sistema. Inventory enfatiza puertos/adaptadores; Catalog capas clásicas con CQRS. Ambos respetan dominio en el centro.
</details>

**P5.** ¿Qué es un bounded context? Nómbralos en ShopDemo.

<details>
<summary>Respuesta modelo</summary>

Límite lingüístico y de modelo: Catalog (productos), Orders (pedidos), Inventory (stock). Analytics es contexto de lectura/observación, no de negocio transaccional core.
</details>

**P6.** ¿Aggregate root y por qué no exponer entidades hijas?

<details>
<summary>Respuesta modelo</summary>

Raíz controla consistencia del cluster de objetos (ej. `Order` con líneas). Modificaciones externas directas romperían invariantes.
</details>

---

## C. Microservicios y mensajería

**P7.** ¿HTTP vs Event Hubs en ShopDemo?

<details>
<summary>Respuesta modelo</summary>

HTTP cuando necesitas **respuesta inmediata** (reservar stock al confirmar). Eventos para **desacoplar** publicadores de múltiples consumidores (auto-stock + analytics) con consistencia eventual.
</details>

**P8.** ¿Para qué sirven los consumer groups?

<details>
<summary>Respuesta modelo</summary>

Cada group mantiene **offset independiente** del mismo hub. `inventory-service` y `analytics-service` procesan el mismo evento sin competir por lectura.
</details>

**P9.** ¿Qué es consistencia eventual y dónde la ves?

<details>
<summary>Respuesta modelo</summary>

El stock puede aparecer segundos después del producto si solo hay evento. Orders→Inventory HTTP busca consistencia fuerte en la transacción de reserva.
</details>

---

## D. Azure

**P10.** ¿ACA vs AKS — cuándo recomiendas cada uno?

<details>
<summary>Respuesta modelo</summary>

ACA: equipos que quieren PaaS, deploy rápido, menos YAML. AKS: necesidad de Kubernetes estándar, Ingress unificado, HPA, portabilidad con EKS.
</details>

**P11.** ¿Por qué Storage Account en ACA y Azurite en AKS para checkpoints?

<details>
<summary>Respuesta modelo</summary>

ACA no tiene Azurite in-cluster; usa Blob Azure real. AKS usa Azurite como sidecar/job in-cluster, alineado con el modelo K8s del curso.
</details>

---

## E. AWS

**P12.** ¿Cloud Map vs Service K8s?

<details>
<summary>Respuesta modelo</summary>

Cloud Map: DNS privado para ECS (`inventory.shopdemo.local`). K8s: DNS interno automático `servicio.namespace.svc.cluster.local`.
</details>

**P13.** ¿Por qué Event Hubs en Azure si el compute está en AWS?

<details>
<summary>Respuesta modelo</summary>

Lab **multicloud**: demuestra integración cross-cloud. Producción podría usar SNS/SQS, Kafka o Event Bridge según estrategia.
</details>

---

## F. Kubernetes

**P14.** ¿Readiness vs liveness?

<details>
<summary>Respuesta modelo</summary>

Readiness: pod recibe tráfico (`/health`). Liveness: kubelet reinicia si falla (`/alive`). Un pod puede estar live pero not ready (arranque DB).
</details>

**P15.** ¿Por qué `k8s/azure/` y `k8s/aws/` separados?

<details>
<summary>Respuesta modelo</summary>

Imágenes de registro distinto (ACR vs ECR). Aplicar YAML incorrecto causa `ImagePullBackOff`.
</details>

---

## G. CI/CD

**P16.** ¿Qué dispara los workflows de ShopDemo?

<details>
<summary>Respuesta modelo</summary>

Push/merge a `main` con path filters (`Catalog/**`, `k8s/**`, etc.). También `workflow_dispatch` manual.
</details>

**P17.** ¿Qué hace el job `sync_secrets`?

<details>
<summary>Respuesta modelo</summary>

Escribe Secret Kubernetes `shopdemo-secrets` desde GitHub secrets (Event Hubs, PG, Azurite checkpoint) vía script `sync-k8s-secrets.sh`.
</details>

---

## H. IA / MCP

**P18.** ¿MCP Gateway vs BFF?

<details>
<summary>Respuesta modelo</summary>

MCP Gateway expone **tools estandarizados para agentes IA** (protocolo MCP). Un BFF agrega APIs para **clientes front-end** humanos. Propósitos distintos; pueden coexistir.
</details>

---

## J. Observabilidad y resiliencia

> Detalle ampliado: [11-observabilidad-resiliencia.md](./11-observabilidad-resiliencia.md)

**P21.** ¿Observabilidad vs monitorización?

<details>
<summary>Respuesta modelo</summary>

Monitorización: detectar síntomas (salud, umbrales). Observabilidad: inferir causa interna con logs, métricas y trazas correlacionadas. ShopDemo: health + `traceId` + logs estructurados; OTEL en Aspire.
</details>

**P22.** ¿Readiness vs liveness con ejemplo ShopDemo?

<details>
<summary>Respuesta modelo</summary>

`/health` → readiness: el pod recibe tráfico del Service/Ingress. `/alive` → liveness: si falla, Kubernetes **reinicia** el contenedor. Durante arranque lento de PG, un pod puede estar live pero not ready.
</details>

**P23.** ¿Cómo investigar un 500 al confirmar pedido?

<details>
<summary>Respuesta modelo</summary>

1) Copiar `traceId` del JSON de error. 2) Logs de Orders e Inventory (Log Analytics / CloudWatch / kubectl). 3) Estado pods Inventory. 4) Métricas reinicios/latencia. 5) Verificar `/health` Inventory.
</details>

**P24.** ¿Qué aporta Event Hubs a la resiliencia frente a solo HTTP?

<details>
<summary>Respuesta modelo</summary>

Desacoplamiento temporal: Catalog publica aunque Inventory esté caído; el consumer procesa cuando vuelve (consistencia eventual). HTTP Orders→Inventory sigue siendo acoplamiento fuerte en confirmación.
</details>

---

## I. Escenario sistema (pregunta senior)

**P19.** Un alumno despliega en AKS pero usa manifiestos de `k8s/aws/`. ¿Qué síntoma y solución?

<details>
<summary>Respuesta modelo</summary>

`ImagePullBackOff` — kubelet no puede pull de ECR. Solución: aplicar `k8s/azure/` con URIs ACR; verificar attach-acr y que la imagen exista en ACR.
</details>

**P20.** Diseña en 2 minutos el flujo desde `POST /api/products` hasta ver el evento en Analytics.

<details>
<summary>Respuesta modelo</summary>

Catalog persiste producto → publica domain event → adaptador envía `IntegrationEventEnvelope` a Event Hubs → consumer `analytics-service` en Analytics processor → evento en buffer → `GET /api/analytics/events`. En paralelo `inventory-service` puede crear stock.
</details>

---

## Checklist final antes de entrevista

- [ ] Explico Clean vs Hexagonal con ejemplo de carpeta
- [ ] Dibujo bounded contexts sin mirar
- [ ] Secuencia E2E con y sin Event Hubs
- [ ] Nombro 4 servicios Azure y 4 AWS del lab
- [ ] Explico Ingress + paths en AKS
- [ ] Explico observabilidad (métricas, logs, trazas) con ejemplo ShopDemo
- [ ] Diferencio `/health` y `/alive` y su probe K8s
- [ ] Describo playbook de incidente con traceId
- [ ] Nombro fortaleza y hueco de resiliencia del lab (retry/CB)

**Siguiente paso:** [EXAMEN-TEORICO-SHOPDEMO.md](../EXAMEN-TEORICO-SHOPDEMO.md) para evaluación formal.
