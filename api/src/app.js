const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const PORT = process.env.API_PORT || 3001;

app.use(cors());
app.use(express.json());

// Ruta de salud
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

// Importar rutas
const mascotasRoutes = require('./routes/mascotas');
const vacunacionRoutes = require('./routes/vacunacion');
const citasRoutes = require('./routes/citas');
const vacunasRoutes = require('./routes/vacunas');

// Usar rutas
app.use('/api/mascotas', mascotasRoutes);
app.use('/api/vacunacion-pendiente', vacunacionRoutes);
app.use('/api/citas', citasRoutes);
app.use('/api/vacunas', vacunasRoutes);

app.listen(PORT, () => {
  console.log(`API corriendo en el puerto ${PORT}`);
});
