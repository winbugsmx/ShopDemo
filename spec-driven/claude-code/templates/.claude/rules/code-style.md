# Code style — ShopDemo

- C# 12 / .NET 10, nullable enabled
- `sealed` classes where existing code uses them
- Primary constructors for DI when matching surrounding files
- No verbose comments; explain only non-obvious domain rules
- Match folder naming per service (Catalog uses `Infraestructure` spelling)
