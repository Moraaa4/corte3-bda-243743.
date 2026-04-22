-- ====================================================================
-- 1. Habilitar RLS
-- ====================================================================
ALTER TABLE mascotas ENABLE ROW LEVEL SECURITY;
ALTER TABLE citas ENABLE ROW LEVEL SECURITY;
ALTER TABLE vacunas_aplicadas ENABLE ROW LEVEL SECURITY;

-- ====================================================================
-- 2. Políticas en la tabla mascotas
-- ====================================================================

DROP POLICY IF EXISTS policy_mascotas_vet ON mascotas;
DROP POLICY IF EXISTS policy_mascotas_recepcion_admin ON mascotas;

-- Protege a la tabla mascotas para que el veterinario vea SOLO las mascotas que él atiende
CREATE POLICY policy_mascotas_vet
ON mascotas
FOR ALL
TO rol_veterinario
USING (
    EXISTS (
        SELECT 1 FROM vet_atiende_mascota
        WHERE vet_atiende_mascota.mascota_id = mascotas.id
        AND vet_atiende_mascota.vet_id = current_setting('app.current_vet_id', TRUE)::INT
    )
);

-- Protege y permite que los roles recepcion y administrador puedan ver todas las mascotas
CREATE POLICY policy_mascotas_recepcion_admin
ON mascotas
FOR ALL
TO rol_recepcion, rol_administrador
USING (TRUE);

-- ====================================================================
-- 3. Políticas en la tabla citas
-- ====================================================================

DROP POLICY IF EXISTS policy_citas_vet ON citas;
DROP POLICY IF EXISTS policy_citas_recepcion_admin ON citas;

-- Protege a la tabla citas para que el veterinario vea SOLO sus propias citas
CREATE POLICY policy_citas_vet
ON citas
FOR ALL
TO rol_veterinario
USING (
    veterinario_id = current_setting('app.current_vet_id', TRUE)::INT
);

-- Protege y permite el acceso total a citas para recepción y administrador
CREATE POLICY policy_citas_recepcion_admin
ON citas
FOR ALL
TO rol_recepcion, rol_administrador
USING (TRUE);

-- ====================================================================
-- 4. Políticas en la tabla vacunas_aplicadas
-- ====================================================================

DROP POLICY IF EXISTS policy_vacunas_vet ON vacunas_aplicadas;
DROP POLICY IF EXISTS policy_vacunas_admin ON vacunas_aplicadas;

-- Protege la tabla de vacunas para que el veterinario vea SOLO las aplicadas a mascotas que atiende
CREATE POLICY policy_vacunas_vet
ON vacunas_aplicadas
FOR ALL
TO rol_veterinario
USING (
    EXISTS (
        SELECT 1 FROM vet_atiende_mascota
        WHERE vet_atiende_mascota.mascota_id = vacunas_aplicadas.mascota_id
        AND vet_atiende_mascota.vet_id = current_setting('app.current_vet_id', TRUE)::INT
    )
);

-- Protege y permite acceso a todo el historial de vacunas para el administrador
CREATE POLICY policy_vacunas_admin
ON vacunas_aplicadas
FOR ALL
TO rol_administrador
USING (TRUE);

-- ====================================================================
-- 5. Bloque de verificación
-- ====================================================================
DO $$
DECLARE
    v_mascotas_pol INT;
    v_citas_pol INT;
    v_vacunas_pol INT;
BEGIN
    SELECT count(*) INTO v_mascotas_pol FROM pg_policies WHERE tablename = 'mascotas';
    SELECT count(*) INTO v_citas_pol FROM pg_policies WHERE tablename = 'citas';
    SELECT count(*) INTO v_vacunas_pol FROM pg_policies WHERE tablename = 'vacunas_aplicadas';

    RAISE NOTICE '=================================================';
    RAISE NOTICE 'Verificación de políticas RLS aplicadas:';
    RAISE NOTICE 'Tabla mascotas: % políticas', v_mascotas_pol;
    RAISE NOTICE 'Tabla citas: % políticas', v_citas_pol;
    RAISE NOTICE 'Tabla vacunas_aplicadas: % políticas', v_vacunas_pol;
    RAISE NOTICE '=================================================';
END $$;
