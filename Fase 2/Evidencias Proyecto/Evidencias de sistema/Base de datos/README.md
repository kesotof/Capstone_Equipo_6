# Scripts de base de datos y servicios

Scripts para crear desde cero el almacenamiento del sistema y dejarlo en su estado inicial.

| Orden | Archivo | Qué hace | Se ejecuta con |
|---|---|---|---|
| 0 | `00_crear_bases_datos.sql` | Crea las bases `keycloak_db` y `sistema_db` y sus usuarios | Superusuario `postgres` |
| 1 | `01_creacion_bd.sql` | Limpia `sistema_db` y crea el modelo completo: 26 tablas, 10 vistas, funciones y triggers | `sistema_user` |
| 2 | `02_poblamiento_bd.sql` | Carga los catálogos estándar y el administrador global | `sistema_user` |
| 3 | `03_keycloak_realm_capstone.json` | Realm de Keycloak: cliente, rol `ADMIN`, bloqueo tras 4 intentos y administrador global | Lo importa el paso 4 |
| 4 | `04_configuracion_servicios.sh` | Importa el realm, activa el aviso de bloqueo y crea el bucket privado de MinIO | Bash, con los contenedores del sistema en ejecución |

## Ejecución

Con el entorno levantado (`docker compose up -d`):

```bash
docker exec -i capstone-postgres psql -U postgres -d postgres < 00_crear_bases_datos.sql
docker exec -i capstone-postgres psql -U sistema_user -d sistema_db < 01_creacion_bd.sql
docker exec -i capstone-postgres psql -U sistema_user -d sistema_db < 02_poblamiento_bd.sql
./04_configuracion_servicios.sh --reemplazar-realm
```

Después, reiniciar el backend (`docker compose restart sistema-principal`).

## Estado inicial

Datos estándar que se cargan:

- Estados y acciones de la máquina de estados de las solicitudes.
- Permisos y roles de sistema: Jefatura de área, Administrador de área, Lector, Auditor y Administrador del sistema.
- Tipos de evento de auditoría y tipos de notificación.
- Tipos de documento con su plazo SLA: Contrato (5 días hábiles), Factura (3), Informe (7), Memorando (2) y General (5).
- Flujo global "Revisión Simple", revisado por la jefatura del área que emite.

Se entrega sin áreas, sin solicitudes y con un único usuario, el administrador global:

| Correo | Contraseña inicial |
|---|---|
| admin@capstone.local | `Admin.Capstone2026` |

La contraseña es temporal: Keycloak exige cambiarla en el primer inicio de sesión.
