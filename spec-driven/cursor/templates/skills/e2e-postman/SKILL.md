---
name: e2e-postman
description: Run and validate ShopDemo E2E purchase flow with Postman collection. Use for integration testing.
---

# E2E Postman flow

1. Ensure services running (local, Aspire, or cloud URLs in Postman variables)
2. Collection: `Documentación_Del_Proyecto/ShopDemo.postman_collection.json`
3. Run folder **Flujo integrado (E2E)** in order
4. Update `productId` and `orderId` from responses
5. With Event Hubs: optional step 2 (stock); use Analytics step 2b

Reference: `Documentación_Del_Proyecto/GUIA-ENDPOINTS.md`
