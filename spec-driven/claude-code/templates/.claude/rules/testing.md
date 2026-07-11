# Testing — ShopDemo

- Run `dotnet build Source/ShopDemo.slnx` after C# changes
- E2E: Postman collection `Documentación_Del_Proyecto/ShopDemo.postman_collection.json`
- K8s: `kubectl get pods -n shopdemo` after manifest changes
- Health: `curl` `/health` on affected API ports
- Do not add trivial unit tests unless SPEC requires them
