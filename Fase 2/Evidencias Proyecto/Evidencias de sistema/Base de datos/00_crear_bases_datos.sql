-- =============================================================================
-- Sistema de Gestión Documental y Flujos de Aprobación (Masterbase)
-- 00_crear_bases_datos.sql — Bases de datos y usuarios de PostgreSQL
-- -----------------------------------------------------------------------------
-- Crea una base de datos por servicio, cada una con su propio usuario dueño:
--   keycloak_db -> Keycloak (autenticación)
--   sistema_db  -> sistema-principal (modelo de negocio)
-- Las credenciales son las del entorno local (.env.example); en otros
-- entornos se reemplazan por las del archivo .env.
--
-- Ejecutar con un superusuario, conectado a la base "postgres":
--   psql -U postgres -d postgres -f 00_crear_bases_datos.sql
-- Es idempotente: no falla si los usuarios o las bases ya existen.
-- =============================================================================

\set ON_ERROR_STOP on

-- 1. Usuarios (roles con login)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'keycloak_user') THEN
        CREATE ROLE keycloak_user LOGIN PASSWORD 'keycloak_secure_pass';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sistema_user') THEN
        CREATE ROLE sistema_user LOGIN PASSWORD 'sistema_secure_pass';
    END IF;
END
$$;

-- 2. Bases de datos (CREATE DATABASE no admite IF NOT EXISTS; se genera con \gexec)
SELECT 'CREATE DATABASE keycloak_db OWNER keycloak_user ENCODING ''UTF8'''
 WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'keycloak_db')\gexec

SELECT 'CREATE DATABASE sistema_db OWNER sistema_user ENCODING ''UTF8'''
 WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'sistema_db')\gexec

-- 3. Cada usuario administra solo el esquema public de su propia base
REVOKE ALL ON DATABASE keycloak_db FROM PUBLIC;
REVOKE ALL ON DATABASE sistema_db  FROM PUBLIC;

\connect keycloak_db
GRANT ALL ON SCHEMA public TO keycloak_user;

\connect sistema_db
GRANT ALL ON SCHEMA public TO sistema_user;
