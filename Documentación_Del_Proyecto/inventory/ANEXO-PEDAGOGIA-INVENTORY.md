# Anexo — Pedagogía: Inventory (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | C — Objetivos del curso |
| **Audiencia** | Instructor y alumno |

---

## 1. Objetivos de aprendizaje

Al completar esta implementación, el alumno será capaz de:

1. Implementar **arquitectura hexagonal** con puertos de entrada y salida explícitos.
2. Diferenciar **driving adapters** (API HTTP) de **driven adapters** (EF Core, event logger).
3. Integrar bounded contexts sin acoplar dominios (comunicación por contratos HTTP).
4. Modelar **StockEntry** como agregado de inventario.
5. Relacionar los tres microservicios en un flujo de e-commerce coherente.
6. Comparar hexagonal con Clean Architecture usada en Catalog y Orders.

---

## 2. Contexto pedagógico

Inventory es el **tercer bounded context** del curso. Introduce arquitectura hexagonal como contraste pedagógico con Clean Architecture.

| Aspecto | Detalle del curso |
|---|---|
| Posición en el roadmap | Etapa 3 |
| Arquitectura enseñada | Hexagonal (Ports & Adapters) |
| Contraste | Catalog y Orders usan Clean Architecture + CQRS |
| Integración | Orders invoca Inventory por HTTP al confirmar/cancelar |

---

## 3. Alcance pedagógico vs. producto

| Tema | En el curso | Fuera del curso |
|---|---|---|
| Outbox Pattern | No | Garantías exactly-once |
| Multi-almacén | No | Logística avanzada |
| Event Hubs consumer | Etapas 5–11 | No obligatorio en MVP Inventory |
| Sincronización automática Catalog→Inventory | Manual en MVP | Producción con eventos |

---

## 4. Entregables del alumno

| # | Entregable |
|---|---|
| 1 | Código fuente en los 4 proyectos `ShopDemo.Inventory.*` |
| 2 | Migración EF Core aplicada |
| 3 | `docker-compose.yml` funcional |
| 4 | Captura de Swagger con endpoints de stock y reservas |
| 5 | Captura de pgAdmin mostrando `ShopDemoInventory` (puerto 5435) |
| 6 | Flujo E2E verificado: Catalog → Inventory → Orders (confirmar/cancelar) |

---

## 5. Preguntas de reflexión

1. ¿En hexagonal, quién define el contrato: el adaptador o el núcleo?
2. ¿Por qué el Controller no debe conocer `StockEntryRepository` directamente?
3. ¿Qué diferencia hay entre Clean Architecture y Hexagonal en la práctica .NET?
4. ¿Por qué Inventory usa `ProductId` de Catalog sin referenciar su agregado `Product`?
5. ¿Cuándo conviene HTTP síncrono (Orders→Inventory) frente a eventos asíncronos (Event Hubs)?

---

## 6. Referencias de estudio

- [IMPLEMENTACION-INVENTORY.md](./IMPLEMENTACION-INVENTORY.md)
- [ANEXO-ESPECIFICACION-TECNICA-INVENTORY.md](./ANEXO-ESPECIFICACION-TECNICA-INVENTORY.md)
- [ANEXO-ESPECIFICACION-TECNICA-ORDERS.md](../orders/ANEXO-ESPECIFICACION-TECNICA-ORDERS.md)
- [Documentación_De_Estudio_Del_Curso/02-arquitecturas-software.md](../../Documentación_De_Estudio_Del_Curso/02-arquitecturas-software.md)
- [Documentación_De_Estudio_Del_Curso/03-ddd-domain-driven-design.md](../../Documentación_De_Estudio_Del_Curso/03-ddd-domain-driven-design.md)
