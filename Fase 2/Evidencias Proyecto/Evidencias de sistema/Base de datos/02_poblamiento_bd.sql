-- =============================================================================
-- Sistema de Gestión Documental y Flujos de Aprobación (Masterbase)
-- 02_poblamiento_bd.sql — Datos iniciales (DML)
-- -----------------------------------------------------------------------------
-- Deja la base recién creada con 01_creacion_bd.sql en su estado inicial de
-- entrega al cliente:
--   Parte A: catálogos estándar que el sistema necesita para funcionar
--            (estados, permisos, roles, auditoría, notificaciones y plazos SLA).
--   Parte B: administrador global, único usuario inicial.
-- No se cargan áreas, otros usuarios ni solicitudes: el cliente los crea desde
-- la plataforma con el administrador global.
--
-- Ejecutar con el usuario dueño de la base:
--   psql -U sistema_user -d sistema_db -f 02_poblamiento_bd.sql
-- =============================================================================

\set ON_ERROR_STOP on

BEGIN;

-- #############################################################################
-- PARTE A. CATÁLOGOS DEL SISTEMA
-- #############################################################################

-- -----------------------------------------------------------------------------
-- A.1 Máquina de estados de la solicitud
-- -----------------------------------------------------------------------------
INSERT INTO estado_solicitud (codigo, etiqueta, orden, es_final) VALUES
    ('PENDIENTE_REVISION',   'Pendiente de revisión', 1, false),
    ('CORRECCION_REQUERIDA', 'Corrección requerida',  2, false),
    ('APROBADO',             'Aprobado',              3, true),
    ('RECHAZADO',            'Rechazado',             4, true);

INSERT INTO accion_transicion (codigo, etiqueta) VALUES
    ('REGISTRAR',            'Registrar'),
    ('APROBAR',              'Aprobar'),
    ('RECHAZAR',             'Rechazar'),
    ('SOLICITAR_CORRECCION', 'Solicitar corrección'),
    ('CORREGIR',             'Corregir');

-- -----------------------------------------------------------------------------
-- A.2 Permisos (recurso + acción). SOLO_GLOBAL: no se pueden acotar a un área
-- -----------------------------------------------------------------------------
INSERT INTO permiso (recurso, accion, descripcion, ambito) VALUES
    ('USUARIO',        'GESTIONAR', 'Crear, editar y desactivar usuarios',                             'SOLO_GLOBAL'),
    ('AREA',           'GESTIONAR', 'Crear, editar y desactivar áreas y asignar jefaturas',            'SOLO_GLOBAL'),
    ('TIPO_DOCUMENTO', 'GESTIONAR', 'Configurar tipos de documento, prefijos y plazos',                'SOLO_GLOBAL'),
    ('ROL',            'GESTIONAR', 'Crear y editar roles y asignar accesos',                          'SOLO_GLOBAL'),
    ('AUDITORIA',      'VER',       'Consultar el registro de auditoría',                              'SOLO_GLOBAL'),
    ('SOLICITUD',      'VER',       'Ver solicitudes, documentos e historial del área',                'AREA_O_GLOBAL'),
    ('DOCUMENTO',      'DESCARGAR', 'Descargar y previsualizar archivos de solicitudes del área',      'AREA_O_GLOBAL'),
    ('DASHBOARD',      'VER',       'Ver métricas y resumen de solicitudes del área',                  'AREA_O_GLOBAL'),
    ('PLANTILLA',      'CREAR',     'Crear plantillas en el área',                                     'AREA_O_GLOBAL'),
    ('PLANTILLA',      'EDITAR',    'Publicar nuevas versiones y editar datos de plantillas del área', 'AREA_O_GLOBAL'),
    ('PLANTILLA',      'ELIMINAR',  'Eliminar (o desactivar, si ya se usaron) plantillas del área',    'AREA_O_GLOBAL'),
    ('FLUJO',          'GESTIONAR', 'Crear y configurar flujos, etapas y revisores',                   'AREA_O_GLOBAL');

