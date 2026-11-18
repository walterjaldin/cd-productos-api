const app = require('./app');

const PORT = process.env.SERVER_PORT || 4000; // BUG intencional: el contenedor expone 3000

app.listen(PORT, () => {
  console.log(`Servidor escuchando en el puerto ${PORT}`);
});
