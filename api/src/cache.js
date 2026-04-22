const Redis = require('ioredis');
const dotenv = require('dotenv');

dotenv.config();

const redis = new Redis({
  host: process.env.REDIS_HOST,
  port: process.env.REDIS_PORT,
});

redis.on('connect', () => {
  console.log('Conectado a Redis');
});

redis.on('error', (error) => {
  console.error(`Error de conexión Redis: ${error.message}`);
});

module.exports = redis;