-- -----------------------------------------------------------------------------
-- A.3 Tipos de evento de auditoría (códigos que registra el backend)
-- -----------------------------------------------------------------------------
INSERT INTO tipo_evento (codigo, categoria, descripcion) VALUES
    -- Autenticación
    ('LOGIN_EXITOSO',               'AUTENTICACION',  'Inicio de sesión exitoso'),
    ('LOGIN_FALLIDO',               'AUTENTICACION',  'Intento fallido de autenticación'),
    ('CUENTA_BLOQUEADA',            'AUTENTICACION',  'Cuenta bloqueada por intentos fallidos'),
    ('LOGOUT',                      'AUTENTICACION',  'Cierre de sesión'),
    ('CONTRASENA_CAMBIADA',         'AUTENTICACION',  'Cambio de contraseña exitoso'),
    ('CAMBIAR_PASSWORD',            'AUTENTICACION',  'Contraseña cambiada por el titular de la cuenta'),
    ('RECUPERACION_SOLICITADA',     'AUTENTICACION',  'Solicitud de restablecimiento de contraseña'),
    ('RECUPERACION_COMPLETADA',     'AUTENTICACION',  'Restablecimiento de contraseña completado'),

    -- Administración: usuarios
    ('USUARIO_CREADO',              'ADMINISTRACION', 'Usuario creado en el sistema'),
    ('USUARIO_EDITADO',             'ADMINISTRACION', 'Datos de usuario actualizados'),
    ('USUARIO_DESACTIVADO',         'ADMINISTRACION', 'Usuario desactivado'),
    ('USUARIO_ACTIVADO',            'ADMINISTRACION', 'Usuario reactivado'),
    ('USUARIO_AREA_CAMBIADA',       'ADMINISTRACION', 'Área asignada al usuario modificada'),
    ('CREAR_USUARIO',               'ADMINISTRACION', 'Usuario creado'),
    ('ACTUALIZAR_USUARIO',          'ADMINISTRACION', 'Datos de usuario actualizados'),
    ('ACTIVAR_USUARIO',             'ADMINISTRACION', 'Usuario activado'),
    ('DESACTIVAR_USUARIO',          'ADMINISTRACION', 'Usuario desactivado'),
    ('ELIMINAR_USUARIO',            'ADMINISTRACION', 'Usuario eliminado'),
    ('DESBLOQUEAR_USUARIO',         'ADMINISTRACION', 'Cuenta desbloqueada manualmente'),
    ('CAMBIAR_AREA_USUARIO',        'ADMINISTRACION', 'Área del usuario modificada (área anterior → nueva)'),
    ('BOOTSTRAP_ADMIN',             'ADMINISTRACION', 'Primer administrador del sistema asignado'),
    ('ADMIN_GLOBAL_ASIGNADO',       'ADMINISTRACION', 'Administrador global asignado al reflejar el rol ADMIN de Keycloak'),
    ('ADMIN_GLOBAL_REVOCADO',       'ADMINISTRACION', 'Administrador global revocado al dejar de tener el rol ADMIN en Keycloak'),

    -- Administración: áreas y jefaturas
    ('AREA_CREADA',                 'ADMINISTRACION', 'Área creada en la estructura organizacional'),
    ('AREA_EDITADA',                'ADMINISTRACION', 'Área actualizada'),
    ('AREA_DESACTIVADA',            'ADMINISTRACION', 'Área desactivada'),
    ('AREA_ACTIVADA',               'ADMINISTRACION', 'Área reactivada'),
    ('CREAR_AREA',                  'ADMINISTRACION', 'Área creada'),
    ('ACTUALIZAR_AREA',             'ADMINISTRACION', 'Área actualizada'),
    ('ACTIVAR_AREA',                'ADMINISTRACION', 'Área activada'),
    ('DESACTIVAR_AREA',             'ADMINISTRACION', 'Área desactivada'),
    ('ASIGNAR_ADMIN_AREA',          'ADMINISTRACION', 'Administrador de área asignado o cambiado'),
    ('JEFATURA_ASIGNADA',           'ADMINISTRACION', 'Jefatura asignada a un área'),
    ('JEFATURA_REMOVIDA',           'ADMINISTRACION', 'Jefatura removida de un área'),
    ('ACTUALIZAR_JEFATURAS_AREA',   'ADMINISTRACION', 'Lista de jefaturas del área actualizada'),

    -- Administración: roles
    ('ROL_CREADO',                  'ADMINISTRACION', 'Rol creado en el catálogo RBAC'),
    ('ROL_EDITADO',                 'ADMINISTRACION', 'Rol actualizado'),
    ('ROL_DESACTIVADO',             'ADMINISTRACION', 'Rol desactivado'),
    ('ROL_ACTIVADO',                'ADMINISTRACION', 'Rol reactivado'),
    ('ROL_ESTADO',                  'ADMINISTRACION', 'Estado del rol modificado'),
    ('ROL_ASIGNADO',                'ADMINISTRACION', 'Rol asignado a un usuario'),
    ('ROL_REVOCADO',                'ADMINISTRACION', 'Rol revocado de un usuario'),

    -- Administración: flujos
    ('FLUJO_CREADO',                'ADMINISTRACION', 'Flujo de aprobación creado'),
    ('FLUJO_EDITADO',               'ADMINISTRACION', 'Flujo de aprobación modificado'),
    ('FLUJO_DESACTIVADO',           'ADMINISTRACION', 'Flujo desactivado'),
    ('FLUJO_ACTIVADO',              'ADMINISTRACION', 'Flujo reactivado'),
    ('FLUJO_VERSION_CREADA',        'ADMINISTRACION', 'Nueva versión de flujo creada'),
    ('CREAR_FLUJO',                 'ADMINISTRACION', 'Flujo de aprobación creado'),
    ('ACTUALIZAR_FLUJO',            'ADMINISTRACION', 'Metadatos del flujo actualizados'),
    ('CAMBIAR_ESTADO_FLUJO',        'ADMINISTRACION', 'Estado del flujo modificado'),
    ('CONFIGURAR_ETAPAS_FLUJO',     'ADMINISTRACION', 'Etapas y revisores del flujo configurados'),
    ('DESACTIVAR_FLUJO',            'ADMINISTRACION', 'Flujo desactivado'),
    ('ELIMINAR_FLUJO',              'ADMINISTRACION', 'Flujo eliminado'),
    ('REVISOR_ASIGNADO',            'ADMINISTRACION', 'Revisor asignado a etapa de flujo'),
    ('REVISOR_REMOVIDO',            'ADMINISTRACION', 'Revisor removido de etapa de flujo'),
    ('ASIGNAR_RESPONSABLE_ETAPA',   'ADMINISTRACION', 'Responsable de etapa de flujo asignado'),

    -- Administración: tipos de documento, plazos SLA y plantillas
    ('TIPO_DOCUMENTO_CREADO',       'ADMINISTRACION', 'Tipo de documento y SLA creado'),
    ('TIPO_DOCUMENTO_EDITADO',      'ADMINISTRACION', 'Tipo de documento o SLA modificado'),
    ('TIPO_DOCUMENTO_ACTIVADO',     'ADMINISTRACION', 'Tipo de documento activado'),
    ('TIPO_DOCUMENTO_DESACTIVADO',  'ADMINISTRACION', 'Tipo de documento desactivado'),
    ('TIPO_DOCUMENTO_ELIMINADO',    'ADMINISTRACION', 'Tipo de documento eliminado'),
    ('PLAZO_MODIFICADO',            'ADMINISTRACION', 'Plazo SLA actualizado'),
    ('CONFIGURAR_SLA',              'ADMINISTRACION', 'Regla SLA creada, modificada o eliminada'),
    ('PLANTILLA_CREADA',            'ADMINISTRACION', 'Plantilla dinámica creada'),
    ('PLANTILLA_EDITADA',           'ADMINISTRACION', 'Metadatos de plantilla editados'),
    ('PLANTILLA_VERSION_PUBLICADA', 'ADMINISTRACION', 'Nueva versión de plantilla publicada'),
    ('PLANTILLA_DESACTIVADA',       'ADMINISTRACION', 'Plantilla desactivada'),
    ('PLANTILLA_ACTIVADA',          'ADMINISTRACION', 'Plantilla reactivada'),
    ('PLANTILLA_ELIMINADA',         'ADMINISTRACION', 'Plantilla eliminada físicamente'),

    -- Flujo operacional
    ('SOLICITUD_CREADA',            'FLUJO',          'Solicitud creada'),
    ('SOLICITUD_REGISTRADA',        'FLUJO',          'Solicitud emitida e ingresada a revisión'),
    ('CREAR_SOLICITUD',             'FLUJO',          'Solicitud registrada'),
    ('DOCUMENTO_GENERADO',          'FLUJO',          'Documento generado desde plantilla'),
    ('SOLICITUD_APROBADA',          'FLUJO',          'Solicitud aprobada'),
    ('APROBAR_SOLICITUD',           'FLUJO',          'Solicitud aprobada'),
    ('SOLICITUD_RECHAZADA',         'FLUJO',          'Solicitud rechazada'),
    ('RECHAZAR_SOLICITUD',          'FLUJO',          'Solicitud rechazada'),
    ('CORRECCION_SOLICITADA',       'FLUJO',          'Solicitud devuelta para correcciones'),
    ('SOLICITUD_CORRECCION_PEDIDA', 'FLUJO',          'Solicitud devuelta con observaciones'),
    ('PEDIR_CORRECCION',            'FLUJO',          'Corrección solicitada'),
    ('SOLICITUD_CORREGIDA',         'FLUJO',          'Solicitud corregida y reenviada'),
    ('REENVIAR_SOLICITUD',          'FLUJO',          'Solicitud corregida y reenviada'),
    ('ANALISIS_IA_SOLICITADO',      'FLUJO',          'Análisis de IA solicitado para la solicitud'),

    -- Acceso y consulta
    ('SOLICITUD_COMPARTIDA',        'ACCESO',         'Acceso a solicitud compartido'),
    ('ACCESO_REVOCADO',             'ACCESO',         'Acceso compartido revocado'),
    ('SOLICITUD_VISUALIZADA',       'ACCESO',         'Detalle de solicitud visualizado'),
    ('DOCUMENTO_VISUALIZADO',       'ACCESO',         'Documento previsualizado en el visor'),
    ('DOCUMENTO_DESCARGADO',        'ACCESO',         'Documento descargado desde almacenamiento'),
    ('DESCARGAR_DOCUMENTO',         'ACCESO',         'Documento de solicitud descargado'),
    ('DASHBOARD_VISUALIZADO',       'ACCESO',         'Panel de control o métricas consultadas'),
    ('ACCESO_DENEGADO',             'ACCESO',         'Intento de acceso denegado por políticas de seguridad');

