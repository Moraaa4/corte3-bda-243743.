const express = require('express');
const router = express.Router();
const pool = require('../db');

router.post('/', async (req, res) => {
  const role = req.header('X-Role');
  const vetId = req.header('X-Vet-Id');
  const { mascota_id, veterinario_id, fecha_hora, motivo } = req.body;

  if (!mascota_id || !veterinario_id || !fecha_hora || !motivo) {
    return res.status(400).json({ error: 'Faltan campos requeridos' });
  }

  let client;
  try {
    client = await pool.connect();

    if (role === 'veterinario') {
      await client.query('SET LOCAL app.current_vet_id = $1', [vetId]);
    }

    const queryText = 'CALL sp_agendar_cita($1, $2, $3::TIMESTAMP, $4, NULL)';
    const queryParams = [mascota_id, veterinario_id, fecha_hora, motivo];

    await client.query(queryText, queryParams);

    res.json({ mensaje: 'Cita agendada correctamente' });

  } catch (error) {
    console.error('Error al agendar cita:', error);
    res.status(400).json({ error: error.message });
  } finally {
    if (client) {
      client.release();
    }
  }
});

router.get('/', async (req, res) => {
  const role = req.header('X-Role');
  const vetId = req.header('X-Vet-Id');

  let client;
  try {
    client = await pool.connect();

    if (role === 'veterinario') {
      await client.query('SET LOCAL app.current_vet_id = $1', [vetId]);
    }

    const result = await client.query('SELECT * FROM citas ORDER BY fecha_hora DESC');

    res.json({
      total: result.rowCount,
      citas: result.rows
    });

  } catch (error) {
    console.error('Error al obtener citas:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  } finally {
    if (client) {
      client.release();
    }
  }
});

module.exports = router;
