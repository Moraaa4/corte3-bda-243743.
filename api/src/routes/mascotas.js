const express = require('express');
const router = express.Router();
const pool = require('../db');

router.get('/', async (req, res) => {
  const role = req.header('X-Role');
  const vetId = req.header('X-Vet-Id');
  const { nombre } = req.query;

  let client;
  try {
    client = await pool.connect();

    if (role === 'veterinario') {
      await client.query('SET LOCAL app.current_vet_id = $1', [vetId]);
    }

    let queryText = 'SELECT * FROM mascotas';
    let queryParams = [];

    if (nombre) {
      queryText += ' WHERE nombre ILIKE $1';
      queryParams.push(`%${nombre}%`);
    }

    const result = await client.query(queryText, queryParams);

    res.json({
      rol: role,
      total: result.rowCount,
      mascotas: result.rows
    });

  } catch (error) {
    console.error('Error al obtener mascotas:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  } finally {
    if (client) {
      client.release();
    }
  }
});

module.exports = router;