-- -----------------------------------------------------------------------------
-- A.4 Tipos de notificación (dentro de la plataforma y por correo)
-- -----------------------------------------------------------------------------
INSERT INTO tipo_notificacion (codigo, descripcion) VALUES
    ('REVISION_ASIGNADA',            'Revisor: hay una solicitud pendiente de revisión'),
    ('SOLICITUD_AVANZA',             'Emisor: la solicitud pasó a la siguiente etapa'),
    ('SOLICITUD_APROBADA',           'Emisor: la solicitud fue aprobada'),
    ('SOLICITUD_RECHAZADA',          'Emisor: la solicitud fue rechazada'),
    ('CORRECCION_REQUERIDA',         'Emisor: se solicitaron correcciones'),
    ('SOLICITUD_COMPARTIDA_CONTIGO', 'Se compartió una solicitud contigo o con tu área'),
    ('PLAZO_POR_VENCER',             'Revisor: el plazo de revisión está por vencer'),
    ('PLAZO_VENCIDO',                'Revisor: el plazo de revisión venció'),
    ('DECISION_ADMIN_GLOBAL',        'Revisor: el administrador global decidió en su lugar');

-- -----------------------------------------------------------------------------
-- A.5 Tipos de documento: prefijo del correlativo y plazo SLA (días hábiles)
-- -----------------------------------------------------------------------------
INSERT INTO tipo_documento (id, nombre, descripcion, prefijo, plazo_dias_habiles) VALUES
    (1, 'Contrato',  'Contratos y acuerdos legales',           'CONT', 5),
    (2, 'Factura',   'Facturas comerciales y tributarias',     'FAC',  3),
    (3, 'Informe',   'Informes técnicos y ejecutivos',         'INF',  7),
    (4, 'Memorando', 'Comunicaciones y memorandos internos',   'MEMO', 2),
    (5, 'General',   'Documentación general y otros trámites', 'GEN',  5);

