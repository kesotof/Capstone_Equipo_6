#!/usr/bin/env bash
# =============================================================================
# Sistema de Gestión Documental y Flujos de Aprobación (Masterbase)
# 04_configuracion_servicios.sh — Configuración de Keycloak y MinIO
# -----------------------------------------------------------------------------
# Configura los servicios de apoyo que no pertenecen a sistema-principal:
#   1. Keycloak: importa el realm capstone-realm (03_keycloak_realm_capstone.json)
#      y activa el flujo de inicio de sesión que avisa del bloqueo temporal
#      tras 4 intentos fallidos.
#   2. MinIO: crea el bucket privado donde se guardan los documentos.
# RabbitMQ no requiere configuración: cada microservicio declara sus colas
# al iniciar.
#
# Requisitos: contenedores capstone-keycloak y capstone-minio en ejecución
# (docker compose up -d). Ejecutar desde esta carpeta:
#   ./04_configuracion_servicios.sh                     # conserva el realm si ya existe
#   ./04_configuracion_servicios.sh --reemplazar-realm  # lo borra y lo vuelve a importar
# Usar --reemplazar-realm si Keycloak ya importó otro realm al iniciar: el id
# del administrador debe coincidir con su keycloak_id en 02_poblamiento_bd.sql.
# Es idempotente: puede ejecutarse más de una vez.
# =============================================================================
set -euo pipefail

CARPETA="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

KEYCLOAK_CONTENEDOR="capstone-keycloak"
KEYCLOAK_ADMIN="${KEYCLOAK_ADMIN:-admin}"
KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-admin_secure_pass}"
REALM="capstone-realm"
FLUJO_LOGIN="browser-capstone-lock-message"
PROVEEDOR_PROPIO="capstone-username-password-form"   # formulario con aviso de bloqueo
PROVEEDOR_ESTANDAR="auth-username-password-form"

MINIO_CONTENEDOR="capstone-minio"
MINIO_ROOT_USER="${MINIO_ROOT_USER:-minioadmin}"
MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:-minioadmin_secure_pass}"
MINIO_BUCKET="${MINIO_DEFAULT_BUCKET:-documentos}"

kcadm() {
    docker exec -e HOME=/tmp "$KEYCLOAK_CONTENEDOR" /opt/keycloak/bin/kcadm.sh "$@"
}

# -----------------------------------------------------------------------------
# 1. Keycloak
# -----------------------------------------------------------------------------
echo "[1/2] Keycloak"
kcadm config credentials --server http://localhost:8080 --realm master \
    --user "$KEYCLOAK_ADMIN" --password "$KEYCLOAK_ADMIN_PASSWORD" >/dev/null

# 1.1 Realm con cliente, rol ADMIN, política de bloqueo y administrador global
if [ "${1:-}" = "--reemplazar-realm" ] && kcadm get "realms/$REALM" >/dev/null 2>&1; then
    kcadm delete "realms/$REALM"
    echo "  - Realm $REALM anterior eliminado"
fi
if kcadm get "realms/$REALM" >/dev/null 2>&1; then
    echo "  - El realm $REALM ya existe; no se reimporta"
else
    docker cp "$CARPETA/03_keycloak_realm_capstone.json" "$KEYCLOAK_CONTENEDOR:/tmp/realm.json"
    kcadm create realms -f /tmp/realm.json
    echo "  - Realm $REALM importado"
fi

# 1.2 Copia del flujo "browser" que usa el formulario propio en lugar del estándar
if ! kcadm get authentication/flows -r "$REALM" | grep -q "\"alias\" : \"$FLUJO_LOGIN\""; then
    kcadm create authentication/flows/browser/copy -r "$REALM" -s "newName=$FLUJO_LOGIN"
fi

# Devuelve el id de la ejecución del flujo que usa el proveedor indicado
id_ejecucion() {
    kcadm get "authentication/flows/$FLUJO_LOGIN/executions" -r "$REALM" | sed -n "
        /\"id\" :/ { s/.*\"id\" : \"\([^\"]*\)\".*/\1/; h }
        /\"providerId\" : \"$1\"/ { g; p; q }"
}

ID_PROPIO="$(id_ejecucion "$PROVEEDOR_PROPIO" || true)"
if [ -z "$ID_PROPIO" ]; then
    kcadm create "authentication/flows/${FLUJO_LOGIN}%20forms/executions/execution" -r "$REALM" \
        -s "provider=$PROVEEDOR_PROPIO"
    ID_PROPIO="$(id_ejecucion "$PROVEEDOR_PROPIO")"
fi
kcadm update "authentication/flows/$FLUJO_LOGIN/executions" -r "$REALM" \
    -b "{\"id\":\"$ID_PROPIO\",\"requirement\":\"REQUIRED\"}" -n

ID_ESTANDAR="$(id_ejecucion "$PROVEEDOR_ESTANDAR" || true)"
if [ -n "$ID_ESTANDAR" ]; then
    kcadm delete "authentication/executions/$ID_ESTANDAR" -r "$REALM"
fi
kcadm create "authentication/executions/$ID_PROPIO/raise-priority" -r "$REALM" >/dev/null 2>&1 || true

kcadm update "realms/$REALM" -s "browserFlow=$FLUJO_LOGIN"
echo "  - Flujo de inicio de sesión $FLUJO_LOGIN activo"

# -----------------------------------------------------------------------------
# 2. MinIO
# -----------------------------------------------------------------------------
echo "[2/2] MinIO"
docker exec "$MINIO_CONTENEDOR" mc alias set local http://localhost:9000 \
    "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null
docker exec "$MINIO_CONTENEDOR" mc mb --ignore-existing "local/$MINIO_BUCKET" >/dev/null
docker exec "$MINIO_CONTENEDOR" mc anonymous set none "local/$MINIO_BUCKET" >/dev/null
echo "  - Bucket $MINIO_BUCKET creado con acceso privado"

echo "Configuración completada."
