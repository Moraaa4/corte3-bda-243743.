const express = require('express');
const router = express.Router();
const pool = require('../db');
const redis = require('../cache');

router.post('/', async (req, res) => {
  const role = req.header('X-Role');
  const vetId = req.header('X-Vet-Id');
  const { mascota_id, vacuna_id, veterinario_id, costo_cobrado } = req.body;

  if (!mascota_id || !vacuna_id || !veterinario_id || costo_cobrado === undefined) {
    return res.status(400).json({ error: 'Faltan campos requeridos' });
  }

  let client;
  try {
    client = await pool.connect();

    if (role === 'veterinario') {
      await client.query('SET LOCAL app.current_vet_id = $1', [vetId]);
    }

    const queryText = `
      INSERT INTO vacunas_aplicadas
      (mascota_id, vacuna_id, veterinario_id, fecha_aplicacion, costo_cobrado)
      VALUES ($1, $2, $3, CURRENT_DATE, $4)
      RETURNING id
    `;
    const queryParams = [mascota_id, vacuna_id, veterinario_id, costo_cobrado];
    
    const result = await client.query(queryText, queryParams);

    await redis.del('vacunacion_pendiente');
    console.log(`[${new Date().toISOString()}] [CACHE INVALIDATED] vacunacion_pendiente`);

    res.json({ 
      mensaje: 'Vacuna aplicada correctamente', 
      id: result.rows[0].id 
    });

  } catch (error) {
    console.error('Error al aplicar vacuna:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  } finally {
    if (client) {
      client.release();
    }
  }
});

module.exports = router;
