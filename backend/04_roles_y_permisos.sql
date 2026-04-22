-- ====================================================================
-- 1. Crear roles
-- ====================================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_veterinario') THEN
        CREATE ROLE rol_veterinario;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_recepcion') THEN
        CREATE ROLE rol_recepcion;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_administrador') THEN
        CREATE ROLE rol_administrador;
    END IF;
END
$$;

-- ====================================================================
-- 2. Crear usuarios de ejemplo con contraseña
-- ====================================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'vet_lopez') THEN
        CREATE USER vet_lopez WITH PASSWORD 'vet123';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'recepcion_ana') THEN
        CREATE USER recepcion_ana WITH PASSWORD 'rec123';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'admin_isaac') THEN
        CREATE USER admin_isaac WITH PASSWORD 'adm123';
    END IF;
END
$$;

-- ====================================================================
-- 3. Asignar usuarios a roles
-- ====================================================================
GRANT rol_veterinario TO vet_lopez;
GRANT rol_recepcion TO recepcion_ana;
GRANT rol_administrador TO admin_isaac;

-- ====================================================================
-- 4. Aplicar GRANT específicos tabla por tabla
-- ====================================================================

-- a) Permisos para rol_veterinario
GRANT SELECT, INSERT ON citas TO rol_veterinario;
GRANT SELECT, INSERT ON vacunas_aplicadas TO rol_veterinario;
GRANT SELECT ON mascotas TO rol_veterinario;
GRANT SELECT ON vet_atiende_mascota TO rol_veterinario;
GRANT SELECT ON inventario_vacunas TO rol_veterinario;

-- Privilegios a secuencias para permitir INSERT
GRANT USAGE, SELECT ON SEQUENCE citas_id_seq TO rol_veterinario;
GRANT USAGE, SELECT ON SEQUENCE vacunas_aplicadas_id_seq TO rol_veterinario;

-- Revocaciones explícitas
REVOKE ALL ON duenos FROM rol_veterinario;
REVOKE ALL ON historial_movimientos FROM rol_veterinario;
REVOKE ALL ON alertas FROM rol_veterinario;

-- b) Permisos para rol_recepcion
GRANT SELECT ON mascotas TO rol_recepcion;
GRANT SELECT ON duenos TO rol_recepcion;
GRANT SELECT, INSERT ON citas TO rol_recepcion;

-- Privilegios a secuencias para permitir INSERT
GRANT USAGE, SELECT ON SEQUENCE citas_id_seq TO rol_recepcion;

-- Revocaciones explícitas
REVOKE ALL ON vacunas_aplicadas FROM rol_recepcion;
REVOKE ALL ON inventario_vacunas FROM rol_recepcion;
REVOKE ALL ON historial_movimientos FROM rol_recepcion;
REVOKE ALL ON alertas FROM rol_recepcion;

-- c) Permisos para rol_administrador
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_administrador;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rol_administrador;
ALTER ROLE rol_administrador BYPASSRLS;

-- ====================================================================
-- 5. GRANT EXECUTE de procedures y funciones
-- ====================================================================

GRANT EXECUTE ON PROCEDURE sp_agendar_cita(INT, INT, TIMESTAMP, TEXT) TO rol_veterinario;
GRANT EXECUTE ON PROCEDURE sp_agendar_cita(INT, INT, TIMESTAMP, TEXT) TO rol_recepcion;

GRANT EXECUTE ON FUNCTION fn_total_facturado(INT, INT) TO rol_administrador;

GRANT SELECT ON v_mascotas_vacunacion_pendiente TO rol_veterinario;
GRANT SELECT ON v_mascotas_vacunacion_pendiente TO rol_recepcion;
GRANT SELECT ON v_mascotas_vacunacion_pendiente TO rol_administrador;
