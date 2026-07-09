-- Se ejecuta solo en la primera inicialización del volumen de datos.
-- POSTGRES_DB ya crea ShopDemoCatalog; este script asegura permisos del esquema.

\connect ShopDemoCatalog

GRANT ALL ON SCHEMA public TO "ShopDemo";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO "ShopDemo";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO "ShopDemo";