-- -----------------------------------------------------------------------------
-- A.6 Roles de sistema y sus permisos
-- -----------------------------------------------------------------------------
INSERT INTO rol (id, codigo, nombre, descripcion, sistema, asignacion, ambito) VALUES
    (1, 'JEFATURA_AREA', 'Jefatura de área',          'Rol automático asignado a las jefaturas de área', true, 'AUTO_JEFATURA', 'AREA_O_GLOBAL'),
    (2, 'ADMIN_AREA',    'Administrador de área',     'Administración funcional del área',               true, 'MANUAL',        'AREA_O_GLOBAL'),
    (3, 'LECTOR',        'Lector',                    'Acceso de consulta a solicitudes y dashboards',   true, 'MANUAL',        'AREA_O_GLOBAL'),
    (4, 'AUDITOR',       'Auditor',                   'Auditoría y consulta transversal',                true, 'MANUAL',        'SOLO_GLOBAL'),
    (5, 'ADMIN_SISTEMA', 'Administrador del sistema', 'Control total de la plataforma',                  true, 'MANUAL',        'SOLO_GLOBAL');

INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT r.rol_id, p.id
  FROM (VALUES
        -- JEFATURA_AREA
        (1, 'SOLICITUD', 'VER'), (1, 'DOCUMENTO', 'DESCARGAR'), (1, 'DASHBOARD', 'VER'),
        (1, 'PLANTILLA', 'CREAR'), (1, 'PLANTILLA', 'EDITAR'), (1, 'PLANTILLA', 'ELIMINAR'),
        (1, 'FLUJO', 'GESTIONAR'),
        -- ADMIN_AREA
        (2, 'FLUJO', 'GESTIONAR'), (2, 'DASHBOARD', 'VER'),
        (2, 'PLANTILLA', 'CREAR'), (2, 'PLANTILLA', 'EDITAR'), (2, 'PLANTILLA', 'ELIMINAR'),
        -- LECTOR
        (3, 'SOLICITUD', 'VER'), (3, 'DOCUMENTO', 'DESCARGAR'), (3, 'DASHBOARD', 'VER'),
        -- AUDITOR
        (4, 'SOLICITUD', 'VER'), (4, 'DOCUMENTO', 'DESCARGAR'), (4, 'DASHBOARD', 'VER'),
        (4, 'AUDITORIA', 'VER')
       ) AS r (rol_id, recurso, accion)
  JOIN permiso p ON p.recurso = r.recurso AND p.accion = r.accion;

