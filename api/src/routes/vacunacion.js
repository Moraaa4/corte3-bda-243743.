const express = require('express');
const router = express.Router();
const pool = require('../db');
const redis = require('../cache');

router.get('/', async (req, res) => {
  const CACHE_KEY = 'vacunacion_pendiente';

  try {
    const cachedData = await redis.get(CACHE_KEY);

    if (cachedData) {
      console.log(`[${new Date().toISOString()}] [CACHE HIT] ${CACHE_KEY}`);
      return res.json({ source: 'cache', data: JSON.parse(cachedData) });
    }

    console.log(`[${new Date().toISOString()}] [CACHE MISS] ${CACHE_KEY}`);
    const start = Date.now();

    const result = await pool.query('SELECT * FROM v_mascotas_vacunacion_pendiente');
    
    const latencia = Date.now() - start + 'ms';
    console.log(`[BD] Consulta completada en ${latencia}`);

    await redis.setex(CACHE_KEY, 300, JSON.stringify(result.rows));

    res.json({ source: 'db', data: result.rows });

  } catch (error) {
    console.error('Error al obtener vacunación pendiente:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

module.exports = router;
