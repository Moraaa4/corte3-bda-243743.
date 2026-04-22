# Cuaderno de Ataques — Validación de Seguridad

En este documento se documentan las pruebas prácticas de seguridad realizadas en el sistema para comprobar la protección contra inyección SQL, la efectividad del control de acceso a nivel de fila (RLS) y el funcionamiento de la caché en memoria.

---

## SECCIÓN 1: Tres ataques de SQL injection que fallan

### Ataque 1 — Quote escape clásico
**Input probado:** `' OR '1'='1`
**Pantalla:** Búsqueda de mascotas (`/buscar`), campo "Buscar mascota por nombre"
**Resultado:** 


**Línea que defendió:**
Archivo: `api/src/routes/mascotas.js`
La query usa el placeholder `$1`:
```javascript
  queryText += ' WHERE nombre ILIKE $1';
  queryParams.push(`%${nombre}%`);
  const result = await client.query(queryText, queryParams);
```
El driver `pg` envía el valor como parámetro separado, nunca como parte del SQL. El input `' OR '1'='1` se busca literalmente como un string que pertenece a un nombre, no se interpreta como sintaxis SQL, por ende, el motor de base de datos no evalúa la expresión booleana y la inyección fracasa.

### Ataque 2 — Stacked query
**Input probado:** `'; DROP TABLE mascotas; --`
**Pantalla:** Búsqueda de mascotas (`/buscar`), campo "Buscar mascota por nombre"
**Resultado:** 


**Línea que defendió:**
Archivo: `api/src/routes/mascotas.js`
Al igual que en el caso anterior, el uso de Prepared Statements con el driver restringe la inyección. PostgreSQL tratará el texto `; DROP TABLE` simplemente como los caracteres literales con los que debe coincidir el nombre de la mascota a buscar, evitando la ejecución y apilamiento de múltiples sentencias.

### Ataque 3 — Union-based
**Input probado:** `' UNION SELECT id,nombre,null,null FROM veterinarios; --`
**Pantalla:** Búsqueda de mascotas (`/buscar`), campo "Buscar mascota por nombre"
**Resultado:** 


**Línea que defendió:**
Archivo: `api/src/routes/mascotas.js`
El driver parametrizó el input malicioso en la posición `$1`. La instrucción `UNION` no se puede utilizar como un operador relacional cuando está encapsulada dentro de un string de valor parámetro. El intento de concatenar resultados exfiltrados de la tabla secreta de `veterinarios` a la consulta legítima fracasa, y solo realiza una búsqueda de un perro o gato llamado "UNION SELECT...".

---

## SECCIÓN 2: Demostración de RLS en acción

El Control de Acceso a Nivel de Fila (RLS) garantiza que aunque dos veterinarios tengan exactamente los mismos permisos de base de datos, a nivel registro solo accederán a la información a la que tengan autorización explícita.

**Prueba 1: Dr. López (vet_id=1)**
- **Sesión Iniciada:** Rol Veterinario, ID: 1
- **Mascotas Visibles:** Según el registro pivote de la BD, este doctor atiende a mascotas específicas. Por ejemplo, Firulais, Max, Toby.


**Prueba 2: Dra. García (vet_id=2)**
- **Sesión Iniciada:** Rol Veterinario, ID: 2
- **Mascotas Visibles:** A pesar de realizar exactamente la misma llamada a la API, la Dra. García ve registros completamente diferentes correspondientes a sus pacientes (ej. Misifú, Luna, Dante).


**Por qué ocurre esto:**
Ocurre gracias a esta política RLS aplicada internamente:
```sql
CREATE POLICY policy_mascotas_vet
ON mascotas FOR ALL TO rol_veterinario
USING (EXISTS (
    SELECT 1 FROM vet_atiende_mascota
    WHERE vet_atiende_mascota.mascota_id = mascotas.id
    AND vet_atiende_mascota.vet_id = current_setting('app.current_vet_id', TRUE)::INT
));
```
El Node.js ejecuta `SET LOCAL app.current_vet_id = X` justo antes de enviar la consulta del frontend al motor, y PostgreSQL en consecuencia descarta silenciosamente cualquier fila de mascota que no pase la condición de existencia de ese vínculo.

---

## SECCIÓN 3: Demostración de caché Redis

**Logs del flujo de caché:**


*Ejemplo de flujo esperado en logs:*
```text
[2026-04-22T10:00:00.000Z] [CACHE MISS] vacunacion_pendiente
[BD] Consulta completada en 187ms
[2026-04-22T10:00:05.000Z] [CACHE HIT] vacunacion_pendiente
[2026-04-22T10:00:10.000Z] [CACHE INVALIDATED] vacunacion_pendiente
[2026-04-22T10:00:12.000Z] [CACHE MISS] vacunacion_pendiente
```

**Análisis de la Implementación:**
- **Clave Utilizada:** `vacunacion_pendiente`. Se usó esta clave plana para almacenar el resultado general en JSON de la vista de base de datos más pesada de nuestro proyecto (aquella que cruza y procesa registros entre dueños, mascotas, e historial de vacunas).
- **TTL Configurado:** 300 segundos (5 minutos).
- **Justificación:** Una vigencia de 5 minutos mantiene un tiempo de respuesta óptimo en la interfaz y evita realizar accesos a disco repetitivos durante un periodo estable. Al mismo tiempo, el sistema implementa **invalidación activa** en el backend; cada vez que se ejecuta el endpoint `POST /api/vacunas` (nueva aplicación de vacuna), se ejecuta `redis.del('vacunacion_pendiente')`. Esta invalidación inmediata previene el riesgo de mostrar información clínica atrasada que ponga en peligro el tratamiento de la mascota, forzando un nuevo `CACHE MISS` cuando se deba ver el historial fresco.
