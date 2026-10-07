import { openDatabase } from './database.js';
import { createApp } from './app.js';

const db = openDatabase();
const options = { demo: process.env.DEMO === '1' };
if (process.env.CORS_ORIGINS) options.origins = process.env.CORS_ORIGINS.split(',').map(value => value.trim());
const port = Number(process.env.PORT || 3001);
const server = createApp(db, options).listen(port, '127.0.0.1', () => {
  console.log(`Compasso API: http://127.0.0.1:${port}`);
});
function stop() { server.close(() => { db.close(); process.exit(0); }); }
process.on('SIGINT', stop);
process.on('SIGTERM', stop);
