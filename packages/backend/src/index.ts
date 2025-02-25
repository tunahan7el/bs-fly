/*
 * Hi!
 *
 * Note that this is an EXAMPLE Backstage backend. Please check the README.
 *
 * Happy hacking!
 */

import express from 'express';
import cors from 'cors';
import path from 'path';

async function main() {
  const app = express();
  
  // Add logging middleware
  app.use((req, res, next) => {
    console.log(`${req.method} ${req.path}`);
    next();
  });

  // Enable CORS
  app.use(cors());

  // Add health check endpoint
  app.get('/health', (_, res) => {
    console.log('Health check endpoint called');
    res.json({ status: 'ok' });
  });

  // Serve API endpoints
  app.get('/api', (_, res) => {
    res.json({ message: 'Backstage backend is running' });
  });

  // Serve static frontend files
  const frontendDir = path.join(__dirname, '../../app/dist');
  console.log('Serving frontend from:', frontendDir);
  app.use(express.static(frontendDir));

  // Serve index.html for all other routes (SPA support)
  app.get('*', (req, res) => {
    console.log('Serving index.html for path:', req.path);
    res.sendFile(path.join(frontendDir, 'index.html'));
  });

  // Handle shutdown gracefully
  process.on('SIGTERM', () => {
    console.log('Received SIGTERM signal, shutting down...');
    process.exit(0);
  });

  const port = 7007;
  app.listen(port, '0.0.0.0', () => {
    console.log(`Backend server listening at http://0.0.0.0:${port}`);
    console.log('Frontend directory:', frontendDir);
  });
}

main().catch((error) => {
  console.error('Server failed to start up', error);
  process.exit(1);
});