-- ADMIN_SISTEMA recibe todos los permisos y luego se bloquean sus cambios
INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT 5, id FROM permiso;

UPDATE rol SET permisos_bloqueados = true WHERE id = 5;

-- -----------------------------------------------------------------------------
-- A.7 Flujo global "Revisión Simple": una etapa revisada por la jefatura del
--     área que emite la solicitud. Queda disponible para toda área que se cree
-- -----------------------------------------------------------------------------
INSERT INTO flujo_definicion (id, nombre, descripcion, area_id) VALUES
    (1, 'Revisión Simple', 'Flujo base global de 1 etapa para revisión por jefatura', NULL);

INSERT INTO flujo_etapa (id, flujo_definicion_id, orden, nombre, modo_revisor) VALUES
    (1, 1, 1, 'Revisión', 'JEFATURA_AREA_SOLICITUD');

-- #############################################################################
-- PARTE B. ADMINISTRADOR GLOBAL
-- #############################################################################

-- Sus credenciales viven en Keycloak (03_keycloak_realm_capstone.json); el
-- keycloak_id vincula ambas cuentas. No pertenece a ningún área.
INSERT INTO usuario (id, keycloak_id, email, nombre, apellido) VALUES
    ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001',
     'admin@capstone.local', 'Admin', 'Capstone');

-- Rol ADMIN_SISTEMA global (área NULL), reflejo del rol ADMIN de Keycloak
INSERT INTO usuario_rol (usuario_id, rol_id, area_id, otorgado_por) VALUES
    ('a0000000-0000-0000-0000-000000000001', 5, NULL, 'a0000000-0000-0000-0000-000000000001');

-- #############################################################################
-- Ajuste de secuencias: los próximos registros creados desde la aplicación
-- continúan después de los ids fijos cargados en este script
-- #############################################################################
SELECT setval(pg_get_serial_sequence('tipo_documento',   'id'), (SELECT max(id) FROM tipo_documento));
SELECT setval(pg_get_serial_sequence('rol',              'id'), (SELECT max(id) FROM rol));
SELECT setval(pg_get_serial_sequence('flujo_definicion', 'id'), (SELECT max(id) FROM flujo_definicion));
SELECT setval(pg_get_serial_sequence('flujo_etapa',      'id'), (SELECT max(id) FROM flujo_etapa));

COMMIT;
