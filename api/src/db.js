const { Pool } = require('pg');
const dotenv = require('dotenv');

dotenv.config();

const pool = new Pool({
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  host: process.env.POSTGRES_HOST,
  database: process.env.POSTGRES_DB,
  port: process.env.POSTGRES_PORT,
});

pool.connect((err, client, release) => {
  if (err) {
    console.error('Error adquiriendo cliente PostgreSQL', err.stack);
  } else {
    console.log('Conectado a PostgreSQL');
    release();
  }
});

module.exports = pool;
