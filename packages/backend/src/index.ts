/*
 * Hi!
 *
 * Note that this is an EXAMPLE Backstage backend. Please check the README.
 *
 * Happy hacking!
 */

import express from 'express';
import cors from 'cors';

async function main() {
  const app = express();
  
  // Enable CORS
  app.use(cors({
    origin: 'http://localhost:3000',
    methods: ['GET', 'HEAD', 'PATCH', 'POST', 'PUT', 'DELETE'],
    credentials: true,
  }));

  // Add health check endpoint
  app.get('/health', (_, res) => {
    console.log('Health check endpoint called');
    res.json({ status: 'ok' });
  });

  app.get('/', (_, res) => {
    res.json({ message: 'Backstage backend is running' });
  });

  // Handle shutdown gracefully
  process.on('SIGTERM', () => {
    console.log('Received SIGTERM signal, shutting down...');
    process.exit(0);
  });

  const port = 7007;
  app.listen(port, '0.0.0.0', () => {
    console.log(`Backend server listening at http://0.0.0.0:${port}`);
  });
}

main().catch((error) => {
  console.error('Server failed to start up', error);
  process.exit(1);
});
